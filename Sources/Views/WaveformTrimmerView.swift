import SwiftUI
import AVFoundation

// MARK: - Waveform Trimmer View
struct WaveformTrimmerView: View {
    @EnvironmentObject var ringtoneManager: RingtoneManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let importResult: RingtoneImportResult
    var onConfirm: (RingtoneSelection) -> Void

    // MARK: State
    @State private var startTime: Double
    @State private var endTime:   Double
    @State private var displayName: String
    @State private var isDraggingStart = false
    @State private var isDraggingEnd   = false
    @State private var isExporting     = false
    @State private var exportError: String?
    @State private var showError       = false

    private let maxDuration = 30.0
    private let minDuration =  1.0

    init(importResult: RingtoneImportResult, onConfirm: @escaping (RingtoneSelection) -> Void) {
        self.importResult = importResult
        self.onConfirm    = onConfirm
        let clampedEnd    = min(importResult.duration, 30.0)
        _startTime        = State(initialValue: 0)
        _endTime          = State(initialValue: clampedEnd)
        _displayName      = State(initialValue: importResult.suggestedDisplayName)
    }

    // MARK: Computed
    private var duration:       Double { importResult.duration }
    private var selectedLength: Double { endTime - startTime }
    private var startFraction:  Double { duration > 0 ? startTime / duration : 0 }
    private var endFraction:    Double { duration > 0 ? endTime   / duration : 1 }

    private var bgColor: Color {
        colorScheme == .dark ? Color.ghibliDarkBackground : Color.ghibliCream
    }
    private var cardColor: Color {
        colorScheme == .dark ? Color.ghibliDarkCard : Color.ghibliParchment
    }
    private var accentColor: Color {
        colorScheme == .dark ? Color.ghibliDarkPrimary : Color.ghibliForestGreen
    }
    private var textColor: Color {
        colorScheme == .dark ? Color.ghibliDarkText : Color.ghibliDeepForest
    }

