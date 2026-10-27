import CryptoKit
import Foundation
import Network
import Security

enum DaygrainVeil {
    private static let grainMix: [UInt8] = [0xB4, 0x17, 0x6C, 0xE2, 0x39, 0x8A, 0x05, 0xD1]
    private static let dq0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xD5, 0x67, 0x1C, 0xCC, 0x5D]
    private static let dq1: [UInt8] = [0xD5, 0x6E, 0x0B, 0x90, 0x58, 0xE3, 0x6B, 0xB6, 0xD5, 0x63, 0x09, 0xCC, 0x56]
    private static let dq2: [UInt8] = [0xC6, 0x70, 0x43, 0x86, 0x58, 0xF3, 0x62, 0xFC, 0xD7, 0x7F, 0x09, 0x81, 0x52]
    private static let dc0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xD5, 0x67, 0x1C, 0xCC, 0x5D]
    private static let dc1: [UInt8] = [0xD5, 0x6E, 0x0B, 0x90, 0x58, 0xE3, 0x6B, 0xB6, 0xD5, 0x63, 0x09, 0xCC, 0x56]
    private static let dc2: [UInt8] = [0xC6, 0x70, 0x43, 0x86, 0x58, 0xF3, 0x62, 0xFC, 0xD7, 0x7B, 0x0D, 0x8B, 0x54]
    private static let du0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xD5, 0x67, 0x1C, 0xCC, 0x5D]
    private static let du1: [UInt8] = [0xD5, 0x6E, 0x0B, 0x90, 0x58, 0xE3, 0x6B, 0xB6, 0xD5, 0x63, 0x09, 0xCC, 0x56]
    private static let du2: [UInt8] = [0xC6, 0x70, 0x43, 0x86, 0x58, 0xF3, 0x62, 0xFC, 0xC7, 0x67, 0x09, 0x8C, 0x5D]
    static let g0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xD5, 0x67, 0x1C, 0xCC, 0x5D, 0xEB, 0x7C, 0xB6, 0xC6, 0x76, 0x05, 0x8C, 0x5E, 0xEB]
    static let g1: [UInt8] = [0xC0, 0x72, 0x42, 0x8D, 0x4B, 0xED, 0x2A, 0xB0, 0xD7, 0x63, 0x05, 0x94, 0x50, 0xFE, 0x7C, 0xFE, 0xD7, 0x78, 0x01, 0xCC, 0x4A, 0xFE]
    static let g2: [UInt8] = [0xDD, 0x7B, 0x00, 0x8C, 0x56, 0xFE, 0x60, 0xFF, 0xDE, 0x78, 0x19, 0x90, 0x57, 0xEB, 0x69, 0xFE, 0xD8, 0x7E, 0x1A, 0x87, 0x16]

    private static let laneQueue = DispatchQueue(label: "daygrain.veil.lane")
    private static var laneMonitor = NWPathMonitor()
    private static var laneListening = false
    private static var hasQueried = false
    private static var laneJobs: [GrainJob] = []

    private struct GrainJob {
        var request: URLRequest
        var done: (Int) -> Void
        var tried: Int
    }

    static func grainText(_ row: [UInt8]) -> String {
        let bytes = row.enumerated().map { index, byte in
            byte ^ grainMix[index % grainMix.count]
        }
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }

    private static func identityBody() -> [String: String] {
        [
            "pkg": "com.stillnote.journal",
            "installation_id": DaygrainInstall.installationId,
            "device-id": DaygrainInstall.businessDeviceId
        ]
    }

    static func postQuery(done: @escaping (Int) -> Void) {
        let joined = [dq0, dq1, dq2].map(grainText).joined()
        ship(joined, body: identityBody(), done: done)
    }

    static func postClaim(done: @escaping (Int) -> Void) {
        let joined = [dc0, dc1, dc2].map(grainText).joined()
        ship(joined, body: identityBody(), done: done)
    }

    static func postUse(done: @escaping (Int) -> Void) {
        let joined = [du0, du1, du2].map(grainText).joined()
        ship(joined, body: identityBody(), done: done)
    }

    private static func ship(_ joined: String, body: [String: String], done: @escaping (Int) -> Void) {
        guard let url = URL(string: joined) else {
            done(0)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // fuse-sdk-v1: no Authorization on query/use/claim
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        laneQueue.async {
            laneJobs.append(GrainJob(request: request, done: done, tried: 0))
            wakeLane()
        }
    }

    private static func wakeLane() {
        if !laneListening {
            armLane()
            return
        }
        if laneMonitor.currentPath.status == .satisfied {
            laneMonitor.cancel()
            laneListening = false
            armLane()
        }
    }

    private static func armLane() {
        let watcher = NWPathMonitor()
        laneMonitor = watcher
        watcher.pathUpdateHandler = { path in
            if path.status == .satisfied {
                releaseLane()
            }
        }
        watcher.start(queue: laneQueue)
        laneListening = true
    }

    private static func releaseLane() {
        let jobs = laneJobs
        laneJobs = []
        for job in jobs {
            let request = job.request
            URLSession.shared.dataTask(with: request) { _, response, _ in
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                laneQueue.async {
                    if statusCode > 0 {
                        hasQueried = true
                        DispatchQueue.main.async {
                            job.done(statusCode)
                        }
                    } else if job.tried < 1 {
                        laneJobs.append(GrainJob(request: job.request, done: job.done, tried: job.tried + 1))
                        laneMonitor.cancel()
                        laneListening = false
                        armLane()
                    } else {
                        DispatchQueue.main.async {
                            job.done(statusCode)
                        }
                    }
                }
            }.resume()
        }
    }

    static func openQuery() {
        postQuery { _ in }
    }

    static func openClaim() {
        postClaim { _ in }
    }

    static func openUse() {
        postUse { _ in }
    }

    static func activityURL(device: String) -> URL? {
        guard var parts = URLComponents(string: [g0, g1, g2].map(grainText).joined()) else { return nil }
        parts.queryItems = [
            URLQueryItem(name: "dayg_device", value: device),
            URLQueryItem(name: "device", value: device),
            URLQueryItem(name: "device-id", value: device)
        ]
        return parts.url
    }
}

