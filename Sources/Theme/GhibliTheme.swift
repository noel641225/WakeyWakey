import SwiftUI

// MARK: - Ghibli Color Palette
extension Color {
    // Primary Palette
    static let ghibliForestGreen = Color(hex: "4A7C59")
    static let ghibliWarmEarth = Color(hex: "8B6914")
    static let ghibliSoftSky = Color(hex: "87CEEB")
    static let ghibliSunsetGlow = Color(hex: "E8985E")
    static let ghibliCream = Color(hex: "FFF8E7")
    static let ghibliParchment = Color(hex: "F5E6D3")
    static let ghibliDeepForest = Color(hex: "2D4A3E")
    static let ghibleBarkBrown = Color(hex: "5C4033")
    static let ghibliSakuraPink = Color(hex: "FFB7C5")
    static let ghibliMeadowGold = Color(hex: "DAA520")

    // Dark Mode (Moonlit Forest)
    static let ghibliDarkBackground = Color(hex: "1A2A1F")
    static let ghibliDarkCard = Color(hex: "2D3E33")
    static let ghibliDarkPrimary = Color(hex: "6AAF7B")
    static let ghibliDarkText = Color(hex: "E8E0D4")
}

// MARK: - Ghibli Theme Namespace
enum GhibliTheme {

    // MARK: - Adaptive Colors
    enum Colors {
        static var background: Color { Color("GhibliBackground") }
        static var card: Color { Color("GhibliCard") }
        static var primary: Color { Color("GhibliPrimary") }
        static var textPrimary: Color { Color("GhibliTextPrimary") }
        static var textSecondary: Color { Color("GhibliTextSecondary") }

        // Fallback statics (used directly when asset catalog color not needed)
        static let forestGreen = Color.ghibliForestGreen
        static let warmEarth = Color.ghibliWarmEarth
        static let softSky = Color.ghibliSoftSky
        static let sunsetGlow = Color.ghibliSunsetGlow
        static let cream = Color.ghibliCream
        static let parchment = Color.ghibliParchment
        static let deepForest = Color.ghibliDeepForest
        static let barkBrown = Color.ghibleBarkBrown
        static let sakuraPink = Color.ghibliSakuraPink
        static let meadowGold = Color.ghibliMeadowGold
    }

    // MARK: - Typography
    enum Typography {
        static func title(_ size: CGFloat = 28) -> Font {
            .custom("Avenir-Heavy", size: size)
        }
        static func heading(_ size: CGFloat = 20) -> Font {
            .custom("Avenir-Medium", size: size)
        }
        static func body(_ size: CGFloat = 16) -> Font {
            .custom("Avenir", size: size)
        }
        static func caption(_ size: CGFloat = 12) -> Font {
            .custom("Avenir-Light", size: size)
        }
        static func timeDisplay(_ size: CGFloat = 48) -> Font {
            .custom("Avenir-Heavy", size: size)
        }
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let pill: CGFloat = 999
    }

    // MARK: - Shadows
    enum Shadow {
        struct ShadowConfig {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }

        static let soft = ShadowConfig(
            color: Color.ghibleBarkBrown.opacity(0.15),
            radius: 12,
            x: 0,
            y: 4
        )
        static let warm = ShadowConfig(
            color: Color.ghibliSunsetGlow.opacity(0.25),
            radius: 16,
            x: 0,
            y: 6
        )
        static let deep = ShadowConfig(
            color: Color.ghibliDeepForest.opacity(0.3),
            radius: 20,
            x: 0,
            y: 8
        )
    }
}

// MARK: - View Helpers
extension View {
    func ghibliShadow(_ style: GhibliTheme.Shadow.ShadowConfig = GhibliTheme.Shadow.soft) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
