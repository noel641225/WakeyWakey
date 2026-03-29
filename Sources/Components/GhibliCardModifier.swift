import SwiftUI

// MARK: - Ghibli Card View Modifier
struct GhibliCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var padding: EdgeInsets
    var cornerRadius: CGFloat

    init(padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
         cornerRadius: CGFloat = GhibliTheme.Radius.lg) {
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(colorScheme == .dark ? Color.ghibliDarkCard : Color.ghibliParchment)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.ghibliWarmEarth.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.ghibleBarkBrown.opacity(0.12),
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Dark Card Modifier
struct GhibliDarkCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    init(cornerRadius: CGFloat = GhibliTheme.Radius.lg) {
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .padding(GhibliTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.ghibliDeepForest.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.ghibliForestGreen.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Convenience Extensions
extension View {
    func ghibliCard(
        padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
        cornerRadius: CGFloat = GhibliTheme.Radius.lg
    ) -> some View {
        self.modifier(GhibliCardModifier(padding: padding, cornerRadius: cornerRadius))
    }

    func ghibliDarkCard(cornerRadius: CGFloat = GhibliTheme.Radius.lg) -> some View {
        self.modifier(GhibliDarkCardModifier(cornerRadius: cornerRadius))
    }
}
