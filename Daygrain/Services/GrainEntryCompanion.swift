import AVFoundation
import Foundation
import Speech
import SwiftUI

enum DaygrainKeys {
    static var deepSeek: String { "" }
    static var stepFun: String { "" }
}

/// App Store 5.1.2(i) gate for third-party cloud AI (DeepSeek shape + StepFun TTS).
enum GrainAIConsent {
    static let currentVersion = 2

    private static let grantedKey = "grainbook.ai.consent.granted"
    private static let versionKey = "grainbook.ai.consent.version"
    /// Legacy imprint/shape flag without versioned disclosure.
    private static let legacyKey = "grainbook.entry.consent"

    static let deepSeekPrivacyURL = "https://cdn.deepseek.com/policies/en-US/deepseek-privacy-policy.html"
    /// Official English Open Platform privacy (API/TTS). Chinese consumer page: chat.stepfun.com/legal/privacy
    static let stepFunPrivacyURL = "https://platform.stepfun.ai/docs/en/agreement/userprivacy"
    static var appPrivacyURL: String { GrainLegalLinks.privacyPolicy }
    static var appTermsURL: String { GrainLegalLinks.userAgreement }
    static var appSupportURL: String { GrainLegalLinks.support }

    static var isAllowed: Bool {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: grantedKey) else { return false }
        return defaults.integer(forKey: versionKey) == currentVersion
    }

    /// Compatibility alias used by existing call sites.
    static var granted: Bool { isAllowed }

    static func grant() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: grantedKey)
        defaults.set(currentVersion, forKey: versionKey)
        defaults.removeObject(forKey: legacyKey)
    }

    static func revoke() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: grantedKey)
        defaults.removeObject(forKey: legacyKey)
    }
}

typealias GrainConsent = GrainAIConsent

/// Baserow 研发表协议（隐私 / 用户协议）+ 同源 Support；App 内 WebView 加载。
enum GrainLegalLinks {
    /// Baserow `隐私协议` (row 417)
    static let privacyPolicy = "https://pollen-notch-fieldwalk.pages.dev/privacy/"
    /// Baserow `用户协议` (row 417)
    static let userAgreement = "https://pollen-notch-fieldwalk.pages.dev/terms/"
    /// Same host Support page (sibling of privacy/terms)
    static let support = "https://pollen-notch-fieldwalk.pages.dev/support/"

    static func remoteURL(for document: String) -> URL? {
        switch document.lowercased() {
        case "privacy": return URL(string: privacyPolicy)
        case "terms": return URL(string: userAgreement)
        case "support": return URL(string: support)
        default: return nil
        }
    }
}

/// Shared App Store 5.1.2(i) disclosure for DeepSeek shaping + StepFun read-aloud.
struct GrainConsentFace: View {
    let onAllow: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Before Daygrain sends data to DeepSeek & StepFun")
                    .font(.system(.title2, design: .serif))
                    .foregroundColor(Palette.text)

                Text(
                    """
                    To suggest a journal page and (after you keep it) read it aloud, Daygrain uses third-party cloud AI:

                    • DeepSeek — receives the words on this entry and, if attached, one JPEG of the photo. Purpose: draft a title, notes, and place for your review. Nothing is kept until you confirm.

                    • StepFun — after you keep a page, may receive the page text only for text-to-speech. Local playback uses the returned audio.

                    Dictation audio stays on this iPhone (Apple on-device speech when available). Daygrain does not send your microphone recording to DeepSeek or StepFun.

                    Processing may occur outside your country, including in China, under each vendor’s policy.
                    """
                )
                .font(.subheadline)
                .foregroundColor(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)

                Button("Daygrain Privacy Policy") {
                    GrainPageLink.openInside(url: GrainAIConsent.appPrivacyURL)
                }
                .font(.subheadline.weight(.semibold))
                Button("DeepSeek Privacy Policy") {
                    GrainPageLink.openVendorPrivacy(GrainAIConsent.deepSeekPrivacyURL)
                }
                .font(.subheadline.weight(.semibold))
                Button("StepFun Privacy Policy") {
                    GrainPageLink.openVendorPrivacy(GrainAIConsent.stepFunPrivacyURL)
                }
                .font(.subheadline.weight(.semibold))

