import SwiftUI

struct CreateEditRoutineView: View {
    @EnvironmentObject var storage: LocalStorage
    @Environment(\.dismiss) var dismiss

    let routine: Routine?

    @State private var name: String = ""
    @State private var steps: [Step] = []
    @State private var showingAddStep = false

    private var isEditing: Bool {
        routine != nil
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !steps.isEmpty
    }

    init(routine: Routine?) {
        self.routine = routine
        if let routine = routine {
            _name = State(initialValue: routine.name)
            _steps = State(initialValue: routine.steps)
        }
    }

    var body: some View {
        NavigationContainer(
            title: isEditing ? "Edit Routine" : "New Routine",
            showSettings: false,
            leadingButton: {
                AnyView(
                    BackButton { dismiss() }
                )
            }
        ) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.paddingLarge) {
                        // Name Field
                        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                            Text("Routine Name")
                                .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                                .foregroundColor(Theme.secondaryText)

                            TextField("e.g., Morning Energizer", text: $name)
                                .font(.system(size: Theme.fontSizeLarge))
                                .padding(Theme.paddingMedium)
                                .background(Theme.secondaryBackground)
                                .cornerRadius(Theme.cornerRadiusSmall)
                        }

                        // Steps Section
                        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                            HStack {
                                Text("Steps")
                                    .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                                    .foregroundColor(Theme.secondaryText)

                                Spacer()

                                if !steps.isEmpty {
                                    Text("\(totalMinutes) min total")
                                        .font(.system(size: Theme.fontSizeSmall))
                                        .foregroundColor(Theme.primary)
                                }
                            }

                            if steps.isEmpty {
                                EmptyStepsView {
                                    showingAddStep = true
                                }
                            } else {
                                stepsList
                            }

                            Button {
                                showingAddStep = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Step")
                                }
                                .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                                .foregroundColor(Theme.primary)
                            }
                            .padding(.top, Theme.paddingSmall)
                        }
                    }
                    .padding(Theme.paddingMedium)
                }

                // Save Button
                VStack {
                    Button(isEditing ? "Save Changes" : "Create Routine") {
                        saveRoutine()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.5)
                }
                .padding(Theme.paddingMedium)
                .background(Theme.background)
            }
        }
        .fullScreenCover(isPresented: $showingAddStep) {
            AddStepView { step in
                steps.append(step)
            }
        }
    }

    private var stepsList: some View {
        VStack(spacing: Theme.paddingSmall) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                StepRow(
                    step: step,
                    index: index + 1,
                    onEdit: {
                        // Edit functionality can be added here
                    },
                    onDelete: {
                        withAnimation {
                            steps.removeAll { $0.id == step.id }
                        }
                    }
                )
            }
            .onMove { from, to in
                steps.move(fromOffsets: from, toOffset: to)
            }
        }
    }

    private var totalMinutes: Int {
        steps.reduce(0) { $0 + $1.durationMinutes }
    }

    private func saveRoutine() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingRoutine = routine {
            var updatedRoutine = existingRoutine
            updatedRoutine.name = trimmedName
            updatedRoutine.steps = steps
            storage.updateRoutine(updatedRoutine)
        } else {
            storage.createRoutine(name: trimmedName, steps: steps)
        }

        dismiss()
    }
}

// MARK: - Empty Steps View
struct EmptyStepsView: View {
    let onAddTap: () -> Void

    var body: some View {
        VStack(spacing: Theme.paddingMedium) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 32))
                .foregroundColor(Theme.secondaryText)

            Text("No steps added yet")
                .font(.system(size: Theme.fontSizeMedium))
                .foregroundColor(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.paddingLarge)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

// MARK: - Step Row
struct StepRow: View {
    let step: Step
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Theme.paddingMedium) {
            // Index
            Text("\(index)")
                .font(.system(size: Theme.fontSizeSmall, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Theme.primary)
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(step.name)
                    .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                    .foregroundColor(Theme.text)

                Text("\(step.durationMinutes) min")
                    .font(.system(size: Theme.fontSizeSmall))
                    .foregroundColor(Theme.secondaryText)
            }

            Spacer()

            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusSmall)
    }
}

// MARK: - Add Step View
struct AddStepView: View {
    @Environment(\.dismiss) var dismiss

    let onAdd: (Step) -> Void

    @State private var name: String = ""
    @State private var durationMinutes: Int = 5

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationContainer(
            title: "Add Step",
            showSettings: false,
            leadingButton: {
                AnyView(
                    BackButton { dismiss() }
                )
            }
        ) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.paddingLarge) {
                        // Name Field
                        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                            Text("Step Name")
                                .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                                .foregroundColor(Theme.secondaryText)

                            TextField("e.g., Meditation", text: $name)
                                .font(.system(size: Theme.fontSizeLarge))
                                .padding(Theme.paddingMedium)
                                .background(Theme.secondaryBackground)
                                .cornerRadius(Theme.cornerRadiusSmall)
                        }

                        // Duration Picker
                        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                            Text("Duration")
                                .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                                .foregroundColor(Theme.secondaryText)

                            HStack(spacing: Theme.paddingMedium) {
                                Button {
                                    if durationMinutes > 1 {
                                        durationMinutes -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Theme.primary)
                                }

                                Text("\(durationMinutes) min")
                                    .font(.system(size: Theme.fontSizeTitle, weight: .semibold))
                                    .foregroundColor(Theme.text)
                                    .frame(width: 80)

                                Button {
                                    if durationMinutes < 120 {
                                        durationMinutes += 1
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Theme.primary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(Theme.paddingMedium)
                            .background(Theme.secondaryBackground)
                            .cornerRadius(Theme.cornerRadiusSmall)
                        }

                        // Quick Duration Buttons
                        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                            Text("Quick Select")
                                .font(.system(size: Theme.fontSizeSmall))
                                .foregroundColor(Theme.secondaryText)

                            HStack(spacing: Theme.paddingSmall) {
                                ForEach([1, 5, 10, 15, 30], id: \.self) { minutes in
                                    Button {
                                        durationMinutes = minutes
                                    } label: {
                                        Text("\(minutes)m")
                                            .font(.system(size: Theme.fontSizeSmall, weight: .medium))
                                            .foregroundColor(durationMinutes == minutes ? .white : Theme.primary)
                                            .padding(.horizontal, Theme.paddingSmall)
                                            .padding(.vertical, 6)
                                            .background(durationMinutes == minutes ? Theme.primary : Theme.secondary)
                                            .cornerRadius(Theme.cornerRadiusSmall)
                                    }
                                }
                            }
                        }
                    }
                    .padding(Theme.paddingMedium)
                }

                // Add Button
                VStack {
                    Button("Add Step") {
                        let step = Step(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            durationMinutes: durationMinutes
                        )
                        onAdd(step)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.5)
                }
                .padding(Theme.paddingMedium)
                .background(Theme.background)
            }
        }
    }
}

#Preview {
    CreateEditRoutineView(routine: nil)
        .environmentObject(LocalStorage())
}
