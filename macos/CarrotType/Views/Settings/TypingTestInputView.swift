import AppKit
import SwiftUI

/// Tiny transparent native text view used only to accept committed text input.
/// It blocks paste/drop/undo/autocorrect and lets the real native input system handle
/// Backspace, dead keys and marked IME text.
@MainActor
final class TypingTestInputController {
    weak var textView: TypingTestField?

    @discardableResult
    func focus() -> Bool {
        guard let textView, let window = textView.window else { return false }
        return window.makeFirstResponder(textView)
    }

    func resign() {
        guard let textView, let window = textView.window,
              window.firstResponder === textView else { return }
        window.makeFirstResponder(nil)
    }
}

final class TypingTestField: NSTextView {
    var onEscape: (() -> Void)?
    var onFocusLost: (() -> Void)?
    var onMarkedTextChange: (() -> Void)?

    override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        super.setMarkedText(string, selectedRange: selectedRange, replacementRange: replacementRange)
        onMarkedTextChange?()
    }

    override func unmarkText() {
        super.unmarkText()
        onMarkedTextChange?()
    }

    override func keyDown(with event: NSEvent) {
        // Leave system/AppKit command handling alone; the test field does not own
        // global shortcuts. Block command/control editing chord injection only.
        if !event.modifierFlags.intersection([.command, .control]).isEmpty { return }
        interpretKeyEvents([event])
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool { false }

    override func paste(_ sender: Any?) {}
    override func pasteAsPlainText(_ sender: Any?) {}
    override func pasteAsRichText(_ sender: Any?) {}
    override func insertNewline(_ sender: Any?) {}
    override func insertTab(_ sender: Any?) {}
    override func cancelOperation(_ sender: Any?) { onEscape?() }

    override func readSelection(from pboard: NSPasteboard) -> Bool { false }
    override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool { false }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool { false }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned { onFocusLost?() }
        return resigned
    }
}

struct TypingTestInputView: NSViewRepresentable {
    let text: String
    let documentToken: UUID
    let isEnabled: Bool
    let locale: Locale
    let controller: TypingTestInputController
    let onEdit: (TypingTestEdit) -> Void
    let onCompositionChange: (String) -> Void
    let onEscape: () -> Void
    let onFocusLost: () -> Void

    func makeNSView(context: Context) -> TypingTestField {
        let view = TypingTestField(frame: .zero)
        view.delegate = context.coordinator
        view.isRichText = false
        view.importsGraphics = false
        view.allowsUndo = false
        view.drawsBackground = false
        view.isEditable = true
        view.isSelectable = true
        view.isAutomaticQuoteSubstitutionEnabled = false
        view.isAutomaticDashSubstitutionEnabled = false
        view.isAutomaticTextReplacementEnabled = false
        view.isAutomaticSpellingCorrectionEnabled = false
        view.isAutomaticLinkDetectionEnabled = false
        view.isAutomaticDataDetectionEnabled = false
        view.isAutomaticTextCompletionEnabled = false
        view.isContinuousSpellCheckingEnabled = false
        view.isGrammarCheckingEnabled = false
        view.smartInsertDeleteEnabled = false
        view.usesFindBar = false
        view.isIncrementalSearchingEnabled = false
        view.textColor = .clear
        view.insertionPointColor = .clear
        view.focusRingType = .none
        view.selectedTextAttributes = [
            .backgroundColor: NSColor.clear,
            .foregroundColor: NSColor.clear,
        ]
        view.font = .monospacedSystemFont(ofSize: 19, weight: .regular)
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.textContainer?.widthTracksTextView = false
        view.textContainer?.containerSize = NSSize(width: 100_000, height: 100_000)
        view.isHorizontallyResizable = true
        view.isVerticallyResizable = true
        view.autoresizingMask = [.width, .height]
        view.onEscape = onEscape
        view.onFocusLost = onFocusLost
        view.onMarkedTextChange = { [weak view, weak coordinator = context.coordinator] in
            guard let view else { return }
            coordinator?.publishComposition(from: view)
        }
        view.string = text
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.textArea)
        view.setAccessibilityLabel(L10n.t("typingtest.input.accessibility", locale: locale))
        controller.textView = view
        context.coordinator.lastText = text
        context.coordinator.documentToken = documentToken
        return view
    }

    func updateNSView(_ view: TypingTestField, context: Context) {
        context.coordinator.parent = self
        view.onEscape = onEscape
        view.onFocusLost = onFocusLost
        view.isEditable = isEnabled
        view.setAccessibilityLabel(L10n.t("typingtest.input.accessibility", locale: locale))
        if context.coordinator.documentToken != documentToken {
            context.coordinator.documentToken = documentToken
            context.coordinator.lastText = text
            view.string = text
            view.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TypingTestInputView
        var lastText = ""
        var documentToken: UUID?

        init(parent: TypingTestInputView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? TypingTestField else { return }
            if view.hasMarkedText() {
                publishComposition(from: view)
                return
            }
            parent.onCompositionChange("")
            let next = view.string
            let previous = lastText
            lastText = next
            if let edit = TypingTestEdit.between(previous, next) {
                parent.onEdit(edit)
            }
        }

        func publishComposition(from view: TypingTestField) {
            guard view.hasMarkedText() else {
                parent.onCompositionChange("")
                return
            }
            let marked = view.markedRange()
            let text = view.string as NSString
            parent.onCompositionChange(
                marked.location == NSNotFound ? "" : text.substring(with: marked)
            )
        }
    }
}

