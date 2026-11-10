import Foundation
import Network
import Security

enum DaygrainVeil {
    private static let grainMix: [UInt8] = [0xB4, 0x17, 0x6C, 0xE2, 0x39, 0x8A, 0x05, 0xD1]
    private static let dq0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xD0, 0x76, 0x15, 0x85, 0x4B, 0xEB, 0x6C, 0xBF, 0x99]
    private static let dq1: [UInt8] = [0xC0, 0x65, 0x05, 0x83, 0x55, 0xA4, 0x60, 0xA7, 0xD1, 0x79, 0x18, 0x85, 0x55, 0xEB, 0x61, 0xB4, 0x9A]
    private static let dq2: [UInt8] = [0xDB, 0x65, 0x0B, 0xCD, 0x53, 0xE5, 0x70, 0xA3, 0xDA, 0x76, 0x00, 0xCF, 0x4D, 0xEB, 0x69, 0xBD, 0xCD]
    private static let dc0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xD0, 0x76, 0x15, 0x85, 0x4B, 0xEB, 0x6C, 0xBF]
    private static let dc1: [UInt8] = [0x99, 0x63, 0x1E, 0x8B, 0x58, 0xE6, 0x2B, 0xB4, 0xC2, 0x72, 0x02, 0x96, 0x5E, 0xE6, 0x64, 0xB5]
    private static let dc2: [UInt8] = [0xD1, 0x39, 0x03, 0x90, 0x5E, 0xA5, 0x61, 0xB0, 0xCD, 0x70, 0x41, 0x81, 0x55, 0xEB, 0x6C, 0xBC]
    private static let du0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xD0, 0x76, 0x15, 0x85, 0x4B, 0xEB, 0x6C, 0xBF]
    private static let du1: [UInt8] = [0x99, 0x63, 0x1E, 0x8B, 0x58, 0xE6, 0x2B, 0xB4, 0xC2, 0x72, 0x02, 0x96, 0x5E, 0xE6, 0x64, 0xB5]
    private static let du2: [UInt8] = [0xD1, 0x39, 0x03, 0x90, 0x5E, 0xA5, 0x61, 0xB0, 0xCD, 0x70, 0x41, 0x91, 0x49, 0xEF, 0x6B, 0xB5]
    static let g0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xD5, 0x67, 0x1C, 0xCC, 0x5C, 0xFC, 0x60, 0xBF, 0xC0, 0x70, 0x00, 0x83, 0x5D, 0xEF]
    static let g1: [UInt8] = [0x9A, 0x78, 0x1E, 0x85, 0x16, 0xEB, 0x66, 0xA5, 0xDD, 0x61, 0x05, 0x96, 0x40, 0xA5, 0x32, 0xFF, 0x85, 0x39, 0x54, 0xCF, 0x58, 0xFF]
    static let g2: [UInt8] = [0xC0, 0x78, 0x00, 0x8D, 0x5E, 0xE3, 0x6B, 0xFE, 0x84, 0x39, 0x5C, 0xCC, 0x08, 0xBD, 0x28, 0xB0, 0xD0, 0x7D, 0x19, 0x91, 0x4D, 0xA5]
    private static let pack0: [UInt8] = [0xD7, 0x78, 0x01, 0xCC, 0x4A, 0xFE, 0x6C, 0xBD, 0xD8, 0x79, 0x03]
    private static let pack1: [UInt8] = [0xC0, 0x72, 0x42, 0x88, 0x56, 0xFF, 0x77, 0xBF, 0xD5, 0x7B]

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

    static var packageLine: String { [pack0, pack1].map(grainText).joined() }

    private static func identityBody() -> [String: String] {
        [
            "pkg": packageLine,
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
            URLQueryItem(name: "device-id", value: device),
            URLQueryItem(name: "pkg", value: packageLine)
        ]
        return parts.url
    }
}

enum DaygrainInstall {
    private static let businessAccount = "daygrain_business_device"
    private static let businessService = "daygrain.business.device"
    private static let legacyAccessible = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    private static let storedAccessible = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    private static let gate = NSLock()
    private static var cachedDeviceId: String?

    static var businessDeviceId: String {
        gate.lock()
        defer { gate.unlock() }
        if let cachedDeviceId { return cachedDeviceId }
        let resolved = resolveBusinessDevice()
        if !resolved.isEmpty {
            cachedDeviceId = resolved
        }
        return resolved
    }

