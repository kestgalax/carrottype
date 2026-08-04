import AppKit
import ApplicationServices
import Foundation

enum SelectionTextError: LocalizedError {
    case accessibilityDenied
    case noSelection

    var errorDescription: String? {
        switch self {
        case .accessibilityDenied:
            return L10n.t("error.accessibility_denied")
        case .noSelection:
            return L10n.t("error.no_selection")
        }
    }
}

/// Reads the current text selection in the frontmost app (ADR-012).
@MainActor
enum SelectionTextService {
    /// Prefer Accessibility selected text; fall back to ⌘C with pasteboard restore.
    static func readSelectedText() async throws -> String {
        guard AXIsProcessTrusted() else {
            throw SelectionTextError.accessibilityDenied
        }

        if let axText = readViaAccessibility(), !axText.isEmpty {
            return axText
        }

        return try await readViaCopyFallback()
    }

    private static func readViaAccessibility() -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedRef: CFTypeRef?
        let focusStatus = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )
        guard focusStatus == .success, let focusedRef else { return nil }
        let focused = focusedRef as! AXUIElement

        var selectedRef: CFTypeRef?
        let selectedStatus = AXUIElementCopyAttributeValue(
            focused,
            kAXSelectedTextAttribute as CFString,
            &selectedRef
        )
        guard selectedStatus == .success, let selectedRef else { return nil }
        let text = selectedRef as? String
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private static func readViaCopyFallback() async throws -> String {
        let pasteboard = NSPasteboard.general
        let previous = TextInsertionService.capturePasteboardItems(pasteboard)
        let changeCountBefore = pasteboard.changeCount

        postCommandC()
        // Give the frontmost app time to place the selection on the pasteboard.
        try await Task.sleep(nanoseconds: 120_000_000)

        let copied = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let changed = pasteboard.changeCount != changeCountBefore

        TextInsertionService.restorePasteboardItems(pasteboard, items: previous)

        guard changed, !copied.isEmpty else {
            throw SelectionTextError.noSelection
        }
        return copied
    }

    private static func postCommandC() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyCDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        keyCDown?.flags = .maskCommand
        let keyCUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        keyCUp?.flags = .maskCommand
        keyCDown?.post(tap: .cghidEventTap)
        keyCUp?.post(tap: .cghidEventTap)
    }
}
