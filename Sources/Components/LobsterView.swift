import SwiftUI

// MARK: - Lobster View (Ghibli Style)
struct LobsterView: View {
    var size: CGFloat = 80

    @State private var breathScale: CGFloat = 1.0
    @State private var isWaving = false
    @State private var eyeBlink = false
    @State private var antennaeWave = false

    private var bodyColor: Color { Color.ghibliSunsetGlow }
    private var darkColor: Color { Color.ghibliWarmEarth }
    private var clawColor: Color { Color(hex: "D4784A") }

    var body: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.ghibleBarkBrown.opacity(0.12))
                .frame(width: size * 0.7, height: size * 0.1)
                .offset(y: size * 0.45)
                .blur(radius: 3)

            // Tail segments
            ForEach(0..<3, id: \.self) { i in
                Ellipse()
                    .fill(bodyColor.opacity(0.85 - Double(i) * 0.15))
                    .frame(width: size * (0.38 - CGFloat(i) * 0.06), height: size * 0.14)
                    .offset(y: size * (0.28 + CGFloat(i) * 0.12))
            }

            // Body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [bodyColor, clawColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.6, height: size * 0.4)
                .offset(y: size * 0.08)

            // Head
            Circle()
                .fill(bodyColor)
                .frame(width: size * 0.4, height: size * 0.4)
                .offset(y: -size * 0.16)

            // Antennae
            ForEach([-1.0, 1.0], id: \.self) { side in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addCurve(
                        to: CGPoint(x: side * size * 0.22, y: -size * 0.28),
                        control1: CGPoint(x: side * size * 0.05, y: -size * 0.1),
                        control2: CGPoint(x: side * size * 0.18, y: -size * 0.2)
                    )
                }
                .stroke(darkColor, lineWidth: 1.5)
                .offset(x: side * size * 0.08, y: -size * 0.26)
                .rotationEffect(.degrees(antennaeWave ? side * 8 : 0))
                .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: antennaeWave)

                Circle()
                    .fill(darkColor)
                    .frame(width: size * 0.04, height: size * 0.04)
                    .offset(
                        x: side * size * (0.08 + 0.22) + (antennaeWave ? side * size * 0.02 : 0),
                        y: -size * 0.44
                    )
            }

            // Eyes
            HStack(spacing: size * 0.12) {
                lobsterEye
                lobsterEye
            }
            .offset(y: -size * 0.21)
            .scaleEffect(eyeBlink ? CGSize(width: 1, height: 0.08) : CGSize(width: 1, height: 1))
            .animation(.easeInOut(duration: 0.08), value: eyeBlink)

            // Mouth
            Path { path in
                path.move(to: CGPoint(x: -size * 0.06, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.06, y: 0),
                    control: CGPoint(x: 0, y: size * 0.04)
                )
            }
            .stroke(darkColor.opacity(0.6), lineWidth: 1.5)
            .offset(y: -size * 0.1)

            // Left claw
            GhibliClaw(isLeft: true, size: size, bodyColor: bodyColor, darkColor: darkColor)
                .offset(x: -size * 0.42, y: -size * 0.05)
                .rotationEffect(.degrees(isWaving ? -18 : 0), anchor: .trailing)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isWaving)

            // Right claw
            GhibliClaw(isLeft: false, size: size, bodyColor: bodyColor, darkColor: darkColor)
                .offset(x: size * 0.42, y: -size * 0.05)
                .rotationEffect(.degrees(isWaving ? 18 : 0), anchor: .leading)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isWaving)

            // Walking legs
            ForEach(0..<3, id: \.self) { i in
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: side * size * 0.15, y: size * 0.12))
                    }
                    .stroke(darkColor.opacity(0.7), lineWidth: 1.2)
                    .offset(x: side * size * (0.18 + CGFloat(i) * 0.04), y: size * (0.1 + CGFloat(i) * 0.06))
                }
            }
        }
        .scaleEffect(breathScale)
        .frame(width: size, height: size)
        .onAppear { startAnimations() }
    }

    private var lobsterEye: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: size * 0.12, height: size * 0.12)
                .shadow(color: darkColor.opacity(0.2), radius: 1)
            Circle()
                .fill(Color.ghibleBarkBrown)
                .frame(width: size * 0.07, height: size * 0.07)
            Circle()
                .fill(.white)
                .frame(width: size * 0.025, height: size * 0.025)
                .offset(x: -size * 0.01, y: -size * 0.01)
        }
    }

    private func startAnimations() {
        // Breathing
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            breathScale = 1.03
        }
        // Waving claws
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            isWaving = true
        }
        // Antennae
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            antennaeWave = true
        }
        // Blink
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            eyeBlink = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                eyeBlink = false
            }
        }
    }
}

// MARK: - Ghibli Claw Shape
private struct GhibliClaw: View {
    let isLeft: Bool
    let size: CGFloat
    let bodyColor: Color
    let darkColor: Color

    var body: some View {
        ZStack {
            // Arm
            RoundedRectangle(cornerRadius: size * 0.06)
                .fill(bodyColor)
                .frame(width: size * 0.24, height: size * 0.1)
                .rotationEffect(.degrees(isLeft ? 20 : -20))

            // Upper pincer
            Ellipse()
                .fill(bodyColor)
                .frame(width: size * 0.18, height: size * 0.1)
                .offset(x: isLeft ? -size * 0.06 : size * 0.06, y: -size * 0.07)
                .rotationEffect(.degrees(isLeft ? -15 : 15))

            // Lower pincer
            Ellipse()
                .fill(darkColor.opacity(0.8))
                .frame(width: size * 0.14, height: size * 0.07)
                .offset(x: isLeft ? -size * 0.06 : size * 0.06, y: size * 0.03)
                .rotationEffect(.degrees(isLeft ? 15 : -15))
        }
    }
}

// MARK: - Preview
#Preview {
    LobsterView(size: 120)
        .padding(40)
        .background(Color.ghibliSoftSky.opacity(0.3))
}
