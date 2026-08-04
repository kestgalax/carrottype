import AppKit
import ApplicationServices
import Foundation

enum TextInsertionError: LocalizedError {
    case accessibilityDenied
    case emptyText

    var errorDescription: String? {
        switch self {
        case .accessibilityDenied:
            return L10n.t("error.accessibility_denied")
        case .emptyText:
            return L10n.t("error.empty_text")
        }
    }
}

/// Pastes text at the caret in the frontmost app (clipboard + ⌘V).
/// By default restores the previous clipboard after a short delay.
@MainActor
enum TextInsertionService {
    static func insertAtCaret(_ text: String, retainInClipboard: Bool = false) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TextInsertionError.emptyText }

        guard AXIsProcessTrusted() else {
            throw TextInsertionError.accessibilityDenied
        }

        let pasteboard = NSPasteboard.general
        let previous = retainInClipboard ? [] : capturePasteboardItems(pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(trimmed, forType: .string)

        postCommandV()

        guard !retainInClipboard else { return }

        // Restore clipboard after the target app has consumed paste.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            restorePasteboardItems(pasteboard, items: previous)
        }
    }

    static func capturePasteboardItems(_ pasteboard: NSPasteboard) -> [[String: Data]] {
        guard let items = pasteboard.pasteboardItems else { return [] }
        return items.map { item in
            var map: [String: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    map[type.rawValue] = data
                }
            }
            return map
        }
    }

    static func restorePasteboardItems(_ pasteboard: NSPasteboard, items: [[String: Data]]) {
        guard !items.isEmpty else { return }
        pasteboard.clearContents()
        for map in items {
            let item = NSPasteboardItem()
            for (type, data) in map {
                item.setData(data, forType: NSPasteboard.PasteboardType(type))
            }
            pasteboard.writeObjects([item])
        }
    }

    private static func postCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyVDown?.flags = .maskCommand
        let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyVUp?.flags = .maskCommand

        keyVDown?.post(tap: .cghidEventTap)
        keyVUp?.post(tap: .cghidEventTap)
    }
}
