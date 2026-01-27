import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var storage: LocalStorage
    @Environment(\.dismiss) var dismiss

    @State private var showingResetConfirm = false
    @State private var showingResetStatsConfirm = false

    var body: some View {
        NavigationContainer(
            title: "Settings",
            showSettings: false,
            leadingButton: {
                AnyView(
                    BackButton { dismiss() }
                )
            }
        ) {
            ScrollView {
                VStack(spacing: Theme.paddingLarge) {
                    // Data Section
                    settingsSection(title: "Data") {
                        SettingsButton(
                            title: "Reset Statistics",
                            subtitle: "Clear all routine statistics",
                            icon: "chart.bar.xaxis",
                            color: .orange
                        ) {
                            showingResetStatsConfirm = true
                        }

                        SettingsButton(
                            title: "Reset All Data",
                            subtitle: "Delete all routines and statistics",
                            icon: "trash",
                            color: Theme.destructive
                        ) {
                            showingResetConfirm = true
                        }
                    }

                    // About Section
                    settingsSection(title: "About") {
                        SettingsInfoRow(
                            title: "Version",
                            value: appVersion
                        )

                        SettingsInfoRow(
                            title: "Build",
                            value: buildNumber
                        )

                        if let url = URL(string: AppConfiguration.URLs.privacyPolicy) {
                            Link(destination: url) {
                                HStack(spacing: Theme.paddingMedium) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Theme.accent.opacity(0.15))
                                            .frame(width: 36, height: 36)

                                        Image(systemName: "hand.raised.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Theme.accent)
                                    }

                                    Text("Privacy Policy")
                                        .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                                        .foregroundColor(Theme.text)

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.secondaryText)
                                }
                                .padding(Theme.paddingMedium)
                            }
                        }
                    }

                    // Footer
                    VStack(spacing: Theme.paddingSmall) {
                        Image(systemName: "sun.horizon.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.sunriseGradient)

                        Text("MorningRoutine")
                            .font(.system(size: Theme.fontSizeMedium, weight: .semibold))
                            .foregroundColor(Theme.text)

                        Text("Start your day right")
                            .font(.system(size: Theme.fontSizeSmall))
                            .foregroundColor(Theme.secondaryText)
                    }
                    .padding(.top, Theme.paddingLarge)
                }
                .padding(Theme.paddingMedium)
            }
        }
        .alert("Reset Statistics?", isPresented: $showingResetStatsConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                storage.resetStatistics()
            }
        } message: {
            Text("This will clear all statistics for all routines. Your routines will not be deleted.")
        }
        .alert("Reset All Data?", isPresented: $showingResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                storage.resetAllData()
                dismiss()
            }
        } message: {
            Text("This will delete all your routines and statistics. This action cannot be undone.")
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text(title)
                .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                .foregroundColor(Theme.secondaryText)

            VStack(spacing: 0) {
                content()
            }
            .background(Theme.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
        }
    }

    // MARK: - App Info

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Settings Button
struct SettingsButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.paddingMedium) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: Theme.fontSizeMedium, weight: .medium))
                        .foregroundColor(Theme.text)

                    Text(subtitle)
                        .font(.system(size: Theme.fontSizeSmall))
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryText)
            }
            .padding(Theme.paddingMedium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: Theme.fontSizeMedium))
                .foregroundColor(Theme.text)

            Spacer()

            Text(value)
                .font(.system(size: Theme.fontSizeMedium))
                .foregroundColor(Theme.secondaryText)
        }
        .padding(Theme.paddingMedium)
    }
}

#Preview {
    SettingsView()
        .environmentObject(LocalStorage())
}
