import Foundation
import SwiftUI

@MainActor
final class TypingSpeedTestSheetModel: ObservableObject {
    enum Screen: Equatable {
        case ready
        case armed
        case running
        case result
    }

    @Published private(set) var screen: Screen = .ready
    @Published private(set) var promptText = ""
    @Published private(set) var typedText = ""
    @Published private(set) var compositionText = ""
    @Published private(set) var remainingSeconds = 30
    @Published private(set) var result: TypingTestResult?
    @Published private(set) var notice: String?
    @Published private(set) var documentToken = UUID()
    @Published private(set) var inputEnabled = false
    @Published private(set) var focusRequest: UUID?
    @Published private(set) var isTimerRunning = false
    @Published private(set) var language: TypingTestLanguage
    @Published private(set) var level: TypingTestLevel

    let inputController: TypingTestInputController
    let appState: AppState
    let locale: Locale

    private let builder: TypingTestPromptBuilder
    private let clock: () -> TimeInterval
    private let makeSeed: () -> UInt64
    private let tickInterval: TimeInterval
    private var engine: TypingSpeedTestEngine?
    private var timer: Timer?
    private var lastPromptText: String?
    private var didInitialize = false
    private var isClosing = false
    private var suppressFocusLoss = false
    private var onRequestClose: (() -> Void)?

    init(
        appState: AppState,
        locale: Locale,
        initialLanguage: TypingTestLanguage? = nil,
        initialLevel: TypingTestLevel = .defaultLevel,
        builder: TypingTestPromptBuilder = TypingTestPromptBuilder(),
        clock: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        makeSeed: @escaping () -> UInt64 = { UInt64.random(in: .min ... .max) },
        tickInterval: TimeInterval = 0.1
    ) {
        let controller = TypingTestInputController()
        self.inputController = controller
        self.appState = appState
        self.locale = locale
        self.language = initialLanguage
            ?? (locale.language.languageCode?.identifier == "ru" ? .russian : .english)
        self.level = initialLevel
        self.builder = builder
        self.clock = clock
        self.makeSeed = makeSeed
        self.tickInterval = tickInterval
        appState.typingSpeedTest.onInvalidated = { [weak self] in
            self?.handleLifecycleInvalidation()
        }
        buildPrompt()
        didInitialize = true
    }

    var canApplyResult: Bool { result?.canApply == true }

    func setOnRequestClose(_ handler: @escaping () -> Void) {
        onRequestClose = handler
    }

    func setLanguage(_ language: TypingTestLanguage) {
        guard language != self.language else { return }
        self.language = language
        guard didInitialize else { return }
        restartForConfigurationChange()
    }

    func setLevel(_ level: TypingTestLevel) {
        guard level != self.level else { return }
        self.level = level
        guard didInitialize else { return }
        restartForConfigurationChange()
    }

    /// Ready → armed/focused. No gate lease or countdown yet. The native field is
    /// mounted by the armed/running view and requests focus only after its window
    /// attachment is real; the async one-shot result carries this token.
    func start() {
        guard screen == .ready, engine != nil, !promptText.isEmpty else { return }
        guard appState.typingSpeedTest.acquireInputFocus() else {
            notice = L10n.t("typingtest.busy", locale: locale)
            return
        }
        notice = nil
        screen = .armed
        inputEnabled = true
        remainingSeconds = Int(engine?.duration ?? 30)
        focusRequest = UUID()
    }

    /// Token-safe focus completion from the actual native field. A stale or failed
    /// request returns to Ready without leaving the gate/hotkey ownership behind.
    func handleInputFocusResult(_ focused: Bool, token: UUID) {
        guard screen == .armed, focusRequest == token else { return }
        if focused {
            notice = nil
            return
        }
        focusRequest = nil
        inputEnabled = false
        screen = .ready
        appState.typingSpeedTest.releaseFocus()
        notice = L10n.t("typingtest.focus_failed", locale: locale)
    }

