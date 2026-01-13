import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sun.horizon.fill",
            title: "Welcome to\nMorningRoutine",
            description: "Create and track your morning routines to start each day with intention and purpose."
        ),
        OnboardingPage(
            icon: "timer",
            title: "Track Your\nProgress",
            description: "Use the built-in timer to measure how long your routines take. Review statistics to optimize your mornings."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Page Content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 400)

            // Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Theme.primary : Theme.secondaryText.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.top, Theme.paddingLarge)

            Spacer()

            // Buttons
            VStack(spacing: Theme.paddingMedium) {
                if currentPage < pages.count - 1 {
                    Button("Continue") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.system(size: Theme.fontSizeMedium))
                    .foregroundColor(Theme.secondaryText)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(.horizontal, Theme.paddingLarge)
            .padding(.bottom, Theme.paddingLarge)
        }
        .background(Theme.background)
    }

    private func completeOnboarding() {
        withAnimation {
            storage.hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Theme.paddingLarge) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.secondary)
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(Theme.sunriseGradient)
            }

            // Title
            Text(page.title)
                .font(.system(size: Theme.fontSizeHeader, weight: .bold))
                .foregroundColor(Theme.text)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.system(size: Theme.fontSizeLarge))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.paddingLarge)
        }
        .padding(.horizontal, Theme.paddingMedium)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(LocalStorage())
}
