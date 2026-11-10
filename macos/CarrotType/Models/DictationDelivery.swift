import Foundation

/// Selects exactly one sink; trial delivery never invokes the caret/clipboard/statistics closure.
enum DictationDelivery {
    case caret
    case setupTrial

    func deliver(_ result: FormattedDictation,
                 atCaret: (FormattedDictation) throws -> Void,
                 inTrial: (FormattedDictation) -> Void) rethrows {
        switch self {
        case .caret: try atCaret(result)
        case .setupTrial: inTrial(result)
        }
    }
}
