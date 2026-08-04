import Foundation
import NaturalLanguage

struct LanguagePairFlipResult: Equatable {
    var sourceCode: String
    var targetCode: String
    var usedFallback: Bool
}

enum LanguagePairDetector {
    private static let confidenceThreshold: Double = 0.4

    static func preferredTarget(
        languageA: String,
        languageB: String,
        uiLanguageCode: String
    ) -> String {
        let ui = TransformLanguageCatalog.normalize(uiLanguageCode)
        if ui == languageA || ui.hasPrefix(languageA) || languageA.hasPrefix(ui) {
            return languageA
        }
        if ui == languageB || ui.hasPrefix(languageB) || languageB.hasPrefix(ui) {
            return languageB
        }
        return languageB
    }

    static func flip(
        text: String,
        languageA: String,
        languageB: String,
        preferredTarget: String
    ) -> LanguagePairFlipResult {
        let a = TransformLanguageCatalog.normalize(languageA)
        let b = TransformLanguageCatalog.normalize(languageB)
        let preferred = TransformLanguageCatalog.normalize(preferredTarget)

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let hypotheses = recognizer.languageHypotheses(withMaximum: 5)

        var bestInPair: (code: String, score: Double)?
        for (language, score) in hypotheses {
            let code = TransformLanguageCatalog.normalize(language.rawValue)
            guard code == a || code == b else { continue }
            if bestInPair == nil || score > bestInPair!.score {
                bestInPair = (code, score)
            }
        }

        if let best = bestInPair, best.score >= confidenceThreshold {
            let target = best.code == a ? b : a
            return LanguagePairFlipResult(sourceCode: best.code, targetCode: target, usedFallback: false)
        }

        let target = (preferred == a || preferred == b) ? preferred : b
        let source = target == a ? b : a
        return LanguagePairFlipResult(sourceCode: source, targetCode: target, usedFallback: true)
    }

    static func translateInstruction(targetCode: String, uiLocale: Locale) -> String {
        let name = TransformLanguageCatalog.displayName(code: targetCode, locale: uiLocale)
        let isRU = uiLocale.language.languageCode?.identifier.hasPrefix("ru") == true
        if isRU {
            return "Переведи на \(name). Выведи только перевод, без кавычек и пояснений."
        }
        return "Translate into \(name). Output only the translation, with no quotes or commentary."
    }

    static func directionLabel(sourceCode: String, targetCode: String) -> String {
        "\(TransformLanguageCatalog.shortLabel(code: sourceCode)) → \(TransformLanguageCatalog.shortLabel(code: targetCode))"
    }
}
