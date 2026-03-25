import SwiftUI

// MARK: - Nekomaru View (圓貓)
struct NekomaruView: View {
    var size: CGFloat = 60
    @State private var tailAngle: CGFloat = 0
    @State private var breathScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Tail
            Path { path in
                path.move(to: CGPoint(x: size * 0.3, y: size * 0.3))
                path.addCurve(
                    to: CGPoint(x: size * 0.55, y: -size * 0.1),
                    control1: CGPoint(x: size * 0.55, y: size * 0.3),
                    control2: CGPoint(x: size * 0.6, y: size * 0.1)
                )
            }
            .stroke(Color.ghibliWarmEarth, lineWidth: size * 0.1)
            .rotationEffect(.degrees(tailAngle), anchor: UnitPoint(x: 0.3, y: 0.8))
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: tailAngle)

            // Body
            Ellipse()
                .fill(Color.ghibliWarmEarth)
                .frame(width: size * 0.85, height: size * 0.75)
                .offset(y: size * 0.1)

            // Belly
            Ellipse()
                .fill(Color.ghibliCream)
                .frame(width: size * 0.5, height: size * 0.4)
                .offset(y: size * 0.18)

            // Head
            Circle()
                .fill(Color.ghibliWarmEarth)
                .frame(width: size * 0.65, height: size * 0.65)
                .offset(y: -size * 0.2)

            // Ears
            ForEach([-1.0, 1.0], id: \.self) { side in
                Triangle()
                    .fill(Color.ghibliWarmEarth)
                    .frame(width: size * 0.2, height: size * 0.22)
                    .offset(x: side * size * 0.2, y: -size * 0.46)
                    .rotationEffect(.degrees(side * 10))
            }

            // Eyes
            HStack(spacing: size * 0.16) {
                catEye
                catEye
            }
            .offset(y: -size * 0.25)

            // Nose
            Triangle()
                .fill(Color.ghibliSakuraPink)
                .frame(width: size * 0.1, height: size * 0.08)
                .offset(y: -size * 0.15)

            // Whiskers
            ForEach([-1.0, 1.0], id: \.self) { side in
                ForEach([-1, 0, 1], id: \.self) { row in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.ghibleBarkBrown.opacity(0.4))
                        .frame(width: size * 0.22, height: 1)
                        .offset(x: side * size * 0.22, y: -size * 0.13 + CGFloat(row) * size * 0.04)
                        .rotationEffect(.degrees(side * Double(row) * 5))
                }
            }
        }
        .scaleEffect(breathScale)
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                tailAngle = 15
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathScale = 1.03
            }
        }
    }

    private var catEye: some View {
        Ellipse()
            .fill(Color.ghibliForestGreen)
            .frame(width: size * 0.14, height: size * 0.16)
            .overlay(
                Capsule()
                    .fill(Color(hex: "1A1A1A"))
                    .frame(width: size * 0.05, height: size * 0.14)
            )
            .overlay(
                Circle().fill(.white).frame(width: size * 0.04, height: size * 0.04)
                    .offset(x: size * 0.02, y: -size * 0.03)
            )
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

#Preview {
    NekomaruView(size: 100)
        .padding(40)
        .background(Color.ghibliCream)
}