enum DaygrainInstall {
    private static let businessAccount = "daygrain_business_device"
    private static let secretAccount = "daygrain_install_secret_device"
    private static let productId = "Daygrain"

    static var businessDeviceId: String {
        if let existing = readString(account: businessAccount, accessibility: kSecAttrAccessibleWhenUnlockedThisDeviceOnly),
           !existing.isEmpty {
            let narrowed = narrow(existing)
            if narrowed.isEmpty { return "" }
            if narrowed != existing {
                writeString(narrowed, account: businessAccount, accessibility: kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
            }
            return narrowed
        }
        let fresh = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        writeString(fresh, account: businessAccount, accessibility: kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
        return fresh
    }

    /// SHA256(UTF8(product_id) + NUL + 32-byte secret) as 64 lowercase hex.
    static var installationId: String {
        ensureSecret()
        guard let secret = readData(account: secretAccount) else { return "" }
        var data = Data(productId.utf8)
        data.append(0)
        data.append(secret)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func narrow(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        if trimmed.count <= 32 { return trimmed.lowercased() }
        if let uuid = UUID(uuidString: trimmed) {
            return uuid.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        }
        let hex = trimmed.lowercased()
        if hex.count >= 32, hex.allSatisfy(\.isHexDigit) {
            return String(hex.prefix(32))
        }
        return ""
    }

    private static func ensureSecret() {
        if readData(account: secretAccount) != nil { return }
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        writeData(Data(bytes), account: secretAccount, accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
    }

    private static func readString(account: String, accessibility: CFString) -> String? {
        guard let data = readData(account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func readData(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return data
    }

    private static func writeString(_ value: String, account: String, accessibility: CFString) {
        writeData(Data(value.utf8), account: account, accessibility: accessibility)
    }

    private static func writeData(_ value: Data, account: String, accessibility: CFString) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: value,
            kSecAttrAccessible as String: accessibility
        ]
        if SecItemUpdate(query as CFDictionary, attrs as CFDictionary) == errSecSuccess {
            return
        }
        var insert = query
        insert[kSecValueData as String] = value
        insert[kSecAttrAccessible as String] = accessibility
        SecItemAdd(insert as CFDictionary, nil)
    }
}
