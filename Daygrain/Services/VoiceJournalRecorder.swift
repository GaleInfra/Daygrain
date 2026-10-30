import SwiftUI
import AVFoundation
import Speech

/// Permission helpers. Every request here is only called from a user tap
/// (never at launch / onAppear).
enum MediaAccess {
    enum State { case granted, denied }

    static func microphone() async -> State {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted: return .granted
        case .denied: return .denied
        default:
            let ok = await withCheckedContinuation { cont in session.requestRecordPermission { cont.resume(returning: $0) } }
            return ok ? .granted : .denied
        }
    }

    static func speech() async -> State {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return .granted
        case .notDetermined:
            let status = await withCheckedContinuation { cont in SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) } }
            return status == .authorized ? .granted : .denied
        default: return .denied
        }
    }

    static func camera() async -> State {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .granted
        case .notDetermined:
            let ok = await AVCaptureDevice.requestAccess(for: .video)
            return ok ? .granted : .denied
        default: return .denied
        }
    }

    @MainActor static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

/// Inline explanation + "Open Settings" shown when a permission is denied.
struct PermissionDeniedNote: View {
    let message: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(message, systemImage: "exclamationmark.circle").font(.caption).foregroundColor(Palette.secondary)
            Button("Open Settings") { MediaAccess.openSettings() }.font(.caption.weight(.semibold))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

@MainActor
final class VoiceJournalRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    enum Phase: Equatable { case idle, recording, paused, transcribing, finished, micDenied }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var transcript = ""
    @Published private(set) var speechDenied = false
    private(set) var fileURL: URL?
    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func start() async {
        guard await MediaAccess.microphone() == .granted else { phase = .micDenied; return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            guard recorder.record() else { deactivate(); return }
            self.recorder = recorder
            fileURL = url
            elapsed = 0
            phase = .recording
            startTimer()
        } catch {
            deactivate()
            phase = .idle
        }
    }

    func pause() {
        guard phase == .recording else { return }
        recorder?.pause(); timer?.invalidate(); phase = .paused
    }

    func resume() {
        guard phase == .paused else { return }
        recorder?.record(); startTimer(); phase = .recording
    }

    /// Stops recording, deactivates the audio session, then (on the user's
    /// "Done" tap) asks for speech recognition and transcribes on device when possible.
    func finish() async {
        recorder?.stop(); recorder = nil; timer?.invalidate()
        deactivate()
        guard let url = fileURL else { phase = .idle; return }
        phase = .transcribing
        guard await MediaAccess.speech() == .granted,
              let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US")) ?? SFSpeechRecognizer(),
              recognizer.isAvailable else {
            speechDenied = SFSpeechRecognizer.authorizationStatus() != .authorized
            phase = .finished
            return
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
        request.shouldReportPartialResults = false
        transcript = await withCheckedContinuation { cont in
            var resumed = false
            recognizer.recognitionTask(with: request) { result, error in
                guard !resumed else { return }
                if let result = result, result.isFinal { resumed = true; cont.resume(returning: result.bestTranscription.formattedString) }
                else if error != nil { resumed = true; cont.resume(returning: "") }
            }
        }
        phase = .finished
    }

    func cancel() {
        recorder?.stop(); recorder = nil; timer?.invalidate(); deactivate()
        if let url = fileURL { try? FileManager.default.removeItem(at: url) }
        fileURL = nil; phase = .idle
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.elapsed = self?.recorder?.currentTime ?? 0 }
        }
    }

    private func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

/// "Speak" sheet: record → pause/resume → done → transcript inserted into the note.
struct VoiceJournalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceJournalRecorder()
    /// (transcript, recorded audio file in tmp)
    let onComplete: (String, URL?) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 22) {
                Image(systemName: "mic.circle.fill").font(.system(size: 66)).foregroundColor(Palette.accent)
                Text(timeString(recorder.elapsed)).font(.system(size: 34, weight: .light, design: .rounded).monospacedDigit())
                switch recorder.phase {
                case .idle:
                    Button { Task { await recorder.start() } } label: { Label("Start recording", systemImage: "record.circle") }.buttonStyle(FilledButtonStyle())
                case .recording, .paused:
                    HStack(spacing: 12) {
                        Button { recorder.phase == .recording ? recorder.pause() : recorder.resume() } label: {
                            Label(recorder.phase == .recording ? "Pause" : "Resume", systemImage: recorder.phase == .recording ? "pause.fill" : "play.fill")
                        }.buttonStyle(QuietButtonStyle(tone: .honey))
                        Button { Task { await recorder.finish() } } label: { Label("Done", systemImage: "checkmark") }.buttonStyle(FilledButtonStyle(tone: .sage))
                    }
                case .transcribing:
                    ProgressView("Writing your words…")
                case .finished:
                    if recorder.speechDenied {
                        PermissionDeniedNote(message: "Speech recognition is off, so only the audio will be kept with this note.")
                    } else if !recorder.transcript.isEmpty {
                        Text(recorder.transcript).font(.body).foregroundColor(Palette.text).frame(maxWidth: .infinity, alignment: .leading).surface()
                    }
                    Button {
                        onComplete(recorder.transcript, recorder.fileURL); dismiss()
                    } label: { Label("Add to note", systemImage: "text.insert") }.buttonStyle(FilledButtonStyle())
                case .micDenied:
                    PermissionDeniedNote(message: "Microphone access is off. Turn it on in Settings to record a voice journal. You can still type your note.")
                }
                Spacer()
            }.padding(24).pageBackground()
                .navigationTitle("Voice journal").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { recorder.cancel(); dismiss() } } }
        }.navigationViewStyle(.stack)
    }

    private func timeString(_ t: TimeInterval) -> String { String(format: "%d:%02d", Int(t) / 60, Int(t) % 60) }
}

/// Playable / deletable list of voice attachments for one entry.
struct VoiceAttachmentsList: View {
    @EnvironmentObject private var store: JournalStore
    let entryID: UUID
    @State private var files: [URL] = []
    @State private var player: AVAudioPlayer?
    @State private var playing: URL?

    var body: some View {
        Group {
            if !files.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(title: "Voice journal", subtitle: "Saved only on this iPhone.")
                    ForEach(files, id: \.self) { url in
                        HStack {
                            Button { toggle(url) } label: {
                                Label(playing == url ? "Stop" : "Play recording", systemImage: playing == url ? "stop.fill" : "play.fill")
                            }
                            Spacer()
                            Button(role: .destructive) {
                                if playing == url { player?.stop(); playing = nil }
                                store.deleteAudio(url); reload()
                            } label: { Image(systemName: "trash") }.accessibilityLabel("Delete recording")
                        }.font(.subheadline)
                    }
                }.surface()
            }
        }.onAppear(perform: reload)
    }

    private func reload() { files = store.audioFiles(for: entryID) }

    private func toggle(_ url: URL) {
        if playing == url { player?.stop(); playing = nil; return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
        playing = player == nil ? nil : url
    }
}
