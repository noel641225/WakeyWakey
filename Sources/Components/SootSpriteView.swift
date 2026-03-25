import SwiftUI

// MARK: - Soot Sprite View (煤灰小精靈)
struct SootSpriteView: View {
    var size: CGFloat = 30
    @State private var wobble: CGFloat = 0

    var body: some View {
        ZStack {
            // Fuzzy body
            Circle()
                .fill(Color(hex: "1A1A1A"))
                .frame(width: size, height: size)
                .blur(radius: size * 0.06)

            // Left eye
            Circle()
                .fill(.white)
                .frame(width: size * 0.3, height: size * 0.3)
                .overlay(Circle().fill(Color(hex: "1A1A1A")).frame(width: size * 0.15, height: size * 0.15))
                .offset(x: -size * 0.14, y: -size * 0.06)

            // Right eye
            Circle()
                .fill(.white)
                .frame(width: size * 0.3, height: size * 0.3)
                .overlay(Circle().fill(Color(hex: "1A1A1A")).frame(width: size * 0.15, height: size * 0.15))
                .offset(x: size * 0.14, y: -size * 0.06)

            // Tiny legs
            HStack(spacing: size * 0.12) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: "1A1A1A"))
                        .frame(width: size * 0.06, height: size * 0.22)
                }
            }
            .offset(y: size * 0.46)
        }
        .rotationEffect(.degrees(wobble))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                wobble = 8
            }
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        SootSpriteView(size: 30)
        SootSpriteView(size: 22)
        SootSpriteView(size: 26)
    }
    .padding()
    .background(Color.ghibliCream)
}