    func handleEdit(_ edit: TypingTestEdit) {
        guard screen == .armed || screen == .running, let engine else { return }
        if screen == .armed {
            guard !edit.replacement.isEmpty else { return }
            guard appState.typingSpeedTest.beginRun() else {
                notice = L10n.t("typingtest.busy", locale: locale)
                resetInputAfterFailedStart()
                return
            }
            screen = .running
            startTimer()
        }

        engine.apply(edit, now: clock())
        promptText = engine.promptText
        typedText = engine.typedText
        remainingSeconds = displayRemaining(engine.remainingSeconds)
        if engine.phase == .completed {
            finish()
        }
    }

    func handleCompositionChange(_ text: String) {
        compositionText = text
    }

    /// Test-only/manual tick seam; production uses the single Timer below.
    func handleTick() {
        guard screen == .running, let engine else { return }
        remainingSeconds = displayRemaining(engine.remainingSeconds)
        if engine.tick(now: clock()) {
            finish()
        }
    }

    func handleFocusLost() {
        guard !suppressFocusLoss, !isClosing else { return }
        guard screen == .armed || screen == .running else { return }
        cancelToReady(rebuildPrompt: true)
    }

    func handleLifecycleInvalidation() {
        guard screen == .armed || screen == .running else { return }
        cancelToReady(rebuildPrompt: true)
    }

    func requestClose() {
        guard !isClosing else { return }
        isClosing = true
        stopTimer()
        engine?.cancel()
        inputEnabled = false
        focusRequest = nil
        resignInput()
        appState.typingSpeedTest.releaseFocus()
        onRequestClose?()
    }

    /// Real dictation/transform/install wins without applying a result.
    func dismissForExternalOperation() {
        requestClose()
    }

    func repeatAttempt() {
        stopTimer()
        engine?.cancel()
        inputEnabled = false
        focusRequest = nil
        resignInput()
        appState.typingSpeedTest.releaseFocus()
        result = nil
        screen = .ready
        notice = nil
        compositionText = ""
        buildPrompt()
    }

    func applyResult() {
        guard let result, result.canApply else {
            notice = outOfRangeNotice
            return
        }
        guard appState.applyMeasuredTypingSpeed(result.roundedWPM) else {
            notice = outOfRangeNotice
            return
        }
        requestClose()
    }

    func sheetDidDisappear() {
        stopTimer()
        engine?.cancel()
        inputEnabled = false
        focusRequest = nil
        resignInput()
        appState.typingSpeedTest.releaseFocus()
        appState.typingSpeedTest.onInvalidated = nil
        onRequestClose = nil
    }

    var outOfRangeNotice: String? {
        guard let result else { return nil }
        if result.creditedCharacters == 0 || result.attempts == 0 {
            return L10n.t("typingtest.result.empty", locale: locale)
        }
        if !result.isWPMInExistingRange {
            return String(
                format: L10n.t("typingtest.result.range", locale: locale),
                UsageStatsEstimate.minimumWPM,
                UsageStatsEstimate.maximumWPM
            )
        }
        return nil
    }

    // MARK: - Internals

    private func restartForConfigurationChange() {
        stopTimer()
        engine?.cancel()
        inputEnabled = false
        focusRequest = nil
        resignInput()
        appState.typingSpeedTest.releaseFocus()
        result = nil
        screen = .ready
        notice = nil
        compositionText = ""
        buildPrompt()
    }

    private func cancelToReady(rebuildPrompt: Bool) {
        stopTimer()
        engine?.cancel()
        inputEnabled = false
        focusRequest = nil
        resignInput()
        appState.typingSpeedTest.releaseFocus()
        screen = .ready
        result = nil
        notice = nil
        compositionText = ""
        if rebuildPrompt {
            buildPrompt()
        } else {
            typedText = ""
        }
    }

    private func resignInput() {
        suppressFocusLoss = true
        inputController.resign()
        suppressFocusLoss = false
    }

    /// A real operation may win between armed and the first grapheme. Build a
    /// fresh engine/prompt so Start can be retried; a cancelled engine must not be
    /// reused by the next attempt.
    private func resetInputAfterFailedStart() {
        stopTimer()
        engine?.cancel()
        inputEnabled = false
        focusRequest = nil
        resignInput()
        appState.typingSpeedTest.releaseFocus()
        screen = .ready
        result = nil
        compositionText = ""
        buildPrompt()
        notice = L10n.t("typingtest.busy", locale: locale)
    }

