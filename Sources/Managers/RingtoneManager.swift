import AVFoundation
import Combine

// MARK: - Import Result
struct RingtoneImportResult {
    let sourceURL: URL
    let duration: Double
    let waveformSamples: [Float]
    let suggestedDisplayName: String
}

// MARK: - Ringtone Error
enum RingtoneError: LocalizedError {
    case noAudioTrack
    case exportFailed
    case readFailed(String)

    var errorDescription: String? {
        switch self {
        case .noAudioTrack:        return "無法讀取音訊軌道"
        case .exportFailed:        return "音訊匯出失敗"
        case .readFailed(let m):   return "讀取失敗：\(m)"
        }
    }
}

// MARK: - Ringtone Manager
class RingtoneManager: ObservableObject {
    @Published var isPlaying = false
    @Published var customRingtones: [RingtoneSelection] = []

    private var audioEngine: AVAudioEngine?
    private var tonePlayerNode: AVAudioPlayerNode?
    private var audioPlayer: AVAudioPlayer?
    private var alarmLoopTimer: Timer?

    private let soundsKey = "customRingtones"

    // MARK: - Sounds Directory
    static var soundsDirectory: URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let sounds = library.appendingPathComponent("Sounds")
        try? FileManager.default.createDirectory(at: sounds, withIntermediateDirectories: true)
        return sounds
    }

    var soundsDirectory: URL { RingtoneManager.soundsDirectory }

    init() {
        loadCustomRingtones()
    }

    // MARK: - Persistence
    private func saveCustomRingtones() {
        if let encoded = try? JSONEncoder().encode(customRingtones) {
            UserDefaults.standard.set(encoded, forKey: soundsKey)
        }
    }

    private func loadCustomRingtones() {
        if let data = UserDefaults.standard.data(forKey: soundsKey),
           let decoded = try? JSONDecoder().decode([RingtoneSelection].self, from: data) {
            customRingtones = decoded
        }
    }

    // MARK: - Waveform Generation
    func generateWaveform(for url: URL, sampleCount: Int = 200) async throws -> [Float] {
        let asset = AVURLAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = tracks.first else {
            return Array(repeating: 0.1, count: sampleCount)
        }

        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey:              Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey:     16,
            AVLinearPCMIsBigEndianKey:  false,
            AVLinearPCMIsFloatKey:      false,
            AVNumberOfChannelsKey:      1
        ]

        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        reader.add(output)

        guard reader.startReading() else {
            return Array(repeating: 0.1, count: sampleCount)
        }

        var allSamples: [Int16] = []

        while reader.status == .reading {
            guard let sampleBuffer = output.copyNextSampleBuffer() else { break }
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }

            let length = CMBlockBufferGetDataLength(blockBuffer)
            var data = Data(count: length)
            data.withUnsafeMutableBytes { ptr in
                _ = CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length,
                                               destination: ptr.baseAddress!)
            }
            data.withUnsafeBytes { rawPtr in
                let typed = rawPtr.bindMemory(to: Int16.self)
                allSamples.append(contentsOf: typed)
            }
            CMSampleBufferInvalidate(sampleBuffer)
        }

        guard !allSamples.isEmpty else {
            return Array(repeating: 0.1, count: sampleCount)
        }

        let chunkSize = max(1, allSamples.count / sampleCount)
        return (0..<sampleCount).map { i in
            let start = i * chunkSize
            let end   = min(start + chunkSize, allSamples.count)
            guard start < allSamples.count else { return Float(0.02) }
            let peak = allSamples[start..<end]
                .max(by: { abs($0) < abs($1) })
                .map { Float(abs($0)) / Float(Int16.max) } ?? 0
            return max(0.02, peak)
        }
    }

    // MARK: - Import Audio
    func importAudio(from url: URL) async throws -> RingtoneImportResult {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let asset    = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let waveform = try await generateWaveform(for: url)
        let name     = url.deletingPathExtension().lastPathComponent

        return RingtoneImportResult(
            sourceURL:            url,
            duration:             duration.seconds,
            waveformSamples:      waveform,
            suggestedDisplayName: name
        )
    }

    // MARK: - Trim & Export to CAF
    func trimAndExport(
        sourceURL: URL,
        startTime: Double,
        endTime:   Double,
        displayName: String
    ) async throws -> RingtoneSelection {
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessing { sourceURL.stopAccessingSecurityScopedResource() } }

        let asset  = AVURLAsset(url: sourceURL)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = tracks.first else { throw RingtoneError.noAudioTrack }

        let cafFileName = "\(UUID().uuidString).caf"
        let outputURL   = soundsDirectory.appendingPathComponent(cafFileName)

        // Read with time range
        let reader = try AVAssetReader(asset: asset)
        let startCM = CMTime(seconds: startTime, preferredTimescale: 44100)
        let endCM   = CMTime(seconds: endTime,   preferredTimescale: 44100)
        reader.timeRange = CMTimeRange(start: startCM, end: endCM)

        let readerSettings: [String: Any] = [
            AVFormatIDKey:                  Int(kAudioFormatLinearPCM),
            AVSampleRateKey:                44100.0,
            AVNumberOfChannelsKey:          2,
            AVLinearPCMBitDepthKey:         16,
            AVLinearPCMIsFloatKey:          false,
            AVLinearPCMIsBigEndianKey:      false,
            AVLinearPCMIsNonInterleaved:    false
        ]

        let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: readerSettings)
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)

        guard reader.startReading() else {
            throw RingtoneError.readFailed(reader.error?.localizedDescription ?? "unknown")
        }

        // Write to CAF
        let writerSettings: [String: Any] = [
            AVFormatIDKey:               Int(kAudioFormatLinearPCM),
            AVSampleRateKey:             44100.0,
            AVNumberOfChannelsKey:       2,
            AVLinearPCMBitDepthKey:      16,
            AVLinearPCMIsFloatKey:       false,
            AVLinearPCMIsBigEndianKey:   false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let interleavedFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 44100,
            channels: 2,
            interleaved: true
        )!

        let outputFile = try AVAudioFile(
            forWriting: outputURL,
            settings:   writerSettings,
            commonFormat: .pcmFormatInt16,
            interleaved: true
        )

        while reader.status == .reading {
            guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else { break }
            guard let blockBuffer  = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }

            let dataLength  = CMBlockBufferGetDataLength(blockBuffer)
            let frameCount  = AVAudioFrameCount(dataLength / (2 * MemoryLayout<Int16>.size))
            guard frameCount > 0 else { continue }

            guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: interleavedFormat,
                                                   frameCapacity: frameCount) else { continue }
            pcmBuffer.frameLength = frameCount

            if let dest = pcmBuffer.mutableAudioBufferList.pointee.mBuffers.mData {
                _ = CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0,
                                               dataLength: dataLength, destination: dest)
            }

            try outputFile.write(from: pcmBuffer)
            CMSampleBufferInvalidate(sampleBuffer)
        }

        if reader.status == .failed {
            throw RingtoneError.readFailed(reader.error?.localizedDescription ?? "unknown")
        }

        let selection = RingtoneSelection(
            type:              .custom,
            presetName:        PresetRingtone.classic.rawValue,
            customFileName:    cafFileName,
            customDisplayName: displayName
        )

        await MainActor.run {
            self.customRingtones.append(selection)
            self.saveCustomRingtones()
        }

        return selection
    }

    // MARK: - Preset Playback
    func playPreset(_ preset: PresetRingtone, loop: Bool = false) {
        stopPlayback()
        setupAudioSession()

        let sampleRate: Double = 44100
        let onFrames  = AVAudioFrameCount(sampleRate * preset.onDuration)
        let offFrames = AVAudioFrameCount(sampleRate * preset.offDuration)
        let total     = onFrames + offFrames

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: total),
              let channelData = buffer.floatChannelData?[0] else { return }

        buffer.frameLength = total

        let freq      = preset.frequency
        let harmonics = preset.harmonics

        for i in 0..<Int(onFrames) {
            let t        = Double(i) / sampleRate
            let attack   = min(1.0, Double(i)           / (sampleRate * 0.015))
            let release  = min(1.0, Double(Int(onFrames) - i) / (sampleRate * 0.015))
            let envelope = min(attack, release) * 0.5
            var sample   = 0.0
            for (hi, amplitude) in harmonics.enumerated() {
                sample += amplitude * sin(2.0 * Double.pi * freq * Double(hi + 1) * t)
            }
            channelData[i] = Float(sample * envelope / Double(harmonics.count))
        }
        for i in 0..<Int(offFrames) {
            channelData[Int(onFrames) + i] = 0
        }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            let options: AVAudioPlayerNodeBufferOptions = loop ? [.loops] : []
            player.scheduleBuffer(buffer, at: nil, options: options) { [weak self] in
                DispatchQueue.main.async { self?.isPlaying = false }
            }
            player.play()
            audioEngine      = engine
            tonePlayerNode   = player
            isPlaying        = true
        } catch {
            print("Preset playback error: \(error)")
        }
    }

    // MARK: - Custom File Playback
    func playCustom(fileName: String, loop: Bool = false) {
        stopPlayback()
        setupAudioSession()
        let fileURL = soundsDirectory.appendingPathComponent(fileName)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.numberOfLoops = loop ? -1 : 0
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Custom playback error: \(error)")
        }
    }

    // MARK: - Segment Preview
    func playSegment(url: URL, startTime: Double, endTime: Double) {
        stopPlayback()
        setupAudioSession()
        do {
            let player          = try AVAudioPlayer(contentsOf: url)
            player.currentTime  = startTime
            player.play()
            audioPlayer         = player
            isPlaying           = true
            let duration        = endTime - startTime
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.stopPlayback()
            }
        } catch {
            print("Segment playback error: \(error)")
        }
    }

    // MARK: - Alarm Looping Playback
    func startAlarmPlayback(for selection: RingtoneSelection) {
        stopPlayback()
        setupAudioSession()

        if selection.type == .custom, let fileName = selection.customFileName {
            playCustom(fileName: fileName, loop: true)
        } else {
            let preset = selection.preset ?? .classic
            playPreset(preset, loop: true)
        }
    }

    // MARK: - Stop
    func stopPlayback() {
        alarmLoopTimer?.invalidate()
        alarmLoopTimer = nil

        tonePlayerNode?.stop()
        audioEngine?.stop()
        audioPlayer?.stop()

        audioEngine    = nil
        tonePlayerNode = nil
        audioPlayer    = nil
        isPlaying      = false
    }

    // MARK: - Delete Custom
    func deleteCustomRingtone(_ selection: RingtoneSelection) {
        if let fileName = selection.customFileName {
            try? FileManager.default.removeItem(
                at: soundsDirectory.appendingPathComponent(fileName))
        }
        customRingtones.removeAll { $0 == selection }
        saveCustomRingtones()
    }

    // MARK: - Audio Session
    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
