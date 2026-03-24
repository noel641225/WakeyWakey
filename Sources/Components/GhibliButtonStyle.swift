import SwiftUI

// MARK: - Ghibli Button Style Variant
enum GhibliButtonVariant {
    case primary
    case secondary
}

// MARK: - Ghibli Button Style
struct GhibliButtonStyle: ButtonStyle {
    let variant: GhibliButtonVariant

    init(_ variant: GhibliButtonVariant = .primary) {
        self.variant = variant
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GhibliTheme.Typography.heading(16))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, GhibliTheme.Spacing.lg)
            .padding(.vertical, GhibliTheme.Spacing.md)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: GhibliTheme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: GhibliTheme.Radius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .ghibliShadow(GhibliTheme.Shadow.soft)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: return .white
        case .secondary: return .ghibliDeepForest
        }
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .primary:
            LinearGradient(
                colors: [Color.ghibliForestGreen, Color.ghibliForestGreen.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            Color.ghibliParchment
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary: return Color.ghibliMeadowGold.opacity(0.4)
        case .secondary: return Color.ghibliWarmEarth.opacity(0.35)
        }
    }
}

// MARK: - Convenience Extensions
extension View {
    func ghibliButton(_ variant: GhibliButtonVariant = .primary) -> some View {
        self.buttonStyle(GhibliButtonStyle(variant))
    }
}
