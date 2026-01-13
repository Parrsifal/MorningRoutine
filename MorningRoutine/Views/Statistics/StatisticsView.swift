import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingSettings = false
    @State private var selectedRoutine: Routine?

    var body: some View {
        NavigationContainer(
            title: "Statistics",
            showSettings: true,
            onSettingsTap: { showingSettings = true }
        ) {
            ScrollView {
                VStack(spacing: Theme.paddingLarge) {
                    // Overall Statistics
                    overallStatisticsSection

                    // Per-Routine Statistics
                    if !storage.routines.isEmpty {
                        routineStatisticsSection
                    }
                }
                .padding(Theme.paddingMedium)
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $selectedRoutine) { routine in
            RoutineStatisticsDetailView(routine: routine)
        }
    }

    // MARK: - Overall Statistics Section
    private var overallStatisticsSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Text("Overview")
                .font(.system(size: Theme.fontSizeMedium, weight: .semibold))
                .foregroundColor(Theme.secondaryText)

            VStack(spacing: Theme.paddingMedium) {
                HStack(spacing: Theme.paddingMedium) {
                    StatCard(
                        title: "Total Routines",
                        value: "\(storage.routines.count)",
                        icon: "sun.horizon.fill",
                        color: Theme.primary
                    )

                    StatCard(
                        title: "Times Started",
                        value: "\(storage.totalStatistics.selected)",
                        icon: "play.fill",
                        color: .blue
                    )
                }

                HStack(spacing: Theme.paddingMedium) {
                    StatCard(
                        title: "Completed",
                        value: "\(storage.totalStatistics.completed)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    StatCard(
                        title: "Total Time",
                        value: formatTotalTime(storage.totalStatistics.timeSpent),
                        icon: "clock.fill",
                        color: .purple
                    )
                }
            }
        }
    }

    // MARK: - Routine Statistics Section
    private var routineStatisticsSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Text("By Routine")
                .font(.system(size: Theme.fontSizeMedium, weight: .semibold))
                .foregroundColor(Theme.secondaryText)

            VStack(spacing: Theme.paddingSmall) {
                ForEach(storage.routines.sorted(by: { $0.statistics.timesCompleted > $1.statistics.timesCompleted })) { routine in
                    RoutineStatRow(routine: routine) {
                        selectedRoutine = routine
                    }
                }
            }
        }
    }

    // MARK: - Helper
    private func formatTotalTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else if seconds > 0 {
            return "\(seconds)s"
        } else {
            return "0m"
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: Theme.fontSizeTitle, weight: .bold))
                .foregroundColor(Theme.text)

            Text(title)
                .font(.system(size: Theme.fontSizeSmall))
                .foregroundColor(Theme.secondaryText)
        }
        .padding(Theme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

// MARK: - Routine Stat Row
struct RoutineStatRow: View {
    let routine: Routine
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.paddingMedium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.secondary)
                        .frame(width: 40, height: 40)

                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.primary)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name)
                        .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                        .foregroundColor(Theme.text)

                    Text("\(routine.steps.count) steps")
                        .font(.system(size: Theme.fontSizeSmall))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                // Stats
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(routine.statistics.timesCompleted)")
                        .font(.system(size: Theme.fontSizeLarge, weight: .semibold))
                        .foregroundColor(Theme.primary)

                    Text("completed")
                        .font(.system(size: Theme.fontSizeSmall))
                        .foregroundColor(Theme.secondaryText)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryText)
            }
            .padding(Theme.paddingMedium)
            .background(Theme.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Routine Statistics Detail View
struct RoutineStatisticsDetailView: View {
    @Environment(\.dismiss) var dismiss

    let routine: Routine

    var body: some View {
        NavigationContainer(
            title: routine.name,
            showSettings: false,
            leadingButton: {
                AnyView(
                    BackButton { dismiss() }
                )
            }
        ) {
            ScrollView {
                VStack(spacing: Theme.paddingLarge) {
                    // Main Stats
                    VStack(spacing: Theme.paddingMedium) {
                        HStack(spacing: Theme.paddingMedium) {
                            DetailStatCard(
                                title: "Times Selected",
                                value: "\(routine.statistics.timesSelected)",
                                icon: "hand.tap.fill"
                            )

                            DetailStatCard(
                                title: "Times Completed",
                                value: "\(routine.statistics.timesCompleted)",
                                icon: "checkmark.circle.fill"
                            )
                        }

                        HStack(spacing: Theme.paddingMedium) {
                            DetailStatCard(
                                title: "Total Time",
                                value: routine.statistics.formattedTotalTime,
                                icon: "clock.fill"
                            )

                            DetailStatCard(
                                title: "Average Time",
                                value: routine.statistics.formattedAverageTime,
                                icon: "chart.line.uptrend.xyaxis"
                            )
                        }
                    }

                    // Completion Rate
                    if routine.statistics.timesSelected > 0 {
                        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                            Text("Completion Rate")
                                .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                                .foregroundColor(Theme.secondaryText)

                            let rate = Double(routine.statistics.timesCompleted) / Double(routine.statistics.timesSelected)

                            VStack(spacing: Theme.paddingSmall) {
                                HStack {
                                    Text("\(Int(rate * 100))%")
                                        .font(.system(size: Theme.fontSizeHeader, weight: .bold))
                                        .foregroundColor(Theme.primary)

                                    Spacer()
                                }

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Theme.secondary)
                                            .frame(height: 8)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Theme.primary)
                                            .frame(width: geometry.size.width * rate, height: 8)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding(Theme.paddingMedium)
                            .background(Theme.secondaryBackground)
                            .cornerRadius(Theme.cornerRadiusMedium)
                        }
                    }

                    // Steps Info
                    VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                        Text("Steps (\(routine.steps.count))")
                            .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                            .foregroundColor(Theme.secondaryText)

                        VStack(spacing: 0) {
                            ForEach(Array(routine.steps.enumerated()), id: \.element.id) { index, step in
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.system(size: Theme.fontSizeSmall, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(Theme.primary)
                                        .clipShape(Circle())

                                    Text(step.name)
                                        .font(.system(size: Theme.fontSizeMedium))
                                        .foregroundColor(Theme.text)

                                    Spacer()

                                    Text("\(step.durationMinutes) min")
                                        .font(.system(size: Theme.fontSizeSmall))
                                        .foregroundColor(Theme.secondaryText)
                                }
                                .padding(.vertical, Theme.paddingSmall)

                                if index < routine.steps.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .padding(Theme.paddingMedium)
                        .background(Theme.secondaryBackground)
                        .cornerRadius(Theme.cornerRadiusMedium)
                    }
                }
                .padding(Theme.paddingMedium)
            }
        }
    }
}

// MARK: - Detail Stat Card
struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: Theme.paddingSmall) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Theme.primary)

            Text(value)
                .font(.system(size: Theme.fontSizeTitle, weight: .bold))
                .foregroundColor(Theme.text)

            Text(title)
                .font(.system(size: Theme.fontSizeSmall))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.paddingMedium)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

#Preview {
    StatisticsView()
        .environmentObject(LocalStorage())
}
