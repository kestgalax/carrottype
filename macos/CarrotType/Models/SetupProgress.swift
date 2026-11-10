import Foundation

struct SetupProgress {
    enum Step: Int, CaseIterable {
        case microphone, accessibility, model, trial
        var titleKey: String { ["permissions.microphone", "permissions.accessibility", "setup.step.model", "setup.step.trial"][rawValue] }
    }
    let microphone: Bool
    let accessibility: Bool
    let model: Bool
    let trial: Bool

    func isComplete(_ step: Step) -> Bool {
        [microphone, accessibility, model, trial][step.rawValue]
    }
    var completedCount: Int { Step.allCases.filter(isComplete).count }
    var nextStep: Step? { Step.allCases.first { !isComplete($0) } }
}
