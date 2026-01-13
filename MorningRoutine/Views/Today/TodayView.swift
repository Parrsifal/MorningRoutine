import SwiftUI

struct TodayView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingSettings = false
    @State private var routineToStart: Routine?

    var body: some View {
        NavigationContainer(
            title: "Today",
            showSettings: true,
            onSettingsTap: { showingSettings = true }
        ) {
            ScrollView {
                VStack(spacing: Theme.paddingLarge) {
                    // Greeting Section
                    greetingSection

                    // Streak Card
                    streakCard

                    // Today's Status
                    todayStatusCard

                    // Quick Start Section
                    if !storage.routines.isEmpty {
                        quickStartSection
                    }

                    // Week Progress
                    weekProgressSection
                }
                .padding(Theme.paddingMedium)
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $routineToStart) { routine in
            TimerView(routine: routine)
        }
    }

    // MARK: - Greeting Section
    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: Theme.fontSizeHeader, weight: .bold))
                    .foregroundColor(Theme.text)

                Text(formattedDate)
                    .font(.system(size: Theme.fontSizeMedium))
                    .foregroundColor(Theme.secondaryText)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.secondary)
                    .frame(width: 56, height: 56)

                Image(systemName: greetingIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.sunriseGradient)
            }
        }
    }

    // MARK: - Streak Card
    private var streakCard: some View {
        HStack(spacing: Theme.paddingMedium) {
            // Flame Icon
            ZStack {
                Circle()
                    .fill(storage.currentStreak > 0 ? Color.orange.opacity(0.15) : Theme.secondary)
                    .frame(width: 60, height: 60)

                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundColor(storage.currentStreak > 0 ? .orange : Theme.secondaryText)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(storage.currentStreak)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(storage.currentStreak > 0 ? Theme.primary : Theme.secondaryText)
                +
                Text(" day streak")
                    .font(.system(size: Theme.fontSizeLarge, weight: .medium))
                    .foregroundColor(Theme.secondaryText)

                Text(streakMessage)
                    .font(.system(size: Theme.fontSizeSmall))
                    .foregroundColor(Theme.secondaryText)
            }

            Spacer()
        }
        .padding(Theme.paddingMedium)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }

    // MARK: - Today Status Card
    private var todayStatusCard: some View {
        VStack(spacing: Theme.paddingMedium) {
            HStack {
                Image(systemName: storage.completedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(storage.completedToday ? .green : Theme.secondaryText)

                Text(storage.completedToday ? "Completed today!" : "Not completed yet")
                    .font(.system(size: Theme.fontSizeLarge, weight: .medium))
                    .foregroundColor(storage.completedToday ? .green : Theme.text)

                Spacer()
            }

            if !storage.todayCompletions.isEmpty {
                VStack(spacing: Theme.paddingSmall) {
                    ForEach(storage.todayCompletions, id: \.date) { record in
                        HStack {
                            Text(record.routineName)
                                .font(.system(size: Theme.fontSizeMedium))
                                .foregroundColor(Theme.text)

                            Spacer()

                            Text(formatTime(record.timeSpentSeconds))
                                .font(.system(size: Theme.fontSizeSmall))
                                .foregroundColor(Theme.secondaryText)
                        }
                    }
                }
                .padding(.top, Theme.paddingSmall)
            }
        }
        .padding(Theme.paddingMedium)
        .background(storage.completedToday ? Color.green.opacity(0.1) : Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }

    // MARK: - Quick Start Section
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Quick Start")
                .font(.system(size: Theme.fontSizeMedium, weight: .semibold))
                .foregroundColor(Theme.secondaryText)

            VStack(spacing: Theme.paddingSmall) {
                ForEach(storage.routines.prefix(3)) { routine in
                    QuickStartCard(routine: routine) {
                        routineToStart = routine
                    }
                }

                if storage.routines.count > 3 {
                    Button {
                        storage.selectedTab = .routines
                    } label: {
                        HStack {
                            Text("See all routines")
                                .font(.system(size: Theme.fontSizeMedium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Theme.primary)
                    }
                    .padding(.top, Theme.paddingSmall)
                }
            }
        }
    }

    // MARK: - Week Progress Section
    private var weekProgressSection: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("This Week")
                .font(.system(size: Theme.fontSizeMedium, weight: .semibold))
                .foregroundColor(Theme.secondaryText)

            HStack(spacing: Theme.paddingMedium) {
                WeekStatItem(
                    value: "\(storage.thisWeekCompletions)",
                    label: "Completions",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                WeekStatItem(
                    value: "\(storage.routines.count)",
                    label: "Routines",
                    icon: "sun.horizon.fill",
                    color: Theme.primary
                )
            }
        }
    }

    // MARK: - Helper Properties

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "sun.horizon.fill"
        case 12..<17:
            return "sun.max.fill"
        case 17..<21:
            return "sunset.fill"
        default:
            return "moon.stars.fill"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private var streakMessage: String {
        if storage.currentStreak == 0 {
            return "Start a routine to begin your streak!"
        } else if storage.currentStreak == 1 {
            return "Great start! Keep it going tomorrow."
        } else if storage.currentStreak < 7 {
            return "You're building momentum!"
        } else if storage.currentStreak < 30 {
            return "Amazing consistency!"
        } else {
            return "You're unstoppable!"
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }
}

// MARK: - Quick Start Card
struct QuickStartCard: View {
    let routine: Routine
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.paddingMedium) {
                ZStack {
                    Circle()
                        .fill(Theme.secondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name)
                        .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                        .foregroundColor(Theme.text)

                    Text("\(routine.steps.count) steps • \(routine.formattedEstimatedTime)")
                        .font(.system(size: Theme.fontSizeSmall))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

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

// MARK: - Week Stat Item
struct WeekStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: Theme.paddingSmall) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: Theme.fontSizeTitle, weight: .bold))
                    .foregroundColor(Theme.text)

                Text(label)
                    .font(.system(size: Theme.fontSizeSmall))
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.paddingMedium)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

#Preview {
    TodayView()
        .environmentObject(LocalStorage())
}
