import { appStyle, darkPane } from "./theme";

/**
 * Stage metrics for the 0.12.0 mic priority film.
 * Source of truth: shipped SwiftUI (`CarrotTypeSettingsView`, `AppStyle`,
 * `MicrophonePrioritySheet`) — not mockup JPGs.
 */
export const windowBox = {
  left: 280,
  top: 120,
  width: 1360,
  height: 820,
  radius: 12,
  titlebar: 52,
  /** ~200pt sidebar × stage scale */
  sidebar: 260,
} as const;

/** Content area (right of sidebar, under titlebar). */
export const contentBox = {
  left: windowBox.sidebar,
  top: windowBox.titlebar,
  width: windowBox.width - windowBox.sidebar,
  height: windowBox.height - windowBox.titlebar,
} as const;

export const cardBox = {
  left: 28,
  right: 28,
  width: contentBox.width - 56,
} as const;

/** Grouped Form rhythm: heading → hotkey → priority → formatting peek. */
export const headingBox = { top: 18, height: 72 } as const;
export const card1 = { top: 100, height: 188 } as const;
export const card2 = { top: 308, height: 118 } as const;
export const card3 = { top: 446, height: 200 } as const;
export const cardHeader = 40 as const;

export const configureButton = { width: 118, height: 28, right: 16 } as const;

/** Stage-pixel centre of «Настроить…». Shell iris opens here. */
export const iris = {
  x:
    windowBox.left +
    contentBox.left +
    cardBox.left +
    (cardBox.width - 16 - configureButton.width / 2),
  y:
    windowBox.top +
    contentBox.top +
    card2.top +
    cardHeader +
    (card2.height - cardHeader) / 2,
} as const;

/**
 * Stage-scaled sheet ≈ shipped SwiftUI frame (min ~520×420).
 * Chrome: header title + «Готово» (carrot tint), caption, inset list, drag grabber.
 */
export const sheetBox = {
  width: 980,
  height: 680,
  left: (1920 - 980) / 2,
  top: 180,
  radius: 12,
  padding: 24,
} as const;

export const sheetRows = {
  top: 168,
  height: 74,
  iconX: 32,
  textX: 66,
} as const;

/** Header «Готово» (top-right). */
export const doneButton = { width: 88, height: 28, right: 24, top: 20 } as const;

export const sheetColors = {
  ...darkPane,
  sheet: "#2C2C2E",
  sheetRow: "#3A3A3C",
  sheetBorder: "rgba(255, 255, 255, 0.12)",
  accent: appStyle.darkAccent,
  accentStrong: appStyle.controlAccent,
} as const;

export type NavItem = { title: string; symbol: string };

export const copy = {
  headline: "Приоритет микрофонов",
  subline: "Диктовка → «Настроить…» → перетащите в списке → Готово",
  establishEyebrow: "Новое в CarrotType 0.12",
  disclaimer: "Сначала используется тот, что выше · во время диктовки микрофон не меняется",
  brand: "CarrotType",
  paneTitle: "Диктовка",
  paneSubtitle: "Сочетание, микрофон, оформление и правила",
  sectionHotkey: "Диктовка",
  comboLabel: "Сочетание",
  comboValue: "⌥⌘C",
  pushToTalk: "Режим рации (удерживать для записи)",
  pushToTalkHint: "Запись идёт только при удержании. Отпустите — распознать и вставить.",
  retainClipboard: "Также оставить результат в буфере обмена",
  sectionPriority: "Приоритет микрофонов",
  activeLabel: "Активный микрофон",
  activeMicBefore: "MacBook Pro Microphone",
  activeMicAfter: "kest Microphone",
  configure: "Настроить…",
  sectionFormatting: "Оформление текста",
  formatMode: "Режим",
  formatModeValue: "Базовое",
  openModels: "Открыть Модели",
  sheetTitle: "Приоритет микрофонов",
  sheetCaption:
    "CarrotType использует первый доступный микрофон из списка; если ни один не доступен — системный по умолчанию. Недоступные остаются в списке и снова включаются после подключения; во время диктовки микрофон не меняется. Порядок меняется перетаскиванием.",
  done: "Готово",
  statusActive: "Активный",
  statusUnavailable: "Недоступен",
  statusReady: "Готов",
  whatsNew: "Что нового",
  appliedNote: "Новый порядок действует сразу — сохранять ничего не нужно",
  nav: [
    { title: "Основные", symbol: "info" },
    { title: "Диктовка", symbol: "mic" },
    { title: "Преобразования", symbol: "text" },
    { title: "Dynamic Island", symbol: "capsule" },
    { title: "Настройка", symbol: "gear" },
    { title: "Модели", symbol: "cpu" },
    { title: "Хранилище", symbol: "drive" },
    { title: "Статистика", symbol: "chart" },
  ] as const satisfies readonly NavItem[],
} as const;

export type MicRow = { name: string; status?: string };

/** Sheet order before the drag. */
export const rowsBefore: readonly MicRow[] = [
  { name: "Elgato Wave Link Voice", status: copy.statusUnavailable },
  { name: "MacBook Pro Microphone", status: copy.statusActive },
  { name: "kest Microphone" },
  { name: "Wave Link Stream" },
];

/** After the drag: promoted mic owns the Active badge. */
export const rowsAfter: readonly MicRow[] = [
  { name: "kest Microphone", status: copy.statusActive },
  { name: "Elgato Wave Link Voice", status: copy.statusUnavailable },
  { name: "MacBook Pro Microphone" },
  { name: "Wave Link Stream" },
];
