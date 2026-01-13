import SwiftUI

struct RoutinesListView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingCreateRoutine = false
    @State private var showingSettings = false
    @State private var routineToEdit: Routine?
    @State private var routineToStart: Routine?

    var body: some View {
        NavigationContainer(
            title: "Routines",
            showSettings: true,
            onSettingsTap: { showingSettings = true }
        ) {
            ZStack {
                if storage.routines.isEmpty {
                    EmptyRoutinesView {
                        showingCreateRoutine = true
                    }
                } else {
                    routinesList
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        AddButton {
                            showingCreateRoutine = true
                        }
                        .padding(.trailing, Theme.paddingLarge)
                        .padding(.bottom, Theme.paddingMedium)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCreateRoutine) {
            CreateEditRoutineView(routine: nil)
        }
        .fullScreenCover(item: $routineToEdit) { routine in
            CreateEditRoutineView(routine: routine)
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $routineToStart) { routine in
            TimerView(routine: routine)
        }
    }

    private var routinesList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.paddingMedium) {
                ForEach(storage.routines) { routine in
                    RoutineCard(
                        routine: routine,
                        onTap: {
                            routineToStart = routine
                        },
                        onEdit: {
                            routineToEdit = routine
                        },
                        onDelete: {
                            withAnimation {
                                storage.deleteRoutine(id: routine.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, Theme.paddingMedium)
            .padding(.top, Theme.paddingSmall)
            .padding(.bottom, 80)
        }
    }
}

// MARK: - Empty State
struct EmptyRoutinesView: View {
    let onCreateTap: () -> Void

    var body: some View {
        VStack(spacing: Theme.paddingLarge) {
            ZStack {
                Circle()
                    .fill(Theme.secondary)
                    .frame(width: 100, height: 100)

                Image(systemName: "sun.horizon")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.primary)
            }

            Text("No Routines Yet")
                .font(.system(size: Theme.fontSizeTitle, weight: .semibold))
                .foregroundColor(Theme.text)

            Text("Create your first morning routine\nto get started")
                .font(.system(size: Theme.fontSizeMedium))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)

            Button("Create Routine") {
                onCreateTap()
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 200)
        }
        .padding(Theme.paddingLarge)
    }
}

// MARK: - Routine Card
struct RoutineCard: View {
    let routine: Routine
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingActions = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.paddingSmall) {
                HStack {
                    Text(routine.name)
                        .font(.system(size: Theme.fontSizeLarge, weight: .semibold))
                        .foregroundColor(Theme.text)

                    Spacer()

                    Menu {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.secondaryText)
                            .frame(width: 32, height: 32)
                    }
                }

                HStack(spacing: Theme.paddingMedium) {
                    Label("\(routine.steps.count) steps", systemImage: "list.bullet")
                        .font(.system(size: Theme.fontSizeSmall))
                        .foregroundColor(Theme.secondaryText)

                    Label(routine.formattedEstimatedTime, systemImage: "clock")
                        .font(.system(size: Theme.fontSizeSmall))
                        .foregroundColor(Theme.secondaryText)
                }

                if routine.statistics.timesCompleted > 0 {
                    HStack(spacing: Theme.paddingSmall) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.primary)

                        Text("Completed \(routine.statistics.timesCompleted) times")
                            .font(.system(size: Theme.fontSizeSmall))
                            .foregroundColor(Theme.primary)
                    }
                }
            }
            .padding(Theme.paddingMedium)
            .background(Theme.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Button
struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Theme.primary)
                .clipShape(Circle())
                .shadow(color: Theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    RoutinesListView()
        .environmentObject(LocalStorage())
}
