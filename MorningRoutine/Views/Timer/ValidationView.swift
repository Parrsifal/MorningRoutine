import SwiftUI

struct ValidationView: View {
    @EnvironmentObject var storage: LocalStorage
    @Environment(\.dismiss) var dismiss

    let routine: Routine
    let elapsedSeconds: Int

    @State private var completedStepIds: Set<UUID> = []

    private var allStepsCompleted: Bool {
        completedStepIds.count == routine.steps.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Theme.paddingSmall) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.sunriseGradient)

                Text("Great Job!")
                    .font(.system(size: Theme.fontSizeHeader, weight: .bold))
                    .foregroundColor(Theme.text)

                Text("You completed your routine in \(formattedTime)")
                    .font(.system(size: Theme.fontSizeMedium))
                    .foregroundColor(Theme.secondaryText)
            }
            .padding(.top, Theme.paddingLarge)
            .padding(.bottom, Theme.paddingLarge)

            // Steps Validation
            VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                HStack {
                    Text("Mark completed steps")
                        .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                        .foregroundColor(Theme.secondaryText)

                    Spacer()

                    Button(allStepsCompleted ? "Uncheck All" : "Check All") {
                        if allStepsCompleted {
                            completedStepIds.removeAll()
                        } else {
                            completedStepIds = Set(routine.steps.map { $0.id })
                        }
                    }
                    .font(.system(size: Theme.fontSizeSmall, weight: .medium))
                    .foregroundColor(Theme.primary)
                }
                .padding(.horizontal, Theme.paddingMedium)

                ScrollView {
                    VStack(spacing: Theme.paddingSmall) {
                        ForEach(Array(routine.steps.enumerated()), id: \.element.id) { index, step in
                            ValidationStepRow(
                                step: step,
                                index: index + 1,
                                isCompleted: completedStepIds.contains(step.id)
                            ) {
                                if completedStepIds.contains(step.id) {
                                    completedStepIds.remove(step.id)
                                } else {
                                    completedStepIds.insert(step.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.paddingMedium)
                }
            }

            Spacer()

            // Summary
            VStack(spacing: Theme.paddingSmall) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Time Spent")
                            .font(.system(size: Theme.fontSizeSmall))
                            .foregroundColor(Theme.secondaryText)
                        Text(formattedTime)
                            .font(.system(size: Theme.fontSizeLarge, weight: .semibold))
                            .foregroundColor(Theme.text)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Steps Completed")
                            .font(.system(size: Theme.fontSizeSmall))
                            .foregroundColor(Theme.secondaryText)
                        Text("\(completedStepIds.count)/\(routine.steps.count)")
                            .font(.system(size: Theme.fontSizeLarge, weight: .semibold))
                            .foregroundColor(Theme.primary)
                    }
                }
                .padding(Theme.paddingMedium)
                .background(Theme.secondaryBackground)
                .cornerRadius(Theme.cornerRadiusMedium)
            }
            .padding(.horizontal, Theme.paddingMedium)

            // Save Button
            VStack {
                Button("Save & Finish") {
                    storage.completeSession(completedStepIds: Array(completedStepIds))
                    // Dismiss both ValidationView and TimerView
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(name: .dismissTimer, object: nil)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Theme.paddingMedium)
            .padding(.bottom, Theme.paddingSmall)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            // Pre-select all steps by default
            completedStepIds = Set(routine.steps.map { $0.id })
        }
    }

    private var formattedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

// MARK: - Validation Step Row
struct ValidationStepRow: View {
    let step: Step
    let index: Int
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.paddingMedium) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Theme.primary : Theme.secondaryText.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isCompleted {
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(step.name)
                        .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                        .foregroundColor(isCompleted ? Theme.text : Theme.secondaryText)

                    Text("\(step.durationMinutes) min")
                        .font(.system(size: Theme.fontSizeSmall))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()
            }
            .padding(Theme.paddingMedium)
            .background(isCompleted ? Theme.secondary : Theme.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusSmall)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let dismissTimer = Notification.Name("dismissTimer")
}

#Preview {
    ValidationView(
        routine: Routine(name: "Morning Routine", steps: [
            Step(name: "Meditation", durationMinutes: 10),
            Step(name: "Exercise", durationMinutes: 20)
        ]),
        elapsedSeconds: 1850
    )
    .environmentObject(LocalStorage())
}
