import SwiftUI

// MARK: - Animated Character View
/// Displays an animated character that uses a SpriteAnimator.
/// Falls back to a hand-drawn placeholder when no sprite frames are loaded.
struct AnimatedCharacterView: View {
    @ObservedObject var animator: SpriteAnimator
    var size: CGFloat = 80
    var onTap: (() -> Void)?

    var body: some View {
        ZStack {
            if animator.frameNames.isEmpty {
                // Placeholder — drawn programmatically
                placeholderCharacter
            } else {
                // Sprite frame from asset catalog
                if let name = animator.frameNames[safe: animator.currentFrameIndex],
                   UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                } else {
                    placeholderCharacter
                }
            }
        }
        .scaleEffect(animator.animationState == .tapped ? 0.85 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: animator.animationState == .tapped)
        .onTapGesture {
            onTap?()
        }
    }

    // MARK: - Placeholder Character (Totoro-style silhouette)
    private var placeholderCharacter: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.15))
                .frame(width: size * 0.8, height: size * 0.15)
                .offset(y: size * 0.42)
                .blur(radius: 4)

            // Body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.ghibliForestGreen.opacity(0.9),
                            Color.ghibliDeepForest
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.7, height: size * 0.75)
                .offset(y: size * 0.08)

            // Belly
            Ellipse()
                .fill(Color.ghibliCream)
                .frame(width: size * 0.42, height: size * 0.48)
                .offset(y: size * 0.16)

            // Head
            Circle()
                .fill(Color.ghibliForestGreen.opacity(0.85))
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(y: -size * 0.18)

            // Ears
            ForEach([(-1.0, 1.0), (1.0, 1.0)], id: \.0) { (xSign, _) in
                Ellipse()
                    .fill(Color.ghibliDeepForest)
                    .frame(width: size * 0.12, height: size * 0.22)
                    .rotationEffect(.degrees(xSign * 12))
                    .offset(x: xSign * size * 0.2, y: -size * 0.38)
            }

            // Eyes
            ForEach([(-1.0, 1.0), (1.0, 1.0)], id: \.0) { (xSign, _) in
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.1, height: size * 0.1)
                    .overlay(
                        Circle()
                            .fill(Color.ghibliDeepForest)
                            .frame(width: size * 0.06, height: size * 0.06)
                    )
                    .offset(x: xSign * size * 0.1, y: -size * 0.2)
            }

            // Nose
            Ellipse()
                .fill(Color.ghibliSakuraPink)
                .frame(width: size * 0.06, height: size * 0.04)
                .offset(y: -size * 0.1)

            // Whisker marks
            ForEach([-1.0, 1.0], id: \.self) { side in
                ForEach([0, 1, 2], id: \.self) { index in
                    let yOffset = CGFloat(index - 1) * size * 0.04
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.ghibliDeepForest.opacity(0.5))
                        .frame(width: size * 0.14, height: 1.5)
                        .offset(x: side * size * 0.18, y: -size * 0.1 + yOffset)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Safe Array Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview
#Preview {
    let animator = SpriteAnimator()
    return AnimatedCharacterView(animator: animator, size: 120)
        .padding()
        .background(Color.ghibliSoftSky)
}
