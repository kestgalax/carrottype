import Foundation

/// Language of the text being typed. Independent of the app interface language.
enum TypingTestLanguage: String, CaseIterable, Identifiable, Sendable {
    case russian
    case english

    var id: String { rawValue }

    var languageCode: String {
        switch self {
        case .russian: return "ru"
        case .english: return "en"
        }
    }
}

/// Editorial difficulty of the generated prompt. Not a scientific word-frequency rank.
enum TypingTestLevel: String, CaseIterable, Identifiable, Sendable {
    case easy
    case medium
    case advanced

    var id: String { rawValue }
    static let defaultLevel: TypingTestLevel = .medium
}

struct TypingTestLanguageCorpus: Equatable, Sendable {
    var easyWords: [String]
    var mediumFragments: [String]
    var advancedFragments: [String]

    func fragments(for level: TypingTestLevel) -> [String] {
        switch level {
        case .easy: return easyWords
        case .medium: return mediumFragments
        case .advanced: return advancedFragments
        }
    }
}

/// Small original CarrotType corpora. No Monkeytype text or code is copied.
/// A single attempt is generated locally from these fragments; the corpus is not
/// rendered as one fixed passage.
struct TypingTestCorpus: Equatable, Sendable {
    var languages: [TypingTestLanguage: TypingTestLanguageCorpus]

    enum ValidationError: Error, Equatable, CustomStringConvertible {
        case missingLanguage(TypingTestLanguage)
        case emptySection(TypingTestLanguage, TypingTestLevel)
        case easyWordNotLowercase(TypingTestLanguage, String)
        case easyWordNotLetters(TypingTestLanguage, String)
        case fragmentHasNewline(TypingTestLanguage, TypingTestLevel)
        case mediumFragmentNeedsTerminalPunctuation(TypingTestLanguage, String)

        var description: String {
            switch self {
            case .missingLanguage(let language):
                return "Missing corpus for \(language.rawValue)"
            case .emptySection(let language, let level):
                return "Empty \(level.rawValue) corpus for \(language.rawValue)"
            case .easyWordNotLowercase(let language, let word):
                return "Easy word must be lowercase (\(language.rawValue)): \(word)"
            case .easyWordNotLetters(let language, let word):
                return "Easy word must contain letters only (\(language.rawValue)): \(word)"
            case .fragmentHasNewline(let language, let level):
                return "Fragment contains a newline/tab (\(language.rawValue), \(level.rawValue))"
            case .mediumFragmentNeedsTerminalPunctuation(let language, let fragment):
                return "Medium fragment needs terminal punctuation (\(language.rawValue)): \(fragment)"
            }
        }
    }

    func languageCorpus(for language: TypingTestLanguage) -> TypingTestLanguageCorpus? {
        languages[language]
    }

    func fragments(for language: TypingTestLanguage, level: TypingTestLevel) -> [String]? {
        languages[language]?.fragments(for: level)
    }

    /// Structural validation used by tests and by the bundled-corpus regression.
    func validate() throws {
        for language in TypingTestLanguage.allCases {
            guard let corpus = languages[language] else {
                throw ValidationError.missingLanguage(language)
            }
            guard !corpus.easyWords.isEmpty else {
                throw ValidationError.emptySection(language, .easy)
            }
            guard !corpus.mediumFragments.isEmpty else {
                throw ValidationError.emptySection(language, .medium)
            }
            guard !corpus.advancedFragments.isEmpty else {
                throw ValidationError.emptySection(language, .advanced)
            }
            for word in corpus.easyWords {
                guard word == word.lowercased() else {
                    throw ValidationError.easyWordNotLowercase(language, word)
                }
                guard !word.isEmpty, word.allSatisfy({ $0.isLetter }) else {
                    throw ValidationError.easyWordNotLetters(language, word)
                }
            }
            for (level, fragments) in [(TypingTestLevel.medium, corpus.mediumFragments),
                                       (.advanced, corpus.advancedFragments)] {
                for fragment in fragments where fragment.contains("\n") || fragment.contains("\t") {
                    throw ValidationError.fragmentHasNewline(language, level)
                }
            }
            for fragment in corpus.mediumFragments {
                guard let last = fragment.last, ".!?".contains(last) else {
                    throw ValidationError.mediumFragmentNeedsTerminalPunctuation(language, fragment)
                }
            }
        }
    }

    /// UTF-8 size of the authored strings only (no Swift source scaffolding).
    var authoredUTF8ByteCount: Int {
        languages.values.reduce(into: 0) { total, corpus in
            for text in corpus.easyWords + corpus.mediumFragments + corpus.advancedFragments {
                total += text.utf8.count
            }
        }
    }