    private func finish() {
        guard let engine, let completed = engine.result else {
            cancelToReady(rebuildPrompt: true)
            return
        }
        stopTimer()
        result = completed
        promptText = engine.promptText
        typedText = engine.typedText
        compositionText = ""
        screen = .result
        inputEnabled = false
        focusRequest = nil
        appState.typingSpeedTest.releaseFocus()
        resignInput()
    }

    private func buildPrompt() {
        do {
            let next = try builder.makePrompt(
                language: language,
                level: level,
                seed: makeSeed(),
                avoiding: lastPromptText
            )
            lastPromptText = next.text
            let nextEngine = TypingSpeedTestEngine(
                prompt: next,
                builder: builder,
                clock: clock
            )
            engine = nextEngine
            promptText = next.text
            typedText = ""
            compositionText = ""
            remainingSeconds = Int(nextEngine.duration)
            notice = nil
            documentToken = UUID()
        } catch {
            engine = nil
            promptText = ""
            typedText = ""
            compositionText = ""
            notice = L10n.t("typingtest.corpus_error", locale: locale)
        }
    }

    private func startTimer() {
        stopTimer()
        let timer = Timer(timeInterval: tickInterval, repeats: true) { [weak self] timer in
            guard self != nil else {
                timer.invalidate()
                return
            }
            Task { @MainActor [weak self] in
                self?.handleTick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        isTimerRunning = true
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }

    private func displayRemaining(_ value: TimeInterval) -> Int {
        max(0, Int(value.rounded(.up)))
    }
}

struct TypingSpeedTestSheet: View {
    @ObservedObject var appState: AppState
    @StateObject private var model: TypingSpeedTestSheetModel
    @Environment(\.dismiss) private var dismiss

    init(appState: AppState) {
        self.appState = appState
        let locale = appState.effectiveLocale
        _model = StateObject(wrappedValue: TypingSpeedTestSheetModel(
            appState: appState,
            locale: locale
        ))
    }

    /// Fixture-only injection for native layout evidence; normal runtime creates its
    /// own RAM-only model in the initializer above.
    init(appState: AppState, fixtureModel: TypingSpeedTestSheetModel) {
        self.appState = appState
        _model = StateObject(wrappedValue: fixtureModel)
    }

    private var locale: Locale { appState.effectiveLocale }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                content
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.automatic)
            Divider()
            footer
        }
        .frame(width: 600, height: 390)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.locale, locale)
        .onAppear {
            model.setOnRequestClose { dismiss() }
        }
        .onDisappear {
            model.sheetDidDisappear()
        }
        .onChange(of: appState.typingSpeedTestDismissRequest) { _, request in
            if request != nil {
                model.dismissForExternalOperation()
                dismiss()
            }
        }
        .onReceive(appState.updates.$isWaitingForOperation) { waiting in
            if waiting {
                model.dismissForExternalOperation()
                dismiss()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.t("typingtest.title", locale: locale))
                    .font(.headline)
                Text(L10n.t("typingtest.subtitle", locale: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if model.screen == .running {
                Text(String(format: L10n.t("typingtest.remaining", locale: locale), model.remainingSeconds))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(L10n.t("typingtest.remaining.accessibility", locale: locale))
                    .accessibilityValue("\(model.remainingSeconds)")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        switch model.screen {
        case .ready:
            readyContent
        case .armed, .running:
            runningContent
        case .result:
            resultContent
        }
    }

    private var readyContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                Picker(L10n.t("typingtest.language", locale: locale), selection: languageBinding) {
                    ForEach(TypingTestLanguage.allCases) { language in
                        Text(languageTitle(language)).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Picker(L10n.t("typingtest.level", locale: locale), selection: levelBinding) {
                    ForEach(TypingTestLevel.allCases) { level in
                        Text(levelTitle(level)).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            TypingPromptView(
                prompt: model.promptText,
                typed: "",
                composition: "",
                showCaret: false,
                locale: locale
            )
            .frame(height: 88)
            .accessibilityElement(children: .contain)

            Text(L10n.t("typingtest.instruction", locale: locale))
                .font(.callout)
                .foregroundStyle(.secondary)

            if let notice = model.notice {
                Text(notice)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var runningContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                TypingPromptView(
                    prompt: model.promptText,
                    typed: model.typedText,
                    composition: model.compositionText,
                    showCaret: true,
                    locale: locale
                )
                .frame(height: 88)

                TypingTestInputView(
                    text: model.typedText,
                    documentToken: model.documentToken,
                    isEnabled: model.inputEnabled,
                    locale: locale,
                    focusRequest: model.focusRequest,
                    controller: model.inputController,
                    onEdit: { model.handleEdit($0) },
                    onCompositionChange: { model.handleCompositionChange($0) },
                    onEscape: { model.requestClose() },
                    onFocusLost: { model.handleFocusLost() },
                    onFocusResult: { focused, token in
                        model.handleInputFocusResult(focused, token: token)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.01)
            }

            if model.screen == .armed {
                Text(L10n.t("typingtest.start_typing", locale: locale))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let notice = model.notice {
                Text(notice)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var resultContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let result = model.result {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(result.roundedWPM)")
                        .font(.system(size: 46, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .accessibilityLabel(L10n.t("typingtest.result.wpm", locale: locale))
                    Text(L10n.t("typingtest.result.wpm", locale: locale))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Text(resultDetails(result))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(resultDetails(result))

                if result.accuracyPercent < 90, result.attempts > 0 {
                    Text(L10n.t("typingtest.result.low_accuracy", locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let notice = model.outOfRangeNotice {
                    Text(notice)
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text(L10n.t("typingtest.result.apply_note", locale: locale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        HStack(spacing: 10) {
            if model.screen == .armed || model.screen == .running {
                Button(L10n.t("typingtest.cancel", locale: locale)) {
                    model.requestClose()
                }
                .keyboardShortcut(.cancelAction)
            } else if model.screen == .result {
                Button(L10n.t("typingtest.repeat", locale: locale)) {
                    model.repeatAttempt()
                }
                Button(L10n.t("typingtest.close", locale: locale)) {
                    model.requestClose()
                }
                .keyboardShortcut(.cancelAction)
            } else {
                Button(L10n.t("typingtest.close", locale: locale)) {
                    model.requestClose()
                }
                .keyboardShortcut(.cancelAction)
            }
            Spacer()
            if model.screen == .ready {
                Button(L10n.t("typingtest.start", locale: locale)) {
                    model.start()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(model.promptText.isEmpty)
            } else if model.screen == .result, let result = model.result {
                Button(String(
                    format: L10n.t("typingtest.use", locale: locale),
                    result.roundedWPM
                )) {
                    model.applyResult()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!model.canApplyResult)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private var languageBinding: Binding<TypingTestLanguage> {
        Binding(get: { model.language }, set: { model.setLanguage($0) })
    }

    private var levelBinding: Binding<TypingTestLevel> {
        Binding(get: { model.level }, set: { model.setLevel($0) })
    }

    private func languageTitle(_ language: TypingTestLanguage) -> String {
        switch language {
        case .russian: return L10n.t("typingtest.language.ru", locale: locale)
        case .english: return L10n.t("typingtest.language.en", locale: locale)
        }
    }

    private func levelTitle(_ level: TypingTestLevel) -> String {
        switch level {
        case .easy: return L10n.t("typingtest.level.easy", locale: locale)
        case .medium: return L10n.t("typingtest.level.medium", locale: locale)
        case .advanced: return L10n.t("typingtest.level.advanced", locale: locale)
        }
    }

    private func resultDetails(_ result: TypingTestResult) -> String {
        String(
            format: L10n.t("typingtest.result.details", locale: locale),
            result.roundedCPM,
            Int(result.accuracyPercent.rounded()),
            languageTitle(result.language),
            levelTitle(result.level)
        )
    }
}
