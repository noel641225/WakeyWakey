import SwiftUI

// MARK: - Bunny View (可愛小兔子)
struct BunnyView: View {
    var isAnimating: Bool = false
    
    @State private var isHopping = false
    @State private var isHeadTilted = false
    @State private var eyeBlink = false
    
    var body: some View {
        ZStack {
            // 陰影
            Ellipse()
                .fill(Color.black.opacity(0.1))
                .frame(width: 50, height: 10)
                .offset(y: 35)
                .scaleEffect(isHopping ? 0.8 : 1)
                .animation(.easeInOut(duration: 0.3), value: isHopping)
            
            // 身體
            Ellipse()
                .fill(Color.white)
                .frame(width: 50, height: 45)
                .offset(y: isHopping ? -5 : 0)
                .animation(.easeInOut(duration: 0.3), value: isHopping)
            
            // 肚子
            Ellipse()
                .fill(Color(hex: "FFF0F5"))
                .frame(width: 30, height: 25)
                .offset(y: 5)
            
            // 頭部
            Circle()
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .offset(y: -25)
                .rotationEffect(.degrees(isHeadTilted ? 15 : 0))
                .animation(.easeInOut(duration: 0.5), value: isHeadTilted)
            
            // 左耳朵
            Ellipse()
                .fill(Color.white)
                .frame(width: 12, height: 35)
                .offset(x: -10, y: -50)
                .rotationEffect(.degrees(isHeadTilted ? -10 : 0))
                .animation(.easeInOut(duration: 0.5), value: isHeadTilted)
            
            // 左耳朵內部
            Ellipse()
                .fill(Color(hex: "FFB6C1"))
                .frame(width: 6, height: 25)
                .offset(x: -10, y: -48)
            
            // 右耳朵
            Ellipse()
                .fill(Color.white)
                .frame(width: 12, height: 35)
                .offset(x: 10, y: -50)
                .rotationEffect(.degrees(isHeadTilted ? 10 : 0))
                .animation(.easeInOut(duration: 0.5), value: isHeadTilted)
            
            // 右耳朵內部
            Ellipse()
                .fill(Color(hex: "FFB6C1"))
                .frame(width: 6, height: 25)
                .offset(x: 10, y: -48)
            
            // 眼睛
            HStack(spacing: 12) {
                Circle()
                    .fill(.black)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 2, height: 2)
                            .offset(x: -1, y: -1)
                    )
                
                Circle()
                    .fill(.black)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 2, height: 2)
                            .offset(x: -1, y: -1)
                    )
            }
            .offset(y: -28)
            .scaleEffect(eyeBlink ? 0.1 : 1)
            .animation(.easeInOut(duration: 0.1), value: eyeBlink)
            
            // 鼻子
            Ellipse()
                .fill(Color(hex: "FFB6C1"))
                .frame(width: 6, height: 4)
                .offset(y: -22)
            
            // 嘴巴
            VStack(spacing: 0) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addQuadCurve(to: CGPoint(x: 4, y: 3), control: CGPoint(x: 4, y: 0))
                }
                .stroke(Color(hex: "FFB6C1"), lineWidth: 1)
                
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addQuadCurve(to: CGPoint(x: -4, y: 3), control: CGPoint(x: -4, y: 0))
                }
                .stroke(Color(hex: "FFB6C1"), lineWidth: 1)
            }
            .offset(y: -18)
            
            // 腮紅
            HStack(spacing: 20) {
                Circle()
                    .fill(Color(hex: "FFB6C1").opacity(0.5))
                    .frame(width: 8, height: 5)
                
                Circle()
                    .fill(Color(hex: "FFB6C1").opacity(0.5))
                    .frame(width: 8, height: 5)
            }
            .offset(y: -20)
            
            // 尾巴
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
                .offset(x: -30, y: 10)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 0)
            
            // 腳腳
            HStack(spacing: 15) {
                Ellipse()
                    .fill(Color.white)
                    .frame(width: 15, height: 10)
                
                Ellipse()
                    .fill(Color.white)
                    .frame(width: 15, height: 10)
            }
            .offset(y: 25)
        }
        .onAppear {
            if isAnimating {
                startAnimating()
            }
        }
    }
    
    private func startAnimating() {
        // 開始跳躍動畫
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            isHopping = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isHopping = false
            }
        }
        
        // 開始歪頭動畫
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            isHeadTilted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isHeadTilted = false
            }
        }
        
        // 開始眨眼動畫
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            eyeBlink = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                eyeBlink = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    BunnyView(isAnimating: true)
        .frame(width: 150, height: 150)
        .padding()
}