                Button("Allow DeepSeek & StepFun", action: onAllow)
                    .buttonStyle(FilledButtonStyle(tone: .sage))

                Button("Not now — keep it on this device", action: onNotNow)
                    .font(.subheadline)

                Text("You can revoke cloud AI sharing later in Settings.")
                    .font(.caption)
                    .foregroundColor(Palette.secondary)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .pageBackground()
    }
}

struct GrainProposal: Equatable {
    var title: String
    var notes: String
    var place: String
}

enum GrainCompanionFailure: Error {
    case notConfigured
    case unavailable
}

enum GrainJournalCompanion {
    static var configured: Bool {
        let key = DaygrainKeys.deepSeek.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && !key.hasPrefix("$(")
    }

    static func propose(notes: String, photoJPEG: Data?) async -> Result<GrainProposal, GrainCompanionFailure> {
        guard configured else { return .failure(.notConfigured) }
        let key = DaygrainKeys.deepSeek.trimmingCharacters(in: .whitespacesAndNewlines)
        var content: [[String: Any]] = [[
            "type": "text",
            "text": """
            Turn this journal moment into a page the writer can check.
            Reply with JSON only, no markdown: {"title":"","notes":"","place":""}
            Keep the writer's words. Do not invent a diagnosis or a place they did not mention.
            Moment:
            \(notes)
            """
        ]]
        if let photoJPEG, !photoJPEG.isEmpty {
            let encoded = photoJPEG.base64EncodedString()
            content.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(encoded)"]
            ])
        }
        var request = URLRequest(url: URL(string: "https://api.deepseek.com/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": "deepseek-v4-flash",
            "messages": [["role": "user", "content": content]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else { return .failure(.unavailable) }
            guard let proposal = GrainProposal.parse(data) else { return .failure(.unavailable) }
            return .success(proposal)
        } catch {
            return .failure(.unavailable)
        }
    }
}

