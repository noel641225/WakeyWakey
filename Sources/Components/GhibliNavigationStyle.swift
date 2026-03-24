import SwiftUI
import UIKit

// MARK: - Ghibli Navigation Appearance
enum GhibliNavigationStyle {
    static func applyGlobalAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        // Parchment background
        appearance.backgroundColor = UIColor(Color.ghibliCream)

        // Title attributes — rounded/warm font
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.ghibliDeepForest),
            .font: UIFont(name: "Avenir-Heavy", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .bold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.ghibliDeepForest),
            .font: UIFont(name: "Avenir-Heavy", size: 34) ?? UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        // Forest green back button tint
        let backItemAppearance = UIBarButtonItemAppearance()
        backItemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.ghibliForestGreen)
        ]
        appearance.backButtonAppearance = backItemAppearance

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(Color.ghibliForestGreen)
    }
}

// MARK: - Ghibli Navigation View Modifier
struct GhibliNavigationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .tint(.ghibliForestGreen)
    }
}

extension View {
    func ghibliNavigation() -> some View {
        self.modifier(GhibliNavigationModifier())
    }
}
