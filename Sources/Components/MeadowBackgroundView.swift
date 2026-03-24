import SwiftUI

// MARK: - Dust Mote Particle
private struct DustMote: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var duration: Double
}

// MARK: - Meadow Background View
struct MeadowBackgroundView: View {
    @State private var motes: [DustMote] = []
    @State private var cloudOffset: CGFloat = 0
    @State private var animateMotes = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sky gradient
                LinearGradient(
                    colors: [
                        Color.ghibliSoftSky,
                        Color.ghibliSoftSky.opacity(0.7),
                        Color.ghibliCream.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.55)
                )

                // Ground / meadow gradient
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(
                        colors: [
                            Color.ghibliForestGreen.opacity(0.25),
                            Color.ghibliForestGreen.opacity(0.5),
                            Color.ghibliDeepForest.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.38)
                }

                // Soft cloud layers
                cloudLayer(width: geo.size.width, at: geo.size.height * 0.22, scale: 1.0)
                    .offset(x: cloudOffset * 0.4)
                cloudLayer(width: geo.size.width, at: geo.size.height * 0.32, scale: 0.7)
                    .offset(x: -cloudOffset * 0.25)

                // Floating dust motes
                ForEach(motes) { mote in
                    Circle()
                        .fill(Color.ghibliMeadowGold.opacity(mote.opacity))
                        .frame(width: mote.size, height: mote.size)
                        .position(x: mote.x, y: mote.y)
                        .animation(
                            Animation.easeInOut(duration: mote.duration).repeatForever(autoreverses: true),
                            value: animateMotes
                        )
                }
            }
            .ignoresSafeArea()
            .onAppear {
                spawnMotes(in: geo.size)
                startCloudAnimation(width: geo.size.width)
            }
        }
    }

    // MARK: - Cloud Layer
    private func cloudLayer(width: CGFloat, at yPos: CGFloat, scale: CGFloat) -> some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Ellipse()
                    .fill(Color.white.opacity(0.55 * scale))
                    .frame(width: 120 * scale, height: 50 * scale)
                    .offset(x: (CGFloat(i) * 180 - width * 0.3) * scale, y: yPos)
                    .blur(radius: 8 * scale)
            }
        }
    }

    // MARK: - Spawn Dust Motes
    private func spawnMotes(in size: CGSize) {
        motes = (0..<18).map { _ in
            DustMote(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height * 0.7),
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.2...0.6),
                duration: Double.random(in: 2.5...6.0)
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateMotes = true
        }
    }

    // MARK: - Cloud Animation
    private func startCloudAnimation(width: CGFloat) {
        withAnimation(Animation.linear(duration: 40).repeatForever(autoreverses: true)) {
            cloudOffset = width * 0.15
        }
    }
}

// MARK: - Preview
#Preview {
    MeadowBackgroundView()
}