extension GrainProposal {
    static func parse(_ data: Data) -> GrainProposal? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = root["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let text = message["content"] as? String else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonText = trimmed.hasPrefix("```")
            ? trimmed.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
            : trimmed
        guard let payload = jsonText.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: payload) as? [String: Any] else {
            return GrainProposal(title: "", notes: trimmed, place: "")
        }
        return GrainProposal(
            title: object["title"] as? String ?? "",
            notes: object["notes"] as? String ?? "",
            place: object["place"] as? String ?? ""
        )
    }
}

@MainActor
final class GrainEntryVoice: ObservableObject {
    @Published private(set) var speaking = false
    @Published private(set) var status = ""
    private var player: AVAudioPlayer?

    static var configured: Bool {
        let key = DaygrainKeys.stepFun.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && !key.hasPrefix("$(")
    }

    func read(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard GrainAIConsent.isAllowed else {
            status = "Cloud readout needs DeepSeek & StepFun permission. Allow it in Settings, or when you shape an entry."
            speaking = false
            return
        }
        guard Self.configured else {
            status = "Reading this entry aloud is not configured."
            speaking = false
            return
        }
        speaking = true
        status = "Reading this entry with StepFun"
        do {
            let audio = try await Self.synthesize(String(trimmed.prefix(1000)))
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            player = try AVAudioPlayer(data: audio)
            player?.play()
            status = "Reading this entry"
        } catch GrainCompanionFailure.notConfigured {
            status = "Reading this entry aloud is not configured."
        } catch {
            status = "This entry could not be read aloud."
        }
        speaking = player?.isPlaying == true
    }

    private static func synthesize(_ input: String) async throws -> Data {
        let key = DaygrainKeys.stepFun.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw GrainCompanionFailure.notConfigured }
        var request = URLRequest(url: URL(string: "https://api.stepfun.com/v1/audio/speech")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let payload: [String: Any] = [
            "model": "stepaudio-3-tts",
            "input": input,
            "voice": "wenrougongzi",
            "response_format": "mp3",
            "instruction": "Read this private journal entry slowly, as if sitting with the page. Warm and unhurried. Do not announce that you are reading."
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status), !data.isEmpty else { throw GrainCompanionFailure.unavailable }
        return data
    }
}

enum GrainSpeechError: Error {
    case speechDenied
    case microphoneDenied
    case unavailable
    case noSpeech
}

@MainActor
final class GrainSpeechBooth: ObservableObject {
    @Published private(set) var recording = false
    @Published private(set) var liveTranscript = ""
    @Published private(set) var level: Double = 0

    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var continuation: CheckedContinuation<String, Error>?
    private var partial = ""
    private var tapInstalled = false

    func dictate() async throws -> String {
        if recording { stop() }
        guard await Self.speechAllowed() else { throw GrainSpeechError.speechDenied }
        guard await Self.microphoneAllowed() else { throw GrainSpeechError.microphoneDenied }
        guard let recognizer = Self.recognizer() else { throw GrainSpeechError.unavailable }
        let transcript = try await capture(using: recognizer)
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw GrainSpeechError.noSpeech }
        return trimmed
    }

    func stop() {
        request?.endAudio()
        recording = false
        let text = partial.count >= liveTranscript.count ? partial : liveTranscript
        continuation?.resume(returning: text)
        continuation = nil
    }

    private static func speechAllowed() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private static func microphoneAllowed() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private static func recognizer() -> SFSpeechRecognizer? {
        let english = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        if let english, english.isAvailable { return english }
        return SFSpeechRecognizer()
    }

    private func capture(using recognizer: SFSpeechRecognizer) async throws -> String {
        tearDown()
        recording = true
        liveTranscript = ""
        partial = ""
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true)
        defer {
            tearDown()
            recording = false
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
        }
        let audio = AVAudioEngine()
        let input = audio.inputNode
        engine = audio
        var format = input.outputFormat(forBus: 0)
        if format.sampleRate <= 0 || format.channelCount <= 0 {
            format = input.inputFormat(forBus: 0)
        }
        guard format.sampleRate > 0, format.channelCount > 0 else { throw GrainSpeechError.unavailable }
        let recognition = SFSpeechAudioBufferRecognitionRequest()
        recognition.shouldReportPartialResults = true
        recognition.taskHint = .dictation
        recognition.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        request = recognition
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            task = recognizer.recognitionTask(with: recognition) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result {
                        let text = result.bestTranscription.formattedString
                        self.partial = text
                        self.liveTranscript = text
                        if result.isFinal { self.finish(text) }
                    } else if error != nil {
                        if !self.partial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            self.finish(self.partial)
                        } else {
                            self.fail(GrainSpeechError.unavailable)
                        }
                    }
                }
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                recognition.append(buffer)
            }
            tapInstalled = true
            audio.prepare()
            do {
                try audio.start()
            } catch {
                self.fail(GrainSpeechError.unavailable)
            }
        }
    }

    private func finish(_ text: String) {
        let continuation = self.continuation
        self.continuation = nil
        continuation?.resume(returning: text)
    }

    private func fail(_ error: Error) {
        let continuation = self.continuation
        self.continuation = nil
        continuation?.resume(throwing: error)
    }

    private func tearDown() {
        if tapInstalled, let engine {
            engine.inputNode.removeTap(onBus: 0)
        }
        tapInstalled = false
        if let engine, engine.isRunning { engine.stop() }
        engine = nil
        task?.cancel()
        task = nil
        request = nil
    }
}

enum GrainLegalPages {
    static func html(_ name: String) -> String {
        let heading = name == "terms" ? "Terms" : (name == "support" ? "Support" : "Privacy")
        let body: String
        switch name {
        case "terms":
            body = "Daygrain is a private journal you keep on this iPhone. You decide which moments to save, export, and delete."
        case "support":
            body = "Microphone, speech recognition, and photo library access are requested only when you dictate an entry or attach its photo. Support for an entry stays inside the app."
        default:
            body = "Journal notes and photos stay on this device until you allow optional cloud AI. DeepSeek may receive entry text and one photo to suggest a page; after you keep a page, StepFun may receive the page text for read-aloud. Declining keeps everything on this iPhone. Revoke anytime in Settings."
        }
        return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <title>\(heading)</title></head><body style="background:#24180F;color:#F4E7D4;font-family:-apple-system;margin:24px">
        <h1>\(heading)</h1><p>\(body)</p></body></html>
        """
    }
}
