import SwiftUI

// MARK: - Lobster View (紅色龍蝦)
struct LobsterView: View {
    @State private var isWaving = false
    @State private var eyeBlink = false
    
    var body: some View {
        ZStack {
            // 身體
            Ellipse()
                .fill(Color(hex: "FF6B6B"))
                .frame(width: 50, height: 35)
            
            // 頭部
            Circle()
                .fill(Color(hex: "FF6B6B"))
                .frame(width: 30, height: 30)
                .offset(y: -15)
            
            // 眼睛
            HStack(spacing: 8) {
                Circle()
                    .fill(.white)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .fill(.black)
                            .frame(width: 4, height: 4)
                    )
                
                Circle()
                    .fill(.white)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .fill(.black)
                            .frame(width: 4, height: 4)
                    )
            }
            .offset(y: -18)
            .scaleEffect(eyeBlink ? 0.1 : 1)
            .animation(.easeInOut(duration: 0.1), value: eyeBlink)
            
            // 嘴巴
            if !eyeBlink {
                Circle()
                    .fill(Color(hex: "FF8E53"))
                    .frame(width: 6, height: 4)
                    .offset(y: -8)
            }
            
            // 左鉗子
            LeftClaw()
                .offset(x: -25, y: -5)
                .rotationEffect(.degrees(isWaving ? -20 : 0))
                .animation(.easeInOut(duration: 0.3), value: isWaving)
            
            // 右鉗子
            RightClaw()
                .offset(x: 25, y: -5)
                .rotationEffect(.degrees(isWaving ? 20 : 0))
                .animation(.easeInOut(duration: 0.3), value: isWaving)
            
            // 觸角
            Antenna()
                .offset(x: -8, y: -30)
                .rotationEffect(.degrees(isWaving ? -10 : 0))
                .animation(.easeInOut(duration: 0.3), value: isWaving)
            
            Antenna()
                .offset(x: 8, y: -30)
                .rotationEffect(.degrees(isWaving ? 10 : 0))
                .animation(.easeInOut(duration: 0.3), value: isWaving)
        }
        .onAppear {
            isWaving = true
            startBlinking()
        }
    }
    
    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            eyeBlink = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                eyeBlink = false
            }
        }
    }
}

// MARK: - Left Claw
struct LeftClaw: View {
    var body: some View {
        ZStack {
            // 鉗子臂
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "FF6B6B"))
                .frame(width: 20, height: 8)
                .rotationEffect(.degrees(-30))
            
            // 鉗子
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(to: CGPoint(x: 15, y: -8), control: CGPoint(x: 5, y: -12))
                path.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: 10, y: 0))
            }
            .fill(Color(hex: "FF6B6B"))
            .offset(x: -8, y: -10)
        }
    }
}

// MARK: - Right Claw
struct RightClaw: View {
    var body: some View {
        ZStack {
            // 鉗子臂
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "FF6B6B"))
                .frame(width: 20, height: 8)
                .rotationEffect(.degrees(30))
            
            // 鉗子
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(to: CGPoint(x: -15, y: -8), control: CGPoint(x: -5, y: -12))
                path.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: -10, y: 0))
            }
            .fill(Color(hex: "FF6B6B"))
            .offset(x: 8, y: -10)
        }
    }
}

// MARK: - Antenna
struct Antenna: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -15))
        }
        .stroke(Color(hex: "FF6B6B"), lineWidth: 2)
        
        Circle()
            .fill(Color(hex: "FF8E53"))
            .frame(width: 4, height: 4)
            .offset(y: -17)
    }
}

// MARK: - Preview
#Preview {
    LobsterView()
        .frame(width: 100, height: 100)
        .padding()
}