    static let bundled = TypingTestCorpus(languages: [
        .russian: TypingTestLanguageCorpus(
            easyWords: [
                "дом", "день", "время", "город", "книга", "рядом", "свет", "окно",
                "стол", "стул", "чай", "хлеб", "вода", "рука", "нога", "глаз",
                "нос", "рот", "ухо", "брат", "сестра", "мама", "папа", "сын",
                "дочь", "друг", "гость", "утро", "вечер", "ночь", "зима", "весна",
                "лето", "осень", "снег", "дождь", "ветер", "небо", "солнце", "луна",
                "звезда", "река", "море", "лес", "поле", "гора", "дорога", "улица",
                "площадь", "магазин", "школа", "работа", "офис", "машина", "поезд", "метро",
                "билет", "ключ", "дверь", "стена", "пол", "потолок", "лампа", "шкаф",
                "диван", "кресло", "кровать", "кухня", "тарелка", "ложка", "вилка", "нож",
                "чашка", "сахар", "соль", "суп", "каша", "мясо", "рыба", "сыр",
                "масло", "яблоко", "груша", "слива", "вишня", "ягода", "лист", "цветок",
                "трава", "дерево", "птица", "кот", "пёс", "конь", "мышь", "лиса",
                "волк", "медведь", "заяц", "тигр", "слон", "остров", "берег", "песок",
                "камень", "мост", "сад", "двор", "крыша", "этаж", "лифт", "почта",
                "банк", "врач", "аптека", "театр", "музей", "парк", "спорт", "игра",
                "мяч", "бег", "шаг", "путь", "край", "круг", "центр", "форма",
                "план", "дело", "слово", "буква", "число", "счёт", "ответ", "вопрос",
                "пример", "текст", "знак", "точка", "линия", "цвет", "звук", "шум",
                "тихо", "быстро", "медленно", "просто", "легко", "трудно", "важно", "точно",
                "ясно", "близко", "далеко", "высоко", "низко", "тепло", "холодно", "мало",
            ],
            mediumFragments: [
                "Утром город просыпается медленно.",
                "На столе стоит чашка чая.",
                "В парке дети играют у старого фонтана.",
                "Она открыла окно и впустила свежий воздух.",
                "Мы договорились встретиться после работы.",
                "Дождь закончился, и на улице стало тихо.",
                "В библиотеке пахнет бумагой и деревом.",
                "Он взял книгу, сел у окна и начал читать.",
                "На кухне греется суп, а на плите свистит чайник.",
                "Каждое утро я иду к метро через небольшой сквер.",
                "Друзья приехали поздно, но мы были рады их видеть.",
                "В комнате горела лампа, и за окном падал снег.",
                "Нужно купить хлеб, молоко и немного сыра.",
                "Она внимательно слушала и иногда кивала.",
                "В поезде было тепло и почти пусто.",
                "На площади играл уличный музыкант.",
                "Мы долго выбирали подарок для бабушки.",
                "После обеда все вышли в сад.",
                "Ветер качал ветки яблонь.",
                "Кот спал на подоконнике и не обращал на нас внимания.",
                "Он забыл ключи дома и ждал у двери.",
                "Новый проект оказался сложнее, чем мы думали.",
                "В пятницу офис закрывается немного раньше.",
                "Я записал адрес на обратной стороне билета.",
                "На небе появились первые звёзды.",
                "Она налила воду в стакан и добавила лимон.",
                "Мы прошли через мост и свернули направо.",
                "В музее открылась выставка старых фотографий.",
                "Ребёнок нарисовал дом, солнце и большую собаку.",
                "Пожалуйста, закройте дверь, когда будете уходить.",
                "Врач посоветовал больше гулять и меньше сидеть.",
                "Наш поезд отправляется в семь часов утра.",
                "Я люблю тихие вечера и длинные прогулки.",
                "Чай был горячим, а разговор спокойным.",
                "В магазине на углу всегда свежий хлеб.",
                "Она поставила цветы в стеклянную вазу.",
                "Мы слышали, как за стеной играет радио.",
                "На следующий день снег растаял.",
                "Он аккуратно сложил бумаги и выключил компьютер.",
                "В лесу пахло хвоей и влажной землёй.",
                "Сестра прислала короткое сообщение и фотографию.",
                "У окна стоял большой деревянный стол.",
                "Мы решили остаться дома и посмотреть фильм.",
                "Каждую субботу она ходит на рынок за овощами.",
                "В конце улицы показался знакомый автобус.",
            ],
            advancedFragments: [
                "Координатор уточнил конфигурацию: проверка запланирована на 14:30.",
                "Инженер перепроверил журнал событий и обнаружил редкую аномалию.",
                "Синхронизация данных завершилась успешно; резервная копия сохранена.",
                "В отчёте указаны три ключевых показателя: точность, задержка и стабильность.",
                "Мы обсудили компромисс между скоростью и надёжностью, но решение отложили.",
                "Архитектор предложил изолировать компонент, чтобы упростить диагностику.",
                "Протокол обмена обновили до версии 3.2 без изменения формата сообщений.",
                "Наблюдение показало, что пиковая нагрузка приходится на 18:45.",
                "Специалист сверил подписи и подтвердил целостность архива.",
                "Если очередь переполнится, система переключится в безопасный режим.",
                "Редактор сократил вступление, сохранив смысл и основные аргументы.",
                "Отклонение составило всего 0,4 %, что находится в допустимых пределах.",
                "Перед запуском необходимо проверить зависимости и параметры среды.",
                "Автоматическая проверка выявила несоответствие в двух записях.",
                "Мы использовали резервный канал, поскольку основной был недоступен.",
                "Документация описывает сценарии восстановления после сбоя питания.",
                "Исследователь сравнил несколько подходов и выбрал наиболее простой.",
                "Внедрение заняло меньше времени, чем предполагалось изначально.",
                "Команда подготовила план миграции: этапы, риски и контрольные точки.",
                "Значение счётчика уменьшилось на 12 единиц после перезапуска.",
                "Обнаруженная ошибка оказалась следствием устаревшей конфигурации.",
                "Руководитель попросил уточнить сроки и распределить ответственность.",
                "Мы сохранили совместимость со старыми клиентами и форматами.",
                "Проверка граничных условий выявила проблему только при пустом вводе.",
                "Резервный сервер принял трафик через 6 секунд после переключения.",
                "Аналитик отметил рост активности в сегменте малого бизнеса.",
                "Новая схема позволяет сократить объём хранимых данных почти вдвое.",
                "Перед публикацией макет ещё раз проверили на минимальном экране.",
                "Служба поддержки зафиксировала обращение и передала его разработчикам.",
                "Мы отказались от сложного решения в пользу понятного и проверяемого.",
                "В журнале остались записи за последние 30 дней.",
                "Тестировщик воспроизвёл сценарий и приложил подробный отчёт.",
                "Обновление затрагивает только интерфейс, не меняя бизнес-логику.",
                "Необходимо учитывать сезонность при интерпретации этих чисел.",
                "Контрольная сумма совпала, поэтому файл признали пригодным.",
                "Сотрудники обсудили регламент и предложили два небольших уточнения.",
                "Система корректно обработала редкий символ и сохранила порядок слов.",
                "После короткого перерыва команда вернулась к обсуждению деталей.",
                "Мы измерили задержку при 200 запросах в секунду.",
                "Отчёт содержит ссылки на источники и дату последней проверки.",
                "Автор подчеркнул, что выводы носят предварительный характер.",
                "В понедельник состоится встреча с представителями партнёра.",
            ]
        ),
        .english: TypingTestLanguageCorpus(
            easyWords: [
                "house", "day", "time", "city", "book", "near", "light", "window",
                "table", "chair", "tea", "bread", "water", "hand", "foot", "eye",
                "nose", "mouth", "ear", "brother", "sister", "mother", "father", "son",
                "daughter", "friend", "guest", "morning", "evening", "night", "winter", "spring",
                "summer", "autumn", "snow", "rain", "wind", "sky", "sun", "moon",
                "star", "river", "sea", "forest", "field", "mountain", "road", "street",
                "square", "store", "school", "work", "office", "car", "train", "subway",
                "ticket", "key", "door", "wall", "floor", "ceiling", "lamp", "closet",
                "sofa", "armchair", "bed", "kitchen", "plate", "spoon", "fork", "knife",
                "cup", "sugar", "salt", "soup", "meat", "fish", "cheese", "butter",
                "apple", "pear", "plum", "cherry", "berry", "leaf", "flower", "grass",
                "tree", "bird", "cat", "dog", "horse", "mouse", "fox", "wolf",
                "bear", "hare", "tiger", "elephant", "island", "shore", "sand", "stone",
                "bridge", "garden", "yard", "roof", "elevator", "mail", "bank", "doctor",
                "pharmacy", "theater", "museum", "park", "sport", "game", "ball", "run",
                "step", "path", "edge", "circle", "center", "shape", "plan", "case",
                "word", "letter", "number", "count", "answer", "question", "example", "text",
                "sheet", "mark", "dot", "line", "color", "sound", "noise", "quiet",
                "fast", "slow", "simple", "easy", "hard", "important", "exact", "clear",
            ],
            mediumFragments: [
                "The morning train was quiet and nearly empty.",
                "She opened the window and let in the cool air.",
                "We agreed to meet after work near the station.",
                "The rain stopped, and the street became still.",
                "A cup of tea stood on the wooden table.",
                "He took a book, sat by the window, and began to read.",
                "The children played beside the old fountain.",
                "I walk through the small park every morning.",
                "Our friends arrived late, but we were glad to see them.",
                "The lamp was on, and snow was falling outside.",
                "We need bread, milk, and a little cheese.",
                "She listened carefully and nodded from time to time.",
                "The train was warm and almost empty.",
                "A street musician was playing in the square.",
                "We spent a long time choosing a gift for my grandmother.",
                "After lunch everyone went out into the garden.",
                "The wind moved the branches of the apple trees.",
                "The cat slept on the windowsill and ignored us.",
                "He forgot his keys at home and waited by the door.",
                "The new project turned out to be harder than we expected.",
                "On Friday the office closes a little earlier.",
                "I wrote the address on the back of the ticket.",
                "The first stars appeared in the sky.",
                "She poured water into a glass and added lemon.",
                "We crossed the bridge and turned right.",
                "The museum opened an exhibition of old photographs.",
                "The child drew a house, a sun, and a large dog.",
                "Please close the door when you leave.",
                "The doctor advised more walking and less sitting.",
                "Our train leaves at seven in the morning.",
                "I like quiet evenings and long walks.",
                "The tea was hot, and the conversation was calm.",
                "The shop on the corner always has fresh bread.",
                "She put the flowers in a glass vase.",
                "We could hear a radio playing behind the wall.",
                "The next day the snow had melted.",
                "He carefully stacked the papers and turned off the computer.",
                "The forest smelled of pine needles and wet earth.",
                "My sister sent a short message and a photograph.",
                "A large wooden desk stood near the window.",
                "We decided to stay home and watch a film.",
                "Every Saturday she goes to the market for vegetables.",
                "A familiar bus appeared at the end of the street.",
                "The kitchen smelled of coffee and warm bread.",
                "He wrote a short note and left it on the table.",
            ],
            advancedFragments: [
                "The coordinator confirmed the configuration: validation is scheduled for 14:30.",
                "The engineer reviewed the event log and found a rare anomaly.",
                "Data synchronization completed successfully; a backup was preserved.",
                "The report lists three key metrics: accuracy, latency, and stability.",
                "We discussed the trade-off between speed and reliability, then postponed the decision.",
                "The architect proposed isolating the component to simplify diagnosis.",
                "The exchange protocol was updated to version 3.2 without changing the message format.",
                "Monitoring showed that peak load occurs around 18:45.",
                "The specialist verified the signatures and confirmed the archive's integrity.",
                "If the queue overflows, the system switches to a safe mode.",
                "The editor shortened the introduction while preserving its meaning and main arguments.",
                "The deviation was only 0.4%, which is within acceptable limits.",
                "Before launch, check the dependencies and environment settings.",
                "An automated check found a mismatch in two records.",
                "We used the backup channel because the primary one was unavailable.",
                "The documentation describes recovery scenarios after a power failure.",
                "The researcher compared several approaches and chose the simplest one.",
                "The rollout took less time than initially expected.",
                "The team prepared a migration plan: stages, risks, and checkpoints.",
                "The counter value decreased by 12 units after the restart.",
                "The defect turned out to be caused by an outdated configuration.",
                "The manager asked to clarify the timeline and assign responsibilities.",
                "We preserved compatibility with older clients and formats.",
                "Boundary testing exposed a problem only with empty input.",
                "The backup server accepted traffic 6 seconds after the switch.",
                "The analyst noted growing activity in the small-business segment.",
                "The new scheme reduces stored data volume by almost half.",
                "Before publication, the layout was checked again at the minimum screen size.",
                "Support logged the request and forwarded it to the developers.",
                "We rejected the complex solution in favor of a clear, verifiable one.",
                "The log retained entries for the last 30 days.",
                "The tester reproduced the scenario and attached a detailed report.",
                "The update affects only the interface and leaves business logic unchanged.",
                "Seasonality must be considered when interpreting these numbers.",
                "The checksum matched, so the file was considered valid.",
                "The staff discussed the policy and suggested two small clarifications.",
                "The system handled the unusual character correctly and preserved word order.",
                "After a short break, the team returned to the details.",
                "We measured latency at 200 requests per second.",
                "The report includes source links and the date of the last review.",
                "The author emphasized that the conclusions are preliminary.",
                "On Monday there will be a meeting with the partner's representatives.",
            ]
        ),
    ])
}
