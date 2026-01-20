import SwiftUI

// ============================================================================
// MARK: - NO INTERNET VIEW
// ============================================================================
// Displays when there's no internet connection.
// Adapted for MorningRoutine's orange theme.
// ============================================================================

struct NoInternetView: View {
    var onRetry: () async -> Void

    @State private var isRetrying = false

    var body: some View {
        ZStack {
            // Background
            Theme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // No internet icon
                Image(systemName: "wifi.slash")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.primaryColor)

                // Text
                VStack(spacing: 8) {
                    Text("No Internet Connection")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.textPrimary)

                    Text("Please check your connection and try again")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Retry button
                Button {
                    Task {
                        isRetrying = true
                        await onRetry()
                        isRetrying = false
                    }
                } label: {
                    HStack {
                        if isRetrying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isRetrying ? "Connecting..." : "Try Again")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isRetrying)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    NoInternetView {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}