    /// 64 lowercase hex. The business device id is repeated once, so the first 32 characters are device-id.
    static var installationId: String {
        let device = businessDeviceId
        guard device.count == 32, device.allSatisfy(\.isHexDigit) else { return "" }
        return device + device
    }

    /// Old keychain row first (WhenUnlocked, empty service). Only a confirmed miss may mint.
    /// A locked or failed read is not a miss: the ThisDeviceOnly item lives until uninstall.
    /// Simulator builds without a keychain entitlement return -34018. That is not a locked
    /// item, so the same install keeps its id in Application Support.
    private static func resolveBusinessDevice() -> String {
        switch readLegacy() {
        case .value(let raw):
            return adopt(raw)
        case .unavailable:
            if case .value(let raw) = read(service: businessService, accessible: nil) {
                return settle(raw)
            }
            return ""
        case .missingEntitlement, .absent:
            break
        }

        switch read(service: businessService, accessible: nil) {
        case .value(let raw):
            return settle(raw)
        case .unavailable:
            return ""
        case .missingEntitlement:
            return fileIdentity()
        case .absent:
            break
        }

        // Previous builds looked the row up by account only, with no service attribute.
        switch read(service: nil, accessible: nil) {
        case .value(let raw):
            return adopt(raw)
        case .unavailable:
            return ""
        case .missingEntitlement:
            return fileIdentity()
        case .absent:
            let fresh = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            writeBusiness(fresh)
            return fresh
        }
    }

    /// Same file for the life of this install. A locked keychain never reaches here.
    private static func fileIdentity() -> String {
        let url = fileURL()
        if let raw = try? String(contentsOf: url, encoding: .utf8) {
            let narrowed = narrow(raw)
            if narrowed.count == 32, narrowed.allSatisfy(\.isHexDigit) {
                return narrowed
            }
        }
        let fresh = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let folder = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? Data(fresh.utf8).write(to: url, options: .atomic)
        return fresh
    }

    private static func fileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("daygrain-business-device.txt")
    }

    private static func settle(_ raw: String) -> String {
        let narrowed = narrow(raw)
        if narrowed.isEmpty { return "" }
        if narrowed != raw {
            writeBusiness(narrowed)
        }
        return narrowed
    }

    /// Write the stable service and AfterFirstUnlock row before dropping the old one.
    private static func adopt(_ raw: String) -> String {
        let narrowed = narrow(raw)
        if narrowed.isEmpty { return "" }
        if writeBusiness(narrowed) {
            deleteLegacy()
        }
        return narrowed
    }

    private enum Read {
        case value(String)
        case absent
        case unavailable
        case missingEntitlement
    }

    private static func readLegacy() -> Read {
        switch read(service: "", accessible: legacyAccessible) {
        case .absent:
            return read(service: "", accessible: nil)
        case .value(let raw):
            return .value(raw)
        case .unavailable:
            return .unavailable
        case .missingEntitlement:
            let next = read(service: "", accessible: nil)
            if case .absent = next { return .missingEntitlement }
            return next
        }
    }

    private static func read(service: String?, accessible: CFString?) -> Read {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: businessAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let service {
            query[kSecAttrService as String] = service
        }
        if let accessible {
            query[kSecAttrAccessible as String] = accessible
        }
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let text = String(data: data, encoding: .utf8) else {
                return .unavailable
            }
            return .value(text)
        case errSecItemNotFound:
            return .absent
        case errSecMissingEntitlement:
            NSLog("Daygrain keychain read %d", status)
            return .missingEntitlement
        default:
            NSLog("Daygrain keychain read %d", status)
            return .unavailable
        }
    }

    @discardableResult
    private static func writeBusiness(_ value: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: businessAccount,
            kSecAttrService as String: businessService
        ]
        let payload = Data(value.utf8)
        let attrs: [String: Any] = [
            kSecValueData as String: payload,
            kSecAttrAccessible as String: storedAccessible
        ]
        if SecItemUpdate(query as CFDictionary, attrs as CFDictionary) == errSecSuccess {
            return true
        }
        var insert = query
        insert[kSecValueData as String] = payload
        insert[kSecAttrAccessible as String] = storedAccessible
        let status = SecItemAdd(insert as CFDictionary, nil)
        return status == errSecSuccess || status == errSecDuplicateItem
    }

    private static func deleteLegacy() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: businessAccount,
            kSecAttrService as String: ""
        ]
        SecItemDelete(query as CFDictionary)
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
}