    // MARK: Body
    var body: some View {
        NavigationView {
            ZStack {
                bgColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        nameSection
                        waveformSection
                        timeInfoSection
                        previewSection
                    }
                    .padding(20)
                }

                if isExporting {
                    exportingOverlay
                }
            }
            .navigationTitle("剪輯音樂")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        ringtoneManager.stopPlayback()
                        dismiss()
                    }
                    .foregroundColor(Color.ghibleBarkBrown.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("確認") { confirmExport() }
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                        .disabled(isExporting)
                }
            }
            .alert("匯出失敗", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(exportError ?? "未知錯誤")
            }
        }
    }

    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .foregroundColor(accentColor)
                Text("鈴聲名稱")
                    .font(GhibliTheme.Typography.heading(16))
                    .foregroundColor(textColor)
            }

            TextField("鈴聲名稱", text: $displayName)
                .font(GhibliTheme.Typography.body(15))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: GhibliTheme.Radius.sm)
                        .fill(bgColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: GhibliTheme.Radius.sm)
                                .stroke(Color.ghibliWarmEarth.opacity(0.25), lineWidth: 1)
                        )
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg)
                .fill(cardColor)
                .shadow(color: Color.ghibleBarkBrown.opacity(0.1), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg)
                .stroke(Color.ghibliWarmEarth.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Waveform Section
    private var waveformSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "scissors")
                    .foregroundColor(accentColor)
                Text("選擇片段（最多 30 秒）")
                    .font(GhibliTheme.Typography.heading(16))
                    .foregroundColor(textColor)
            }

            Text("拖曳控制點來選擇開始和結束位置")
                .font(GhibliTheme.Typography.caption(12))
                .foregroundColor(Color.ghibleBarkBrown.opacity(0.6))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    GhibliWaveformView(
                        samples:       importResult.waveformSamples,
                        startFraction: startFraction,
                        endFraction:   endFraction,
                        activeColor:   accentColor,
                        inactiveColor: Color.ghibleBarkBrown.opacity(0.25)
                    )

                    // Start handle touch area
                    Color.clear
                        .frame(width: 44, height: geo.size.height)
                        .offset(x: geo.size.width * CGFloat(startFraction) - 22)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    isDraggingStart = true
                                    let fraction = (drag.location.x / geo.size.width)
                                        .clamped(to: 0...1)
                                    let newTime  = fraction * duration
                                    startTime    = min(newTime, endTime - minDuration)
                                    startTime    = max(0, startTime)
                                    if endTime - startTime > maxDuration {
                                        endTime = startTime + maxDuration
                                    }
                                }
                                .onEnded { _ in isDraggingStart = false }
                        )

                    // End handle touch area
                    Color.clear
                        .frame(width: 44, height: geo.size.height)
                        .offset(x: geo.size.width * CGFloat(endFraction) - 22)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    isDraggingEnd = true
                                    let fraction  = (drag.location.x / geo.size.width)
                                        .clamped(to: 0...1)
                                    let newTime   = fraction * duration
                                    endTime       = max(newTime, startTime + minDuration)
                                    endTime       = min(duration, endTime)
                                    if endTime - startTime > maxDuration {
                                        startTime = endTime - maxDuration
                                    }
                                }
                                .onEnded { _ in isDraggingEnd = false }
                        )
                }
            }
            .frame(height: 80)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg)
                .fill(cardColor)
                .shadow(color: Color.ghibleBarkBrown.opacity(0.1), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg)
                .stroke(Color.ghibliWarmEarth.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Time Info Section
    private var timeInfoSection: some View {
        HStack(spacing: 20) {
            timeCell(label: "開始", value: formatTime(startTime))
            Divider().frame(height: 40).background(Color.ghibliWarmEarth.opacity(0.2))
            timeCell(
                label: "時長",
                value: String(format: "%.1f 秒", selectedLength),
                valueColor: selectedLength <= maxDuration ? accentColor : Color.ghibliSunsetGlow
            )
            Divider().frame(height: 40).background(Color.ghibliWarmEarth.opacity(0.2))
            timeCell(label: "結束", value: formatTime(endTime))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg)
                .fill(cardColor)
                .shadow(color: Color.ghibleBarkBrown.opacity(0.1), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg)
                .stroke(Color.ghibliWarmEarth.opacity(0.2), lineWidth: 1)
        )
    }

    private func timeCell(label: String, value: String, valueColor: Color? = nil) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(GhibliTheme.Typography.caption(12))
                .foregroundColor(Color.ghibleBarkBrown.opacity(0.6))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(valueColor ?? textColor)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(spacing: 12) {
            Button(action: togglePreview) {
                HStack(spacing: 10) {
                    Image(systemName: ringtoneManager.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 26))
                    Text(ringtoneManager.isPlaying ? "停止試聽" : "試聽選段")
                        .font(GhibliTheme.Typography.body(16))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: GhibliTheme.Radius.md)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, Color.ghibliDeepForest],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: accentColor.opacity(0.35), radius: 6, x: 0, y: 3)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg)
                .fill(cardColor)
                .shadow(color: Color.ghibleBarkBrown.opacity(0.1), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg)
                .stroke(Color.ghibliWarmEarth.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Exporting Overlay
    private var exportingOverlay: some View {
        ZStack {
            Color.ghibliDeepForest.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.ghibliForestGreen))
                    .scaleEffect(1.5)
                Text("正在處理音訊...")
                    .font(GhibliTheme.Typography.body(15))
                    .foregroundColor(Color.ghibliDeepForest)
                    .fontWeight(.semibold)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg)
                    .fill(Color.ghibliCream)
                    .shadow(color: Color.ghibleBarkBrown.opacity(0.2), radius: 16, x: 0, y: 6)
            )
        }
    }

    // MARK: - Actions
    private func togglePreview() {
        if ringtoneManager.isPlaying {
            ringtoneManager.stopPlayback()
        } else {
            ringtoneManager.playSegment(
                url: importResult.sourceURL,
                startTime: startTime,
                endTime:   endTime
            )
        }
    }

    private func confirmExport() {
        ringtoneManager.stopPlayback()
        isExporting = true
        let name = displayName.isEmpty ? importResult.suggestedDisplayName : displayName

        Task {
            do {
                let selection = try await ringtoneManager.trimAndExport(
                    sourceURL:   importResult.sourceURL,
                    startTime:   startTime,
                    endTime:     endTime,
                    displayName: name
                )
                await MainActor.run {
                    isExporting = false
                    onConfirm(selection)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                    showError   = true
                }
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Ghibli Waveform View
private struct GhibliWaveformView: View {
    let samples: [Float]
    let startFraction: Double
    let endFraction: Double
    var activeColor: Color = Color.ghibliForestGreen
    var inactiveColor: Color = Color.ghibleBarkBrown.opacity(0.25)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let count = max(samples.count, 1)
            let barWidth = w / CGFloat(count)
            let startX = w * CGFloat(startFraction)
            let endX   = w * CGFloat(endFraction)

            ZStack(alignment: .leading) {
                // Background parchment track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.ghibliParchment.opacity(0.5))
                    .frame(height: h)

                // Waveform bars
                Canvas { ctx, size in
                    for (i, sample) in samples.enumerated() {
                        let x = CGFloat(i) * barWidth
                        let barH = CGFloat(max(sample, 0.02)) * size.height * 0.9
                        let rect = CGRect(
                            x: x + barWidth * 0.15,
                            y: (size.height - barH) / 2,
                            width: barWidth * 0.7,
                            height: barH
                        )
                        let inSelected = x >= startX - barWidth && x <= endX
                        let color = inSelected ? activeColor : inactiveColor
                        ctx.fill(
                            Path(roundedRect: rect, cornerRadius: barWidth * 0.35),
                            with: .color(color)
                        )
                    }
                }

                // Selection region overlay
                Rectangle()
                    .fill(activeColor.opacity(0.08))
                    .frame(width: max(0, CGFloat(endFraction - startFraction) * w))
                    .offset(x: CGFloat(startFraction) * w)

                // Start handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.ghibliMeadowGold)
                    .frame(width: 3, height: h + 8)
                    .offset(x: CGFloat(startFraction) * w - 1.5, y: -4)

                // End handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.ghibliMeadowGold)
                    .frame(width: 3, height: h + 8)
                    .offset(x: CGFloat(endFraction) * w - 1.5, y: -4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        max(range.lowerBound, min(range.upperBound, self))
    }
}