/// Non-editable native TextKit view that renders the fixed prompt with per-character
/// feedback. It scrolls by line to keep the caret visible without moving the window.
final class TypingPromptDisplayView: NSView {
    private let textStorage = NSTextStorage()
    private let layoutManager = NSLayoutManager()
    private let textContainer = NSTextContainer(size: .zero)
    private let inset = NSSize(width: 2, height: 6)
    private var caretUTF16 = 0

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = .byWordWrapping
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        setAccessibilityRole(.staticText)
    }

    required init?(coder: NSCoder) { nil }

    func update(attributed: NSAttributedString, caretUTF16: Int, accessibilityValue: String) {
        textStorage.setAttributedString(attributed)
        self.caretUTF16 = caretUTF16
        setAccessibilityValue(accessibilityValue)
        textContainer.size = NSSize(
            width: max(0, bounds.width - inset.width * 2),
            height: .greatestFiniteMagnitude
        )
        layoutManager.ensureLayout(for: textContainer)
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        textContainer.size = NSSize(
            width: max(0, bounds.width - inset.width * 2),
            height: .greatestFiniteMagnitude
        )
        layoutManager.ensureLayout(for: textContainer)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current else { return }
        layoutManager.ensureLayout(for: textContainer)
        let glyphCount = layoutManager.numberOfGlyphs
        guard glyphCount > 0 else { return }
        let offset = scrollOffset(glyphCount: glyphCount)
        let origin = NSPoint(x: inset.width, y: inset.height - offset)
        let glyphRange = NSRange(location: 0, length: glyphCount)
        var visibleLineTops: [CGFloat] = []
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { rect, _, _, _, _ in
            let top = rect.minY + origin.y
            let bottom = rect.maxY + origin.y
            if bottom > 0, top < self.bounds.height {
                visibleLineTops.append(top)
            }
        }
        let clipHeight = visibleLineTops.count > 3
            ? min(self.bounds.height, visibleLineTops[3])
            : self.bounds.height
        context.saveGraphicsState()
        NSBezierPath(rect: NSRect(
            x: bounds.minX,
            y: bounds.minY,
            width: bounds.width,
            height: max(0, clipHeight)
        )).addClip()
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: origin)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: origin)
        context.restoreGraphicsState()
    }

    private func scrollOffset(glyphCount: Int) -> CGFloat {
        let characterIndex = min(max(0, caretUTF16), textStorage.length)
        let range = layoutManager.glyphRange(
            forCharacterRange: NSRange(location: characterIndex, length: 0),
            actualCharacterRange: nil
        )
        let glyphIndex = min(max(0, range.location), glyphCount - 1)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        let usedHeight = layoutManager.usedRect(for: textContainer).height + inset.height * 2
        let maxOffset = max(0, usedHeight - bounds.height)
        let desired = lineRect.minY + inset.height - lineRect.height
        return min(max(0, desired), maxOffset)
    }
}

