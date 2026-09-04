import SwiftUI

struct StatisticsSettingsPane: View {
    @ObservedObject var appState: AppState
    @ObservedObject var usageStats: UsageStatsStore
    @State private var selectedMonth: Date = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: Date())
    ) ?? Date()

    private var locale: Locale { appState.effectiveLocale }
    private var calendar: Calendar { Calendar.current }

    private var monthStarts: [Date] {
        usageStats.selectableMonthStarts()
    }

    private var selectedMonthStart: Date {
        UsageStatsStore.startOfMonth(for: selectedMonth, calendar: calendar) ?? selectedMonth
    }

    private var monthTotals: UsageStatsStore.MonthTotals {
        usageStats.totals(forMonthContaining: selectedMonthStart)
    }

    private var estimate: UsageStatsEstimate.Result {
        UsageStatsEstimate.estimate(
            characters: monthTotals.characters,
            recordingMilliseconds: monthTotals.recordingMilliseconds,
            wordsPerMinute: appState.typingSpeedWPM
        )
    }

    private var transformTotals: [UsageStatsStore.TransformMonthTotal] {
        usageStats.transformTotals(forMonthContaining: selectedMonthStart)
    }

    private var previousMonth: Date? {
        monthStarts.filter { $0 < selectedMonthStart }.max()
    }

    private var nextMonth: Date? {
        monthStarts.filter { $0 > selectedMonthStart }.min()
    }

    var body: some View {
        Form {
            Section {
                Toggle(
                    L10n.t("stats.collection", locale: locale),
                    isOn: $appState.statsCollectionEnabled
                )
            } header: {
                Text(L10n.t("stats.section.collection", locale: locale))
            } footer: {
                Text(L10n.t("stats.collection_footer", locale: locale))
            }

            Section {
                monthStepper

                if monthTotals.isEmpty {
                    Text(dictationEmptyMessage)
                        .foregroundStyle(.secondary)
                } else {
                    estimateRow(
                        titleKey: "stats.would_have_typed",
                        seconds: estimate.typingSeconds
                    )
                    estimateRow(
                        titleKey: "stats.saved",
                        seconds: estimate.savedSeconds
                    )
                    HStack(alignment: .top, spacing: 16) {
                        countRow(titleKey: "stats.characters", value: monthTotals.characters)
                        countRow(titleKey: "stats.sessions", value: monthTotals.sessions)
                    }
                }
            } header: {
                Text(L10n.t("stats.section.period", locale: locale))
            } footer: {
                Text(L10n.t("stats.estimate_footer", locale: locale))
            }

            Section {
                Stepper(value: $appState.typingSpeedWPM, in: UsageStatsEstimate.minimumWPM...UsageStatsEstimate.maximumWPM) {
                    LabeledContent(L10n.t("stats.typing_speed", locale: locale)) {
                        HStack(spacing: 6) {
                            Text("\(appState.typingSpeedWPM)")
                                .monospacedDigit()
                            Text(L10n.t("stats.wpm_suffix", locale: locale))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text(L10n.t("stats.section.speed", locale: locale))
            } footer: {
                Text(L10n.t("stats.wpm_footer", locale: locale))
            }

            Section {
                if transformTotals.isEmpty {
                    Text(L10n.t("stats.transform.empty", locale: locale))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(transformTotals) { row in
                        transformRow(row)
                    }
                }
            } header: {
                Text(L10n.t("stats.section.bindings", locale: locale))
            } footer: {
                Text(L10n.t("stats.bindings_footer", locale: locale))
            }

            Section {
                Button(L10n.t("stats.clear", locale: locale), role: .destructive) {
                    appState.clearUsageStatistics()
                    selectedMonth = UsageStatsStore.startOfMonth(for: Date(), calendar: calendar) ?? Date()
                }
                .disabled(!usageStats.hasAnyData)
            } footer: {
                Text(L10n.t("stats.clear_footer", locale: locale))
            }
        }
        .formStyle(.grouped)
        .onAppear {
            selectedMonth = UsageStatsStore.startOfMonth(for: Date(), calendar: calendar) ?? Date()
        }
        .onChange(of: usageStats.days) { _, _ in
            clampSelectedMonth()
        }
    }

    private var dictationEmptyMessage: String {
        if !appState.statsCollectionEnabled, !usageStats.hasAnyData {
            return L10n.t("stats.collection_off", locale: locale)
        }
        return L10n.t("stats.month_empty", locale: locale)
    }

    private var monthStepper: some View {
        HStack {
            Button {
                if let previousMonth {
                    selectedMonth = previousMonth
                }
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(previousMonth == nil)
            .accessibilityLabel(L10n.t("stats.previous_month", locale: locale))

            Spacer()

            Text(monthTitle(selectedMonthStart))
                .font(.body.weight(.medium))

            Spacer()

            Button {
                if let nextMonth {
                    selectedMonth = nextMonth
                }
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(nextMonth == nil)
            .accessibilityLabel(L10n.t("stats.next_month", locale: locale))
        }
    }

    private func estimateRow(titleKey: String, seconds: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t(titleKey, locale: locale))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(UsageStatsEstimate.durationString(seconds, locale: locale))
                .font(.title2.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func countRow(titleKey: String, value: Int) -> some View {
        let formatted = formattedCount(value)
        return VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t(titleKey, locale: locale))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(formatted)
                .font(.title2.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityLabel(L10n.t(titleKey, locale: locale))
        .accessibilityValue(formatted)
    }

    private func formattedCount(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func transformRow(_ row: UsageStatsStore.TransformMonthTotal) -> some View {
        let label = transformLabel(id: row.id, kind: row.kind)
        return VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(label.title)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text("\(row.count)")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.primary)
            }
            if let subtitle = label.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label.title)
        .accessibilityValue("\(row.count)")
    }

    private func transformLabel(id: UUID, kind: TransformKind) -> (title: String, subtitle: String?) {
        if let binding = appState.transformBindings.first(where: { $0.id == id }) {
            let chord = binding.chord.displayString
            switch binding.kind {
            case .translate:
                let left = TransformLanguageCatalog.shortLabel(code: binding.languageA)
                let right = TransformLanguageCatalog.shortLabel(code: binding.languageB)
                let title = String(
                    format: L10n.t("stats.transform.translate", locale: locale),
                    left,
                    right
                )
                return (title, chord)
            case .custom:
                let trimmed = binding.customInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
                let firstLine = trimmed.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
                let title = firstLine.isEmpty
                    ? L10n.t("stats.transform.custom_untitled", locale: locale)
                    : Self.truncated(firstLine, limit: 42)
                return (title, chord)
            }
        }
        return (
            L10n.t("stats.transform.deleted", locale: locale),
            kind.title(locale: locale)
        )
    }

    private static func truncated(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit - 1)) + "…"
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter.string(from: date)
    }

    private func clampSelectedMonth() {
        let allowed = monthStarts
        if !allowed.contains(selectedMonthStart),
           let current = UsageStatsStore.startOfMonth(for: Date(), calendar: calendar) {
            selectedMonth = current
        }
    }
}
