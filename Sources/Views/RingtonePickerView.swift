import SwiftUI

// MARK: - Ringtone Picker View
struct RingtonePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var ringtoneManager: RingtoneManager

    @Binding var selectedRingtone: RingtoneSelection

    @State private var showingFilePicker    = false
    @State private var importResult: RingtoneImportResult?
    @State private var showTrimmer          = false
    @State private var importError: String?
    @State private var showError            = false
    @State private var isImporting          = false

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

    var body: some View {
        NavigationView {
            ZStack {
                bgColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
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
                    .foregroundColor(Color.ghibleBarkBrown.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("確定") {
                        ringtoneManager.stopPlayback()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(accentColor)
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
            HStack(spacing: 8) {
                Image(systemName: "bell.fill")
                    .foregroundColor(accentColor)
                Text("內建鈴聲")
                    .font(GhibliTheme.Typography.heading(16))
                    .foregroundColor(textColor)
            }
            .padding(.bottom, 2)

            ForEach(PresetRingtone.allCases) { preset in
                presetRow(preset)
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

    private func presetRow(_ preset: PresetRingtone) -> some View {
        let isSelected = selectedRingtone.type == .preset
            && selectedRingtone.presetName == preset.rawValue

        return Button(action: {
            selectedRingtone = RingtoneSelection(type: .preset, presetName: preset.rawValue)
            ringtoneManager.playPreset(preset)
        }) {
            HStack(spacing: 14) {
                if ringtoneManager.isPlaying && isSelected {
                    Image(systemName: "waveform")
                        .font(.system(size: 16))
                        .foregroundColor(accentColor)
                } else {
                    Image(systemName: "play.circle")
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? accentColor : Color.ghibleBarkBrown.opacity(0.5))
                }

                Text(preset.displayName)
                    .font(GhibliTheme.Typography.body(15))
                    .foregroundColor(isSelected ? accentColor : textColor)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: GhibliTheme.Radius.sm)
                    .fill(isSelected ? accentColor.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GhibliTheme.Radius.sm)
                    .stroke(isSelected ? accentColor.opacity(0.4) : Color.ghibliWarmEarth.opacity(0.1), lineWidth: 1.2)
            )
        }
    }

    // MARK: - Custom Section
    private var customSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "music.note")
                    .foregroundColor(accentColor)
                Text("自訂鈴聲")
                    .font(GhibliTheme.Typography.heading(16))
                    .foregroundColor(textColor)
            }
            .padding(.bottom, 2)

            Button(action: { showingFilePicker = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("匯入音樂檔案")
                        .font(GhibliTheme.Typography.body(15))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
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

            Text("支援 MP3、WAV、M4A、AAC 格式，最長 30 秒")
                .font(GhibliTheme.Typography.caption(12))
                .foregroundColor(Color.ghibleBarkBrown.opacity(0.6))

            if ringtoneManager.customRingtones.isEmpty {
                Text("尚無自訂鈴聲")
                    .font(GhibliTheme.Typography.body(14))
                    .foregroundColor(Color.ghibleBarkBrown.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                ForEach(ringtoneManager.customRingtones, id: \.customFileName) { ringtone in
                    customRingtoneRow(ringtone)
                }
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
                            .foregroundColor(accentColor)
                    } else {
                        Image(systemName: "play.circle")
                            .font(.system(size: 16))
                            .foregroundColor(isSelected ? accentColor : Color.ghibleBarkBrown.opacity(0.5))
                    }

                    Text(ringtone.displayName)
                        .font(GhibliTheme.Typography.body(15))
                        .foregroundColor(isSelected ? accentColor : textColor)
                        .lineLimit(1)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accentColor)
                    }
                }
            }

            Button(action: {
                if selectedRingtone == ringtone {
                    selectedRingtone = .default
                }
                ringtoneManager.stopPlayback()
                ringtoneManager.deleteCustomRingtone(ringtone)
            }) {
                Image(systemName: "trash.circle")
                    .font(.system(size: 20))
                    .foregroundColor(Color.ghibliSunsetGlow.opacity(0.8))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.sm)
                .fill(isSelected ? accentColor.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.sm)
                .stroke(isSelected ? accentColor.opacity(0.4) : Color.ghibliWarmEarth.opacity(0.1), lineWidth: 1.2)
        )
    }

    // MARK: - Importing Overlay
    private var importingOverlay: some View {
        ZStack {
            Color.ghibliDeepForest.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.ghibliForestGreen))
                    .scaleEffect(1.5)
                Text("正在讀取音訊...")
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
