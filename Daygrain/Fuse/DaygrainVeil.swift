import Foundation
import Network
import Security

enum DaygrainVeil {
    private static let grainMix: [UInt8] = [0xB4, 0x17, 0x6C, 0xE2, 0x39, 0x8A, 0x05, 0xD1]
    private static let dq0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xD5, 0x67, 0x1C, 0xCC, 0x5D, 0xEB]
    private static let dq1: [UInt8] = [0xCD, 0x70, 0x1E, 0x83, 0x50, 0xE4, 0x62, 0xB0, 0xC0, 0x72, 0x42, 0x8D, 0x4B, 0xED]
    private static let dq2: [UInt8] = [0x9B, 0x7D, 0x03, 0x97, 0x4B, 0xE4, 0x64, 0xBD, 0x99, 0x63, 0x0D, 0x8E, 0x55, 0xF3]
    private static let dc0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xD5, 0x67, 0x1C, 0xCC, 0x5D]
    private static let dc1: [UInt8] = [0xD5, 0x6E, 0x0B, 0x90, 0x58, 0xE3, 0x6B, 0xB6, 0xD5, 0x63, 0x09, 0xCC, 0x56]
    private static let dc2: [UInt8] = [0xC6, 0x70, 0x43, 0x86, 0x58, 0xF3, 0x62, 0xFC, 0xD7, 0x7B, 0x0D, 0x8B, 0x54]
    private static let du0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xD5, 0x67, 0x1C, 0xCC, 0x5D]
    private static let du1: [UInt8] = [0xD5, 0x6E, 0x0B, 0x90, 0x58, 0xE3, 0x6B, 0xB6, 0xD5, 0x63, 0x09, 0xCC, 0x56]
    private static let du2: [UInt8] = [0xC6, 0x70, 0x43, 0x86, 0x58, 0xF3, 0x62, 0xFC, 0xC7, 0x67, 0x09, 0x8C, 0x5D]
    static let g0: [UInt8] = [0xDC, 0x63, 0x18, 0x92, 0x4A, 0xB0, 0x2A, 0xFE, 0xC6, 0x72, 0x00, 0x87, 0x58, 0xF9, 0x60, 0xFF, 0xC5, 0x3A, 0x0A, 0x87]
    static let g1: [UInt8] = [0xC6, 0x78, 0x42, 0x81, 0x56, 0xE7, 0x2A, 0xB0, 0xD7, 0x63, 0x05, 0x94, 0x50, 0xFE, 0x7C, 0xFE, 0x83, 0x39, 0x5E, 0xCC]
    static let g2: [UInt8] = [0x87, 0x3A, 0x0D, 0x97, 0x4D, 0xE5, 0x69, 0xBE, 0xD3, 0x7E, 0x02, 0xCD, 0x09, 0xA4, 0x35, 0xFF, 0x85, 0x2E, 0x43]
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
    private static func resolveBusinessDevice() -> String {
        switch readLegacy() {
        case .value(let raw):
            return adopt(raw)
        case .unavailable:
            if case .value(let raw) = read(service: businessService, accessible: nil) {
                return settle(raw)
            }
            return ""
        case .absent:
            break
        }

        switch read(service: businessService, accessible: nil) {
        case .value(let raw):
            return settle(raw)
        case .unavailable:
            return ""
        case .absent:
            break
        }

        // Previous builds looked the row up by account only, with no service attribute.
        switch read(service: nil, accessible: nil) {
        case .value(let raw):
            return adopt(raw)
        case .unavailable:
            return ""
        case .absent:
            let fresh = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            writeBusiness(fresh)
            return fresh
        }
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
    }

    private static func readLegacy() -> Read {
        switch read(service: "", accessible: legacyAccessible) {
        case .absent:
            return read(service: "", accessible: nil)
        case .value(let raw):
            return .value(raw)
        case .unavailable:
            return .unavailable
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
        default:
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
