import SwiftUI

struct TimerView: View {
    @EnvironmentObject var storage: LocalStorage
    @Environment(\.dismiss) var dismiss

    let routine: Routine

    @State private var elapsedSeconds: Int = 0
    @State private var isRunning: Bool = false
    @State private var timer: Timer?
    @State private var showingValidation = false
    @State private var showingCancelConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    if isRunning || elapsedSeconds > 0 {
                        showingCancelConfirm = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                Text(routine.name)
                    .font(.system(size: Theme.fontSizeLarge, weight: .semibold))
                    .foregroundColor(Theme.text)

                Spacer()
            }
            .padding(Theme.paddingMedium)

            // Timer Display
            VStack(spacing: Theme.paddingLarge) {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Theme.secondary, lineWidth: 8)
                        .frame(width: 220, height: 220)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(Theme.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progressValue)

                    // Time display
                    VStack(spacing: 4) {
                        Text(formattedTime)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.text)

                        Text(isRunning ? "In Progress" : (elapsedSeconds > 0 ? "Paused" : "Ready"))
                            .font(.system(size: Theme.fontSizeSmall))
                            .foregroundColor(Theme.secondaryText)
                    }
                }

                // Estimated time
                HStack(spacing: Theme.paddingSmall) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))

                    Text("Estimated: \(routine.formattedEstimatedTime)")
                        .font(.system(size: Theme.fontSizeMedium))
                }
                .foregroundColor(Theme.secondaryText)
            }

            Spacer()

            // Steps Preview
            VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                Text("Steps")
                    .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
                    .padding(.horizontal, Theme.paddingMedium)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.paddingSmall) {
                        ForEach(Array(routine.steps.enumerated()), id: \.element.id) { index, step in
                            StepPreviewChip(step: step, index: index + 1)
                        }
                    }
                    .padding(.horizontal, Theme.paddingMedium)
                }
            }

            Spacer()

            // Control Buttons
            VStack(spacing: Theme.paddingMedium) {
                if isRunning {
                    HStack(spacing: Theme.paddingMedium) {
                        Button("Pause") {
                            pauseTimer()
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button("Finish") {
                            finishTimer()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                } else if elapsedSeconds > 0 {
                    HStack(spacing: Theme.paddingMedium) {
                        Button("Resume") {
                            startTimer()
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button("Finish") {
                            finishTimer()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                } else {
                    Button("Start Timer") {
                        startTimer()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(Theme.paddingMedium)
            .padding(.bottom, Theme.paddingSmall)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            storage.startSession(for: routine.id)
        }
        .onDisappear {
            timer?.invalidate()
        }
        .alert("Cancel Routine?", isPresented: $showingCancelConfirm) {
            Button("Continue", role: .cancel) { }
            Button("Cancel Routine", role: .destructive) {
                storage.cancelSession()
                dismiss()
            }
        } message: {
            Text("Your progress will not be saved.")
        }
        .fullScreenCover(isPresented: $showingValidation) {
            ValidationView(routine: routine, elapsedSeconds: elapsedSeconds)
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissTimer)) { _ in
            dismiss()
        }
    }

    // MARK: - Timer Functions

    private var formattedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private var progressValue: CGFloat {
        let estimatedSeconds = routine.totalEstimatedMinutes * 60
        guard estimatedSeconds > 0 else { return 0 }
        return min(CGFloat(elapsedSeconds) / CGFloat(estimatedSeconds), 1.0)
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func finishTimer() {
        pauseTimer()
        showingValidation = true
    }
}

// MARK: - Step Preview Chip
struct StepPreviewChip: View {
    let step: Step
    let index: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("\(index)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Theme.primary)
                .clipShape(Circle())

            Text(step.name)
                .font(.system(size: Theme.fontSizeSmall))
                .foregroundColor(Theme.text)

            Text("\(step.durationMinutes)m")
                .font(.system(size: Theme.fontSizeSmall))
                .foregroundColor(Theme.secondaryText)
        }
        .padding(.horizontal, Theme.paddingSmall)
        .padding(.vertical, 6)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusSmall)
    }
}

#Preview {
    TimerView(routine: Routine(name: "Morning Routine", steps: [
        Step(name: "Meditation", durationMinutes: 10),
        Step(name: "Exercise", durationMinutes: 20),
        Step(name: "Shower", durationMinutes: 15)
    ]))
    .environmentObject(LocalStorage())
}
