import SwiftUI

// MARK: - Kinoko View (可愛蘑菇)
struct KinokoView: View {
    var size: CGFloat = 50
    @State private var bounceY: CGFloat = 0

    var body: some View {
        ZStack {
            // Stem
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(Color.ghibliParchment)
                .frame(width: size * 0.44, height: size * 0.38)
                .offset(y: size * 0.22)

            // Cap
            Ellipse()
                .fill(Color.ghibliSunsetGlow)
                .frame(width: size * 0.9, height: size * 0.55)
                .offset(y: -size * 0.08)

            // Cap spots
            ForEach([
                CGPoint(x: -0.2, y: -0.05),
                CGPoint(x: 0.18, y: -0.1),
                CGPoint(x: 0.0, y: 0.08)
            ], id: \.x) { pos in
                Circle()
                    .fill(Color.ghibliCream.opacity(0.85))
                    .frame(width: size * 0.14, height: size * 0.14)
                    .offset(x: pos.x * size, y: pos.y * size)
            }

            // Eyes
            HStack(spacing: size * 0.18) {
                Circle().fill(Color.ghibleBarkBrown).frame(width: size * 0.1, height: size * 0.1)
                Circle().fill(Color.ghibleBarkBrown).frame(width: size * 0.1, height: size * 0.1)
            }
            .offset(y: size * 0.2)

            // Smile
            Path { path in
                path.move(to: CGPoint(x: -size * 0.08, y: 0))
                path.addQuadCurve(to: CGPoint(x: size * 0.08, y: 0), control: CGPoint(x: 0, y: size * 0.06))
            }
            .stroke(Color.ghibleBarkBrown, lineWidth: 1.5)
            .offset(y: size * 0.3)
        }
        .offset(y: bounceY)
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                bounceY = -size * 0.08
            }
        }
    }
}

#Preview {
    KinokoView(size: 80)
        .padding(40)
        .background(Color.ghibliSoftSky.opacity(0.3))
}
