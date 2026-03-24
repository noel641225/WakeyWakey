import SwiftUI

// MARK: - Ghibli Leaf Toggle Style
struct GhibliToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            leafToggle(isOn: configuration.isOn, toggle: configuration.$isOn)
        }
    }

    private func leafToggle(isOn: Bool, toggle: Binding<Bool>) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            // Branch / track
            Capsule()
                .fill(isOn ? Color.ghibliForestGreen.opacity(0.3) : Color.ghibleBarkBrown.opacity(0.2))
                .frame(width: 52, height: 30)
                .overlay(
                    Capsule()
                        .stroke(isOn ? Color.ghibliForestGreen : Color.ghibleBarkBrown.opacity(0.4), lineWidth: 1.5)
                )

            // Leaf thumb
            ZStack {
                Circle()
                    .fill(isOn ? Color.ghibliForestGreen : Color.ghibliParchment)
                    .frame(width: 26, height: 26)
                    .shadow(color: isOn ? Color.ghibliForestGreen.opacity(0.4) : Color.ghibleBarkBrown.opacity(0.15), radius: 4, x: 0, y: 2)

                // Leaf vein icon when ON
                if isOn {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .stroke(Color.ghibleBarkBrown.opacity(0.3), lineWidth: 1)
                        .frame(width: 18, height: 18)
                }
            }
            .padding(2)
        }
        .frame(width: 52, height: 30)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                toggle.wrappedValue.toggle()
            }
        }
    }
}

// MARK: - Convenience Extension
extension View {
    func ghibliToggle() -> some View {
        self.toggleStyle(GhibliToggleStyle())
    }
}
