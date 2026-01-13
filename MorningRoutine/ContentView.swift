import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var storage: LocalStorage

    var body: some View {
        Group {
            if storage.hasCompletedOnboarding {
                MainView()
            } else {
                OnboardingView()
            }
        }
    }
}

// MARK: - Main View with Tab Bar
struct MainView: View {
    @EnvironmentObject var storage: LocalStorage

    var body: some View {
        VStack(spacing: 0) {
            // Content based on selected tab
            Group {
                switch storage.selectedTab {
                case .today:
                    TodayView()
                case .routines:
                    RoutinesListView()
                case .statistics:
                    StatisticsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $storage.selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalStorage())
}
