import SwiftUI

// MARK: - Custom Navigation Bar
struct CustomNavigationBar: View {
    let title: String
    var showSettings: Bool = true
    var onSettingsTap: (() -> Void)?
    var leadingButton: (() -> AnyView)? = nil

    var body: some View {
        HStack(spacing: Theme.paddingMedium) {
            if let leadingButton = leadingButton {
                leadingButton()
            }

            Text(title)
                .font(.system(size: Theme.fontSizeTitle, weight: .bold))
                .foregroundColor(Theme.text)

            Spacer()

            if showSettings, let onSettingsTap = onSettingsTap {
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.primary)
                }
            }
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, Theme.paddingSmall)
        .background(Theme.background)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    let tabs: [AppTab] = AppTab.allCases

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, Theme.paddingLarge)
        .padding(.top, Theme.paddingSmall)
        .padding(.bottom, Theme.paddingSmall)
        .background(Theme.background)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Theme.primary : Theme.secondaryText)

                Text(tab.rawValue)
                    .font(.system(size: Theme.fontSizeSmall, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Theme.primary : Theme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Navigation Container
struct NavigationContainer<Content: View>: View {
    let title: String
    var showSettings: Bool = true
    var onSettingsTap: (() -> Void)?
    var leadingButton: (() -> AnyView)? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(
                title: title,
                showSettings: showSettings,
                onSettingsTap: onSettingsTap,
                leadingButton: leadingButton
            )

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.background)
    }
}

// MARK: - Back Button
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.primary)
        }
    }
}
