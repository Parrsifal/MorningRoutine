import SwiftUI

// ============================================================================
// MARK: - LOADING VIEW
// ============================================================================
// Displays loading state with animated indicator and progress text.
// Adapted for MorningRoutine's orange theme.
// ============================================================================

struct LoadingView: View {
    @ObservedObject var appStateManager = AppStateManager.shared

    var body: some View {
        ZStack {
            // Background
            Theme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Animated loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.primaryColor))
                    .scaleEffect(2.0)

                // Loading text
                VStack(spacing: 8) {
                    Text(appStateManager.loadingProgress)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    Text("Please wait")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    LoadingView()
}
