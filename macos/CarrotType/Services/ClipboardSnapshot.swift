import AppKit

/// A transaction may restore the clipboard only while its last observed version is current.
@MainActor
struct ClipboardSnapshot {
    let items: [[NSPasteboard.PasteboardType: Data]]

    init(_ pasteboard: NSPasteboard) {
        items = (pasteboard.pasteboardItems ?? []).map { item in
            var values: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) { values[type] = data }
            }
            return values
        }
    }

    @discardableResult
    func restore(_ pasteboard: NSPasteboard, ifUnchangedSince changeCount: Int) -> Bool {
        guard pasteboard.changeCount == changeCount else { return false }
        let restored = items.map { values in
            let item = NSPasteboardItem()
            for (type, data) in values { item.setData(data, forType: type) }
            return item
        }
        pasteboard.clearContents()
        return restored.isEmpty || pasteboard.writeObjects(restored)
    }
}
