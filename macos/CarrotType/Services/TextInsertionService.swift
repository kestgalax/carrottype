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
        let previous = ClipboardSnapshot(pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(trimmed, forType: .string)
        let ownedChangeCount = pasteboard.changeCount

        postCommandV()

        guard !retainInClipboard else { return }

        // Restore clipboard after the target app has consumed paste (keep window short — ADR-015 / Secure Coding).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            previous.restore(pasteboard, ifUnchangedSince: ownedChangeCount)
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
