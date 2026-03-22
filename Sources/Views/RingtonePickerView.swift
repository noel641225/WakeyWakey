import SwiftUI

// MARK: - Ringtone Picker View
struct RingtonePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var ringtoneManager: RingtoneManager

    @Binding var selectedRingtone: RingtoneSelection

    @State private var showingFilePicker    = false
    @State private var importResult: RingtoneImportResult?
    @State private var showTrimmer          = false
    @State private var importError: String?
    @State private var showError            = false
    @State private var isImporting          = false

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
                        presetSection
                        customSection
                    }
                    .padding(20)
                }

                if isImporting {
                    importingOverlay
                }
            }
            .navigationTitle("選擇鈴聲")
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
                    Button("確定") {
                        ringtoneManager.stopPlayback()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "FF6B6B"))
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.audio, .mp3, .wav, .aiff],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showTrimmer) {
                if let result = importResult {
                    WaveformTrimmerView(importResult: result) { selection in
                        selectedRingtone = selection
                    }
                    .environmentObject(ringtoneManager)
                }
            }
            .alert("匯入失敗", isPresented: $showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(importError ?? "無法讀取音訊檔案")
            }
        }
    }

    // MARK: - Preset Section
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔔 內建鈴聲")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(PresetRingtone.allCases) { preset in
                presetRow(preset)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }

    private func presetRow(_ preset: PresetRingtone) -> some View {
        let isSelected = selectedRingtone.type == .preset
            && selectedRingtone.presetName == preset.rawValue

        return Button(action: {
            selectedRingtone = RingtoneSelection(type: .preset, presetName: preset.rawValue)
            ringtoneManager.playPreset(preset)
        }) {
            HStack(spacing: 14) {
                // Play indicator
                if ringtoneManager.isPlaying && isSelected {
                    Image(systemName: "waveform")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "FF6B6B"))
                        .opacity(ringtoneManager.isPlaying ? 1 : 0.5)
                } else {
                    Image(systemName: "play.circle")
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? Color(hex: "FF6B6B") : .gray)
                }

                Text(preset.displayName)
                    .foregroundColor(isSelected ? .white : Color(.label))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "FF6B6B"))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "FF6B6B").opacity(0.2) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "FF6B6B") : Color.clear, lineWidth: 1.5)
            )
        }
    }

    // MARK: - Custom Section
    private var customSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎵 自訂鈴聲")
                .font(.headline)
                .foregroundColor(.white)

            // Import button
            Button(action: { showingFilePicker = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("匯入音樂檔案")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "FF6B6B"))
                )
            }

            Text("支援 MP3、WAV、M4A、AAC 格式，最長 30 秒")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            if ringtoneManager.customRingtones.isEmpty {
                Text("尚無自訂鈴聲")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                ForEach(ringtoneManager.customRingtones, id: \.customFileName) { ringtone in
                    customRingtoneRow(ringtone)
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
    }

    private func customRingtoneRow(_ ringtone: RingtoneSelection) -> some View {
        let isSelected = selectedRingtone == ringtone

        return HStack(spacing: 14) {
            Button(action: {
                selectedRingtone = ringtone
                if let fileName = ringtone.customFileName {
                    ringtoneManager.playCustom(fileName: fileName)
                }
            }) {
                HStack(spacing: 14) {
                    if ringtoneManager.isPlaying && isSelected {
                        Image(systemName: "waveform")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "FF6B6B"))
                            .opacity(ringtoneManager.isPlaying ? 1 : 0.5)
                    } else {
                        Image(systemName: "play.circle")
                            .font(.system(size: 16))
                            .foregroundColor(isSelected ? Color(hex: "FF6B6B") : .gray)
                    }

                    Text(ringtone.displayName)
                        .foregroundColor(isSelected ? .white : Color(.label))
                        .lineLimit(1)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "FF6B6B"))
                    }
                }
            }

            // Delete button
            Button(action: {
                if selectedRingtone == ringtone {
                    selectedRingtone = .default
                }
                ringtoneManager.stopPlayback()
                ringtoneManager.deleteCustomRingtone(ringtone)
            }) {
                Image(systemName: "trash.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color(hex: "FF6B6B").opacity(0.2) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color(hex: "FF6B6B") : Color.clear, lineWidth: 1.5)
        )
    }

    // MARK: - Importing Overlay
    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Text("正在讀取音訊...")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            .padding(40)
            .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
        }
    }

    // MARK: - File Import Handler
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importError = error.localizedDescription
            showError   = true

        case .success(let urls):
            guard let url = urls.first else { return }
            isImporting = true

            Task {
                do {
                    let result = try await ringtoneManager.importAudio(from: url)
                    await MainActor.run {
                        isImporting  = false
                        importResult = result
                        showTrimmer  = true
                    }
                } catch {
                    await MainActor.run {
                        isImporting  = false
                        importError  = error.localizedDescription
                        showError    = true
                    }
                }
            }
        }
    }
}

#Preview {
    RingtonePickerView(selectedRingtone: .constant(.default))
        .environmentObject(RingtoneManager())
}
