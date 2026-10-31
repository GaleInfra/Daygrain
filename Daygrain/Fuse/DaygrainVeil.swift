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

    static var businessDeviceId: String {
        if let kept = readBusiness() {
            let narrowed = narrow(kept.value)
            if narrowed.isEmpty { return "" }
            let legacyRow = kept.service != businessService || isWhenUnlocked(kept.accessible)
            if narrowed != kept.value || kept.needsRewrite {
                rewrite(narrowed, dropLegacy: legacyRow)
            }
            return narrowed
        }
        let fresh = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        rewrite(fresh, dropLegacy: false)
        return fresh
    }

    /// 64 lowercase hex. The first 32 characters are businessDeviceId.
    static var installationId: String {
        let device = businessDeviceId
        guard device.count == 32 else { return "" }
        return device + device
    }

    private struct KeptDevice {
        var value: String
        var service: String?
        var accessible: String?

        var needsRewrite: Bool {
            if service != DaygrainInstall.businessService { return true }
            return DaygrainInstall.isWhenUnlocked(accessible)
        }
    }

    /// Reads omit kSecAttrAccessible. A WhenUnlocked row is copied onto the new attributes immediately.
    private static func readBusiness() -> KeptDevice? {
        if let current = copyBusiness(service: businessService) {
            return current
        }
        return copyBusiness(service: nil)
    }

    private static func copyBusiness(service named: String?) -> KeptDevice? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: businessAccount,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let named {
            query[kSecAttrService as String] = named
        }
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let row = item as? [String: Any],
              let data = row[kSecValueData as String] as? Data,
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return KeptDevice(
            value: text,
            service: row[kSecAttrService as String] as? String,
            accessible: accessibleName(row[kSecAttrAccessible as String])
        )
    }

    private static func accessibleName(_ raw: Any?) -> String? {
        if let name = raw as? String { return name }
        if let name = raw as? NSString { return name as String }
        return nil
    }

    private static func isWhenUnlocked(_ name: String?) -> Bool {
        name == (kSecAttrAccessibleWhenUnlocked as String)
            || name == (kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
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

    /// Persist under the new service first. Drop the empty-service row only after that write succeeds.
    private static func rewrite(_ value: String, dropLegacy: Bool) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: businessService,
            kSecAttrAccount as String: businessAccount
        ]
        let payload = Data(value.utf8)
        let attrs: [String: Any] = [
            kSecValueData as String: payload,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        var status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = payload
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = SecItemAdd(insert as CFDictionary, nil)
        }
        guard status == errSecSuccess || status == errSecDuplicateItem else { return }
        if dropLegacy {
            deleteLegacyService()
        }
    }

    /// Old rows have an empty service. Delete those persistent refs only, after the new row exists.
    private static func deleteLegacyService() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: businessAccount,
            kSecReturnAttributes as String: true,
            kSecReturnPersistentRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return }
        let rows = item as? [[String: Any]] ?? []
        for row in rows {
            let service = (row[kSecAttrService as String] as? String) ?? ""
            guard service.isEmpty, let persistent = row[kSecValuePersistentRef as String] else { continue }
            let removal: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecValuePersistentRef as String: persistent
            ]
            SecItemDelete(removal as CFDictionary)
        }
    }
}
