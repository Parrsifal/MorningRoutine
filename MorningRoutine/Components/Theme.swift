import SwiftUI
import UIKit

// MARK: - App Theme
enum Theme {
    // MARK: - Colors
    static let primary = Color.orange
    static let secondary = Color.orange.opacity(0.15)
    static let accent = Color.orange
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let text = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let destructive = Color.red

    // MARK: - Gradients
    static let sunriseGradient = LinearGradient(
        colors: [Color.orange, Color.yellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [Color.orange.opacity(0.8), Color.orange],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24

    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16

    // MARK: - Font Sizes
    static let fontSizeSmall: CGFloat = 12
    static let fontSizeMedium: CGFloat = 14
    static let fontSizeLarge: CGFloat = 16
    static let fontSizeTitle: CGFloat = 20
    static let fontSizeHeader: CGFloat = 28
}

// MARK: - View Extensions
extension View {
    func primaryButtonStyle() -> some View {
        self
            .font(.system(size: Theme.fontSizeLarge, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.primary)
            .cornerRadius(Theme.cornerRadiusMedium)
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(.system(size: Theme.fontSizeLarge, weight: .semibold))
            .foregroundColor(Theme.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.secondary)
            .cornerRadius(Theme.cornerRadiusMedium)
    }

    func cardStyle() -> some View {
        self
            .padding(Theme.paddingMedium)
            .background(Theme.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
    }

    func inputFieldStyle() -> some View {
        self
            .padding(Theme.paddingMedium)
            .background(Theme.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusSmall)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: Theme.fontSizeLarge, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(configuration.isPressed ? Theme.primary.opacity(0.8) : Theme.primary)
            .cornerRadius(Theme.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: Theme.fontSizeLarge, weight: .semibold))
            .foregroundColor(Theme.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(configuration.isPressed ? Theme.secondary.opacity(0.5) : Theme.secondary)
            .cornerRadius(Theme.cornerRadiusMedium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
