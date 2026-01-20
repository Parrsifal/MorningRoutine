import SwiftUI

// ============================================================================
// MARK: - ROOT VIEW
// ============================================================================
// This view handles navigation between app states.
// Routes to LoadingView, NoInternetView, PushPermissionView, WebView, or Native.
// ============================================================================

struct RootView: View {
    @StateObject private var appStateManager = AppStateManager.shared
    @EnvironmentObject var storage: LocalStorage

    var body: some View {
        Group {
            switch appStateManager.currentState {
            case .loading:
                LoadingView()

            case .noInternet:
                NoInternetView {
                    await appStateManager.retryConnection()
                }

            case .pushPermission:
                PushPermissionView(
                    onAccept: {
                        await appStateManager.onPushPermissionAccepted()
                    },
                    onSkip: {
                        await appStateManager.onPushPermissionSkipped()
                    }
                )

            case .webView(let url):
                FullscreenWebView(urlString: url)

            case .native:
                ContentView()
                    .environmentObject(storage)
            }
        }
        .task {
            await appStateManager.initializeApp()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(LocalStorage())
}
