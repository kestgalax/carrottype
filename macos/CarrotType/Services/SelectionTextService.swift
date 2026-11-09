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

    static func readViaCopyFallback(
        pasteboard: NSPasteboard = .general,
        postCopy: (() -> Void)? = nil
    ) async throws -> String {
        try Task.checkCancellation()
        let previous = ClipboardSnapshot(pasteboard)
        let changeCountBefore = pasteboard.changeCount

        if let postCopy { postCopy() } else { postCommandC() }
        // Observe the first copy promptly instead of leaving an unconditional restore pending.
        // macOS cannot identify the writer of a clipboard change; a concurrent external copy
        // during this short fallback window is inherently indistinguishable from the target.
        for _ in 0..<12 {
            // Finish cleanup before propagating cancellation, including a copy already delivered.
            await Task.detached { try? await Task.sleep(nanoseconds: 10_000_000) }.value
            let observed = pasteboard.changeCount
            if observed != changeCountBefore {
                let copied = pasteboard.string(forType: .string)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                previous.restore(pasteboard, ifUnchangedSince: observed)
                try Task.checkCancellation()
                guard !copied.isEmpty else { throw SelectionTextError.noSelection }
                return copied
            }
        }
        try Task.checkCancellation()
        throw SelectionTextError.noSelection
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
