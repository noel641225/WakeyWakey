import SwiftUI

// MARK: - Sunrise Background View
struct SunriseBackgroundView: View {
    @State private var sunRise: CGFloat = 0     // 0 = below horizon, 1 = fully risen
    @State private var glowPulse = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sky gradient (deep purple → orange → gold)
                LinearGradient(
                    colors: [
                        Color(hex: "1A0A2E"),  // deep purple
                        Color(hex: "6B2D6B"),  // purple
                        Color.ghibliSunsetGlow,
                        Color.ghibliMeadowGold.opacity(0.9),
                        Color.ghibliCream
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Horizon glow
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.ghibliMeadowGold.opacity(0.6),
                                Color.ghibliSunsetGlow.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.7
                        )
                    )
                    .frame(width: geo.size.width * 1.4, height: geo.size.height * 0.5)
                    .offset(y: geo.size.height * 0.25)
                    .blur(radius: 20)

                // Sun disk
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.ghibliMeadowGold.opacity(0.5),
                                    Color.ghibliSunsetGlow.opacity(0.2),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(glowPulse ? 1.08 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                            value: glowPulse
                        )

                    // Sun body
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white, Color.ghibliMeadowGold, Color.ghibliSunsetGlow],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                }
                .position(
                    x: geo.size.width * 0.5,
                    y: geo.size.height * 0.55 - sunRise * geo.size.height * 0.3
                )

                // Floating clouds
                cloudLayer(geo: geo)

                // Silhouette hills at bottom
                hillSilhouette(geo: geo)
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeOut(duration: 3.0)) {
                    sunRise = 1.0
                }
                glowPulse = true
            }
        }
    }

    // MARK: - Clouds
    private func cloudLayer(geo: GeometryProxy) -> some View {
        ZStack {
            cloudShape(width: 140, at: CGPoint(x: geo.size.width * 0.15, y: geo.size.height * 0.25))
            cloudShape(width: 110, at: CGPoint(x: geo.size.width * 0.75, y: geo.size.height * 0.18))
            cloudShape(width: 90, at: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.32))
        }
    }

    private func cloudShape(width: CGFloat, at position: CGPoint) -> some View {
        ZStack {
            Ellipse()
                .fill(Color.white.opacity(0.6))
                .frame(width: width, height: width * 0.4)
            Ellipse()
                .fill(Color.white.opacity(0.5))
                .frame(width: width * 0.55, height: width * 0.35)
                .offset(x: -width * 0.2, y: -width * 0.1)
            Ellipse()
                .fill(Color.white.opacity(0.45))
                .frame(width: width * 0.45, height: width * 0.3)
                .offset(x: width * 0.15, y: -width * 0.08)
        }
        .blur(radius: 3)
        .position(position)
    }

    // MARK: - Hill Silhouette
    private func hillSilhouette(geo: GeometryProxy) -> some View {
        ZStack {
            // Back hill
            Ellipse()
                .fill(Color.ghibliDeepForest.opacity(0.5))
                .frame(width: geo.size.width * 1.4, height: geo.size.height * 0.35)
                .offset(y: geo.size.height * 0.5)

            // Front hill
            Ellipse()
                .fill(Color.ghibliDeepForest.opacity(0.8))
                .frame(width: geo.size.width * 1.6, height: geo.size.height * 0.3)
                .offset(y: geo.size.height * 0.58)

            // Ground
            Rectangle()
                .fill(Color.ghibliDeepForest)
                .frame(height: geo.size.height * 0.25)
                .frame(maxWidth: .infinity)
                .offset(y: geo.size.height * 0.38)
        }
    }
}

// MARK: - Preview
#Preview {
    SunriseBackgroundView()
}
