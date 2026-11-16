import { darkPane } from "./theme";

/**
 * Stage metrics for the 0.12.0 mic priority film. The Settings window is
 * staged at ~1:1 against the 1920×1080 stage so 15–17 px app type stays legible
 * (the mockups in `docs/mockups/mic-priority-mockup-a-*.jpg` are 1280-wide).
 */
export const windowBox = {
  left: 296,
  top: 150,
  width: 1328,
  height: 740,
  radius: 18,
  titlebar: 46,
  sidebar: 300,
} as const;

/** Content area of the window (right of the sidebar, under the titlebar). */
export const contentBox = {
  left: windowBox.sidebar,
  top: windowBox.titlebar,
  width: windowBox.width - windowBox.sidebar,
  height: windowBox.height - windowBox.titlebar,
} as const;

export const cardBox = {
  left: 32,
  right: 32,
  width: contentBox.width - 64,
} as const;

/** Dictation cards: compact priority row sits between hotkey and formatting. */
export const card1 = { top: 104, height: 168 } as const;
export const card2 = { top: 296, height: 156 } as const;
export const card3 = { top: 476, height: 200 } as const;
export const cardHeader = 56 as const;

export const configureButton = { width: 136, height: 40, right: 20 } as const;

/** Stage-pixel centre of «Настроить…». Shell iris opens here. */
export const iris = {
  x:
    windowBox.left +
    contentBox.left +
    cardBox.left +
    (cardBox.width - 20 - configureButton.width / 2),
  y:
    windowBox.top +
    contentBox.top +
    card2.top +
    cardHeader +
    (card2.height - cardHeader) / 2,
} as const;

export const sheetBox = {
  width: 1120,
  height: 620,
  left: (1920 - 1120) / 2,
  top: 226,
  radius: 22,
  padding: 40,
} as const;

export const sheetRows = {
  top: 168,
  height: 88,
  iconX: 36,
  textX: 78,
} as const;

export const doneButton = { width: 132, height: 44, right: 36, bottom: 34 } as const;

export const sheetColors = {
  ...darkPane,
  sheet: "#2A2B31",
  sheetRow: "#2E2F36",
  sheetBorder: "rgba(255, 255, 255, 0.10)",
} as const;

export const copy = {
  headline: "Приоритет микрофонов",
  subline: "Dictation → «Настроить…» → drag reorder → Готово",
  establishEyebrow: "Приоритет микрофонов — 0.12.0",
  disclaimer: "Меняется порядок failover · во время диктовки микрофон не меняется",
  paneTitle: "Диктовка",
  sectionHotkey: "Горячая клавиша",
  comboLabel: "Комбинация клавиш",
  comboValue: "⌥⌘C",
  pushToTalk: "Режим рации",
  sectionPriority: "Приоритет микрофонов",
  activeLabel: "Активный микрофон",
  activeMicBefore: "MacBook Pro Microphone",
  activeMicAfter: "kest Microphone",
  configure: "Настроить…",
  sectionFormatting: "Оформление текста",
  autocorrect: "Автозамена",
  sheetTitle: "Приоритет микрофонов",
  sheetCaption:
    "CarrotType использует первый подключённый микрофон из списка; если ни один из них не подключён — системный микрофон по умолчанию. Отключённые остаются и снова используются после подключения; во время диктовки микрофон не меняется.",
  done: "Готово",
  statusActive: "Активный",
  statusUnavailable: "Недоступен",
  appliedNote: "Порядок применяется сразу · без отдельного сохранения",
  nav: ["Основные", "Диктовка", "Текстовые действия", "Dynamic Island", "Настройка", "Модели"],
} as const;

export type MicRow = { name: string; status?: string };

/** Sheet order before the drag: macOS default first, promoted mic third. */
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