struct TypingPromptView: NSViewRepresentable {
    let prompt: String
    let typed: String
    let composition: String
    var showCaret: Bool = true
    let locale: Locale

    func makeNSView(context: Context) -> TypingPromptDisplayView {
        TypingPromptDisplayView(frame: .zero)
    }

    func updateNSView(_ view: TypingPromptDisplayView, context: Context) {
        view.setAccessibilityLabel(L10n.t("typingtest.prompt.accessibility", locale: locale))
        view.update(
            attributed: TypingPromptRenderer.render(
                prompt: prompt,
                typed: typed,
                composition: composition,
                showCaret: showCaret
            ),
            caretUTF16: TypingPromptRenderer.caretUTF16Location(
                prompt: prompt,
                typed: typed,
                composition: composition
            ),
            accessibilityValue: String(
                format: L10n.t("typingtest.prompt.value", locale: locale),
                typed.count,
                prompt.count
            )
        )
    }
}

enum TypingPromptRenderer {
    static func render(
        prompt: String,
        typed: String,
        composition: String,
        showCaret: Bool = true
    ) -> NSAttributedString {
        let expected = Array(prompt)
        let typedGraphemes = Array(typed)
        let font = NSFont.monospacedSystemFont(ofSize: 19, weight: .regular)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 4
        let base: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraph,
            .foregroundColor: NSColor.secondaryLabelColor,
        ]

        let result = NSMutableAttributedString()
        var location = 0

        func append(_ character: Character, attributes: [NSAttributedString.Key: Any]) {
            let piece = String(character)
            result.append(NSAttributedString(string: piece, attributes: attributes))
            location += (piece as NSString).length
        }

        for index in expected.indices {
            var attributes = base
            if index < typedGraphemes.count {
                if typedGraphemes[index] == expected[index] {
                    attributes[.foregroundColor] = NSColor.labelColor
                } else {
                    attributes[.foregroundColor] = NSColor.systemRed
                    attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                    attributes[.underlineColor] = NSColor.systemRed
                }
            } else if composition.isEmpty, showCaret, index == typedGraphemes.count {
                attributes[.foregroundColor] = NSColor.labelColor
                attributes[.backgroundColor] = NSColor.controlAccentColor.withAlphaComponent(0.22)
            }
            append(expected[index], attributes: attributes)

            if index + 1 == typedGraphemes.count, !composition.isEmpty {
                for composed in composition {
                    var composedAttributes = base
                    composedAttributes[.foregroundColor] = NSColor.controlAccentColor
                    composedAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                    append(composed, attributes: composedAttributes)
                }
            }
        }

        if typedGraphemes.count > expected.count {
            for index in expected.count..<typedGraphemes.count {
                var attributes = base
                attributes[.foregroundColor] = NSColor.systemRed
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                append(typedGraphemes[index], attributes: attributes)
            }
        }

        if !composition.isEmpty, typedGraphemes.count >= expected.count {
            for composed in composition {
                var composedAttributes = base
                composedAttributes[.foregroundColor] = NSColor.controlAccentColor
                composedAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                append(composed, attributes: composedAttributes)
            }
        }

        return result
    }

    static func caretUTF16Location(prompt: String, typed: String, composition: String) -> Int {
        let expected = Array(prompt)
        let typedGraphemes = Array(typed)
        var location = 0
        for index in 0..<min(typedGraphemes.count, expected.count) {
            location += (String(expected[index]) as NSString).length
        }
        if typedGraphemes.count > expected.count {
            for index in expected.count..<typedGraphemes.count {
                location += (String(typedGraphemes[index]) as NSString).length
            }
        }
        if typedGraphemes.count < expected.count || !composition.isEmpty {
            location += (composition as NSString).length
        }
        return location
    }
}
