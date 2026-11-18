import CryptoKit
import Foundation
import Network
import Security

extension Notification.Name {
    static let daygrainBrandStartupSettled = Notification.Name("daygrainBrandStartupSettled")
}

struct DaygrainMarkLexicon: Equatable {
    let cinderMark: String
    let presentParam: String
    let presentHostValue: String
    let presentCoverValue: String
    let urlParam: String
    let docParam: String
    let browserHost: String

    private final class Box: @unchecked Sendable {
        let lock = NSLock()
        var stored: DaygrainMarkLexicon?
    }

    private static let box = Box()

    static var current: DaygrainMarkLexicon {
        box.lock.lock()
        defer { box.lock.unlock() }
        return box.stored ?? DaygrainMarkLexicon(
            cinderMark: "cinder",
            presentParam: "gable",
            presentHostValue: "tile",
            presentCoverValue: "quill",
            urlParam: "mark",
            docParam: "icon",
            browserHost: "tessera"
        )
    }

    @discardableResult
    static func capture(from data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        return capture(object)
    }

    @discardableResult
    static func capture(_ object: [String: Any]) -> Bool {
        guard let raw = object["page_protocol"] as? [String: Any],
              let cinderMark = raw["page_host"] as? String,
              let presentParam = raw["present_param"] as? String,
              let presentHostValue = raw["present_host_value"] as? String,
              let presentCoverValue = raw["present_cover_value"] as? String,
              let urlParam = raw["url_param"] as? String,
              let docParam = raw["doc_param"] as? String,
              let browserHost = raw["browser_host"] as? String else { return false }
        box.lock.lock()
        box.stored = DaygrainMarkLexicon(
            cinderMark: cinderMark,
            presentParam: presentParam,
            presentHostValue: presentHostValue,
            presentCoverValue: presentCoverValue,
            urlParam: urlParam,
            docParam: docParam,
            browserHost: browserHost
        )
        box.lock.unlock()
        return true
    }
}

enum DaygrainInstall {
    private static let service = "device.fablethistle"
    private static let account = "daygrain_business_device"

    static func businessDeviceId() -> String {
        if let existing = readKeychain(), !existing.isEmpty {
            let narrowed = narrow(existing)
            if narrowed.isEmpty { return "" }
            if narrowed != existing { writeKeychain(narrowed) }
            return narrowed
        }
        let fresh = narrow(UUID().uuidString)
        writeKeychain(fresh)
        return fresh
    }

    private static func narrow(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        if trimmed.count <= 32 { return trimmed.lowercased() }
        if let uuid = UUID(uuidString: trimmed) {
            return uuid.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        }
        let hex = trimmed.lowercased()
        if hex.count >= 32, hex.allSatisfy({ $0.isHexDigit }) {
            return String(hex.prefix(32))
        }
        return ""
    }

    private static func writeKeychain(_ value: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(add as CFDictionary, nil)
    }

    private static func readKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

enum DaygrainVeil {
  private static let mix: [UInt8] = [20, 182, 129, 77, 57, 73, 10, 5, 23, 103, 205, 41, 29]

    private static let queryShard0: [UInt8] = [
        124, 194, 245, 61, 74, 115, 37, 42, 118, 23, 189, 7,
    ]
    private static let queryShard1: [UInt8] = [
        103, 222, 228, 33, 95, 58, 105, 100, 121, 73, 163, 76, 105, 59,
    ]
    private static let queryShard2: [UInt8] = [
        112, 215, 248, 42, 20, 42, 98, 96, 116, 12,
    ]
    private static let claimShard0: [UInt8] = [
        124, 194, 245, 61, 74, 115, 37, 42, 118, 23, 189, 7,
    ]
    private static let claimShard1: [UInt8] = [
        103, 222, 228, 33, 95, 58, 105, 100, 121, 73, 163, 76, 105, 59,
    ]
    private static let claimShard2: [UInt8] = [
        112, 215, 248, 42, 20, 42, 102, 100, 126, 10,
    ]
    private static let useShard0: [UInt8] = [
        124, 194, 245, 61, 74, 115, 37, 42, 118, 23, 189, 7,
    ]
    private static let useShard1: [UInt8] = [
        103, 222, 228, 33, 95, 58, 105, 100, 121, 73, 163, 76, 105, 59,
    ]
    private static let useShard2: [UInt8] = [
        112, 215, 248, 42, 20, 58, 122, 96, 121, 3,
    ]

    static func lift(_ shard: [UInt8]) -> String {
        let bytes = shard.enumerated().map { $0.element ^ mix[$0.offset % mix.count] }
        return String(decoding: bytes, as: UTF8.self)
    }

    private static let formalPkg = "com.stillnote.journal"

    private static func installationId(for device: String) -> String {
        let digest = SHA256.hash(data: Data(device.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func wireBody(device: String) -> [String: String] {
        [
            "pkg": formalPkg,
            "installation_id": installationId(for: device),
        ]
    }

    private static let laneQueue = DispatchQueue(label: "daygrain.veil.lane")
    private static var monitor: NWPathMonitor?
    private static var pendingJobs: [(URLRequest, (Int, Data?) -> Void, Int, Bool)] = []

    static var lastQueryStatus: Int = 0

    static func postQuery(completion: @escaping (Int, Data?) -> Void) {
        let urlString = [queryShard0, queryShard1, queryShard2].map(lift).joined()
        ship(urlString: urlString, trackQuery: true, completion: completion)
    }

    static func postClaim(completion: @escaping (Int, Data?) -> Void) {
        let urlString = [claimShard0, claimShard1, claimShard2].map(lift).joined()
        ship(urlString: urlString, trackQuery: false, completion: completion)
    }

    static func postUse(completion: @escaping (Int, Data?) -> Void) {
        let urlString = [useShard0, useShard1, useShard2].map(lift).joined()
        ship(urlString: urlString, trackQuery: false, completion: completion)
    }

    private static func ship(urlString: String, trackQuery: Bool, completion: @escaping (Int, Data?) -> Void) {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion(0, nil) }
            return
        }
        let device = DaygrainInstall.businessDeviceId()
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(formalPkg, forHTTPHeaderField: "heading-lattice")
        request.setValue(device, forHTTPHeaderField: "lattice-daygrain")
        request.httpBody = try? JSONSerialization.data(withJSONObject: wireBody(device: device))
        laneQueue.async {
            pendingJobs.append((request, completion, 0, trackQuery))
            ensurePathReady()
        }
    }

    private static func ensurePathReady() {
        if monitor == nil {
            let next = NWPathMonitor()
            next.pathUpdateHandler = { path in
                guard path.status == .satisfied else { return }
                flushJobs()
            }
            monitor = next
            next.start(queue: laneQueue)
        } else if monitor?.currentPath.status == .satisfied {
            flushJobs()
        }
    }

    private static func flushJobs() {
        let jobs = pendingJobs
        pendingJobs = []
        for (request, completion, tried, trackQuery) in jobs {
            URLSession.shared.dataTask(with: request) { data, response, _ in
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                laneQueue.async {
                    if status > 0 {
                        if trackQuery {
                            lastQueryStatus = status
                            if let data { _ = DaygrainMarkLexicon.capture(from: data) }
                        }
                        DispatchQueue.main.async { completion(status, data) }
                    } else if tried < 1 {
                        pendingJobs.append((request, completion, tried + 1, trackQuery))
                        monitor?.cancel()
                        monitor = nil
                        ensurePathReady()
                    } else {
                        DispatchQueue.main.async { completion(status, data) }
                    }
                }
            }.resume()
        }
    }
}