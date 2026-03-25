import SwiftUI

// MARK: - Bunny View (Ghibli Style)
struct BunnyView: View {
    var isAnimating: Bool = false
    var size: CGFloat = 80

    @State private var breathScale: CGFloat = 1.0
    @State private var isHeadTilted = false
    @State private var eyeBlink = false

    var body: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.ghibleBarkBrown.opacity(0.12))
                .frame(width: size * 0.65, height: size * 0.12)
                .offset(y: size * 0.44)
                .blur(radius: 3)
                .scaleEffect(x: breathScale * 0.97, y: 1)

            // Body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.ghibliCream, Color(hex: "F0E8D0")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.62, height: size * 0.55)
                .offset(y: size * 0.1)

            // Belly
            Ellipse()
                .fill(Color(hex: "FFF0E0"))
                .frame(width: size * 0.36, height: size * 0.32)
                .offset(y: size * 0.18)

            // Left ear
            Ellipse()
                .fill(Color.ghibliCream)
                .frame(width: size * 0.15, height: size * 0.42)
                .offset(x: -size * 0.14, y: -size * 0.35)
                .rotationEffect(.degrees(isHeadTilted ? -8 : 0))
                .animation(.easeInOut(duration: 0.6), value: isHeadTilted)

            // Left ear inner
            Ellipse()
                .fill(Color.ghibliSakuraPink.opacity(0.7))
                .frame(width: size * 0.07, height: size * 0.28)
                .offset(x: -size * 0.14, y: -size * 0.33)
                .rotationEffect(.degrees(isHeadTilted ? -8 : 0))
                .animation(.easeInOut(duration: 0.6), value: isHeadTilted)

            // Right ear
            Ellipse()
                .fill(Color.ghibliCream)
                .frame(width: size * 0.15, height: size * 0.42)
                .offset(x: size * 0.14, y: -size * 0.35)
                .rotationEffect(.degrees(isHeadTilted ? 8 : 0))
                .animation(.easeInOut(duration: 0.6), value: isHeadTilted)

            // Right ear inner
            Ellipse()
                .fill(Color.ghibliSakuraPink.opacity(0.7))
                .frame(width: size * 0.07, height: size * 0.28)
                .offset(x: size * 0.14, y: -size * 0.33)
                .rotationEffect(.degrees(isHeadTilted ? 8 : 0))
                .animation(.easeInOut(duration: 0.6), value: isHeadTilted)

            // Head
            Circle()
                .fill(Color.ghibliCream)
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(y: -size * 0.18)
                .rotationEffect(.degrees(isHeadTilted ? 12 : 0))
                .animation(.easeInOut(duration: 0.6), value: isHeadTilted)

            // Eyes
            HStack(spacing: size * 0.13) {
                eyeView
                eyeView
            }
            .offset(y: -size * 0.24)
            .scaleEffect(eyeBlink ? CGSize(width: 1.0, height: 0.08) : CGSize(width: 1, height: 1))
            .animation(.easeInOut(duration: 0.08), value: eyeBlink)

            // Nose
            Ellipse()
                .fill(Color.ghibliSakuraPink)
                .frame(width: size * 0.08, height: size * 0.05)
                .offset(y: -size * 0.16)

            // Cheeks
            HStack(spacing: size * 0.22) {
                Ellipse()
                    .fill(Color.ghibliSakuraPink.opacity(0.35))
                    .frame(width: size * 0.1, height: size * 0.06)
                Ellipse()
                    .fill(Color.ghibliSakuraPink.opacity(0.35))
                    .frame(width: size * 0.1, height: size * 0.06)
            }
            .offset(y: -size * 0.19)

            // Tail
            Circle()
                .fill(Color.ghibliCream)
                .frame(width: size * 0.16, height: size * 0.16)
                .offset(x: -size * 0.36, y: size * 0.08)
                .shadow(color: Color.ghibleBarkBrown.opacity(0.08), radius: 2)

            // Feet
            HStack(spacing: size * 0.18) {
                Ellipse()
                    .fill(Color.ghibliCream)
                    .frame(width: size * 0.2, height: size * 0.12)
                Ellipse()
                    .fill(Color.ghibliCream)
                    .frame(width: size * 0.2, height: size * 0.12)
            }
            .offset(y: size * 0.36)
        }
        .scaleEffect(breathScale)
        .frame(width: size, height: size)
        .onAppear {
            if isAnimating { startAnimations() }
        }
    }

    private var eyeView: some View {
        Circle()
            .fill(Color.ghibleBarkBrown)
            .frame(width: size * 0.09, height: size * 0.09)
            .overlay(
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.03, height: size * 0.03)
                    .offset(x: -size * 0.01, y: -size * 0.01)
            )
    }

    private func startAnimations() {
        // Breathing animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            breathScale = 1.03
        }

        // Head tilt
        Timer.scheduledTimer(withTimeInterval: 2.8, repeats: true) { _ in
            withAnimation { isHeadTilted = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { isHeadTilted = false }
            }
        }

        // Blink
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            eyeBlink = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                eyeBlink = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    BunnyView(isAnimating: true, size: 120)
        .padding(40)
        .background(Color.ghibliSoftSky.opacity(0.3))
}
