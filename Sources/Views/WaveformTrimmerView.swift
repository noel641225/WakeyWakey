import SwiftUI
import AVFoundation

// MARK: - Waveform Trimmer View
struct WaveformTrimmerView: View {
    @EnvironmentObject var ringtoneManager: RingtoneManager
    @Environment(\.dismiss) private var dismiss

    let importResult: RingtoneImportResult

    /// Called when the user confirms the trimmed segment.
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

    // MARK: Body
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "FFB6C1"), Color(hex: "E6E6FA")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
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
                    .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("確認") { confirmExport() }
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "FF6B6B"))
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
            Text("🏷️ 鈴聲名稱")
                .font(.headline)
                .foregroundColor(.white)

            TextField("鈴聲名稱", text: $displayName)
                .textFieldStyle(.roundedBorder)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }

    // MARK: - Waveform Section
    private var waveformSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("✂️ 選擇片段（最多 30 秒）")
                .font(.headline)
                .foregroundColor(.white)

            Text("拖曳白色控制點來選擇開始和結束位置")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Waveform
                    WaveformView(
                        samples:       importResult.waveformSamples,
                        startFraction: startFraction,
                        endFraction:   endFraction
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
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }

    // MARK: - Time Info Section
    private var timeInfoSection: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("開始")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(formatTime(startTime))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("時長")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(String(format: "%.1f 秒", selectedLength))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(selectedLength <= maxDuration ? .white : Color(hex: "FF6B6B"))
            }

            VStack(spacing: 4) {
                Text("結束")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(formatTime(endTime))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }

    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(spacing: 12) {
            Button(action: togglePreview) {
                HStack {
                    Image(systemName: ringtoneManager.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 28))
                    Text(ringtoneManager.isPlaying ? "停止試聽" : "試聽選段")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "FF6B6B"))
                )
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }

    // MARK: - Exporting Overlay
    private var exportingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Text("正在處理音訊...")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            .padding(40)
            .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
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

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        max(range.lowerBound, min(range.upperBound, self))
    }
}
