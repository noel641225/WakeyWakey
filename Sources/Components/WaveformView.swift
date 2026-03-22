import SwiftUI

// MARK: - Waveform View
/// Renders audio amplitude samples as vertical bars using Canvas.
struct WaveformView: View {
    let samples: [Float]
    /// Fraction (0–1) of the audio where the selection starts.
    var startFraction: Double = 0
    /// Fraction (0–1) of the audio where the selection ends.
    var endFraction: Double = 1

    var body: some View {
        Canvas { context, size in
            guard !samples.isEmpty else { return }

            let count    = samples.count
            let barWidth = size.width / CGFloat(count)
            let midY     = size.height / 2

            for (i, sample) in samples.enumerated() {
                let fraction   = Double(i) / Double(count)
                let isSelected = fraction >= startFraction && fraction <= endFraction

                let barHeight  = CGFloat(sample) * midY * 0.9
                let rect = CGRect(
                    x:      CGFloat(i) * barWidth,
                    y:      midY - barHeight,
                    width:  max(1, barWidth - 0.5),
                    height: barHeight * 2
                )

                let color: Color = isSelected
                    ? Color(red: 1.0, green: 0.42, blue: 0.42)   // #FF6B6B
                    : Color.gray.opacity(0.25)

                context.fill(Path(rect), with: .color(color))
            }

            // Draw start and end handle lines
            let startX = size.width * CGFloat(startFraction)
            let endX   = size.width * CGFloat(endFraction)

            var startPath = Path()
            startPath.move(to:    CGPoint(x: startX, y: 0))
            startPath.addLine(to: CGPoint(x: startX, y: size.height))
            context.stroke(startPath, with: .color(.white), lineWidth: 2)

            var endPath = Path()
            endPath.move(to:    CGPoint(x: endX, y: 0))
            endPath.addLine(to: CGPoint(x: endX, y: size.height))
            context.stroke(endPath, with: .color(.white), lineWidth: 2)

            // Handle knobs
            let knobRadius: CGFloat = 6
            context.fill(
                Path(ellipseIn: CGRect(
                    x: startX - knobRadius,
                    y: midY - knobRadius,
                    width:  knobRadius * 2,
                    height: knobRadius * 2)),
                with: .color(.white))

            context.fill(
                Path(ellipseIn: CGRect(
                    x: endX - knobRadius,
                    y: midY - knobRadius,
                    width:  knobRadius * 2,
                    height: knobRadius * 2)),
                with: .color(.white))
        }
        .background(Color.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    WaveformView(
        samples: (0..<100).map { _ in Float.random(in: 0.05...0.95) },
        startFraction: 0.2,
        endFraction: 0.7
    )
    .frame(height: 80)
    .padding()
    .background(Color(red: 1.0, green: 0.71, blue: 0.76))
}
