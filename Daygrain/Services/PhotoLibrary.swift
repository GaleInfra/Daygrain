import SwiftUI
import PhotosUI
import Photos
import UniformTypeIdentifiers

struct PendingPhoto: Identifiable {
    let id: String
    let data: Data
    let image: UIImage

    init?(image: UIImage) {
        guard let data = PhotoProcessor.jpeg(from: image), let normalized = UIImage(data: data) else { return nil }
        self.id = UUID().uuidString
        self.data = data
        self.image = normalized
    }
}

enum PhotoProcessor {
    static func jpeg(from image: UIImage) -> Data? {
        let maximum: CGFloat = 1_800
        let scale = min(1, maximum / max(image.size.width, image.size.height))
        let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let result = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return result.jpegData(compressionQuality: 0.82)
    }
}

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let limit: Int
    let onComplete: ([UIImage], Int) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = max(1, limit)
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onComplete: ([UIImage], Int) -> Void
        init(onComplete: @escaping ([UIImage], Int) -> Void) { self.onComplete = onComplete }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else { onComplete([], 0); return }
            let group = DispatchGroup()
            let lock = NSLock()
            var images: [Int: UIImage] = [:]
            for (index, result) in results.enumerated() {
                guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        lock.lock()
                        images[index] = image
                        lock.unlock()
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                self.onComplete(images.keys.sorted().compactMap { images[$0] }, results.count - images.count)
            }
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .plainText] }
    var data: Data

    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw JournalError.invalidBackup }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct ReadableDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var data = Data()
    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw JournalError.invalidBackup }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

/// System camera for "Take a photo" in the entry editor.
/// Camera permission is checked by the caller on the user's tap (MediaAccess.camera()).
struct CameraPicker: UIViewControllerRepresentable {
    let onComplete: (UIImage?) -> Void

    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onComplete: (UIImage?) -> Void
        init(onComplete: @escaping (UIImage?) -> Void) { self.onComplete = onComplete }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            onComplete(info[.originalImage] as? UIImage)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onComplete(nil)
        }
    }
}

/// "Save to Photos": renders a journal moment card and writes it with add-only access,
/// requested only when the user taps Save to Photos.
@MainActor
enum MomentCardSaver {
    enum Outcome { case saved, denied, failed }

    static func render(_ entry: JournalEntry, tags: [EmotionTag], photo: UIImage?) -> UIImage {
        let size = CGSize(width: 1080, height: 1350)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: 1, green: 0.988, blue: 0.969, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            var y: CGFloat = 80
            if let photo = photo {
                let rect = CGRect(x: 80, y: y, width: 920, height: 620)
                context.cgContext.saveGState()
                UIBezierPath(roundedRect: rect, cornerRadius: 36).addClip()
                let scale = max(rect.width / photo.size.width, rect.height / photo.size.height)
                let drawSize = CGSize(width: photo.size.width * scale, height: photo.size.height * scale)
                photo.draw(in: CGRect(x: rect.midX - drawSize.width / 2, y: rect.midY - drawSize.height / 2, width: drawSize.width, height: drawSize.height))
                context.cgContext.restoreGState()
                y += 660
            }
            let ink = UIColor(red: 0.29, green: 0.22, blue: 0.18, alpha: 1)
            let soft = UIColor(red: 0.48, green: 0.41, blue: 0.35, alpha: 1)
            func draw(_ text: String, font: UIFont, color: UIColor, height: CGFloat) {
                (text as NSString).draw(with: CGRect(x: 80, y: y, width: 920, height: height), options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: [.font: font, .foregroundColor: color], context: nil)
                y += height
            }
            draw(EnglishDate.string(entry.date, template: "MMMM d yyyy"), font: .systemFont(ofSize: 34, weight: .medium), color: soft, height: 56)
            draw(entry.title, font: UIFont(name: "Georgia", size: 60) ?? .systemFont(ofSize: 60), color: ink, height: 160)
            if !tags.isEmpty { draw(tags.map(\.name).joined(separator: " · "), font: .systemFont(ofSize: 34, weight: .semibold), color: soft, height: 60) }
            let summary = entry.notes.isEmpty ? entry.observations.map(\.text).filter { !$0.isEmpty }.joined(separator: " ") : entry.notes
            if !summary.isEmpty { draw(summary, font: .systemFont(ofSize: 36), color: ink, height: max(0, 1250 - y)) }
            ("Daygrain" as NSString).draw(at: CGPoint(x: 80, y: 1270), withAttributes: [.font: UIFont.systemFont(ofSize: 28, weight: .semibold), .foregroundColor: soft])
        }
    }

    static func save(_ entry: JournalEntry, store: JournalStore) async -> Outcome {
        let photo = entry.photoIDs.first.flatMap { store.image(for: $0) }
        return await save(render(entry, tags: store.tags(for: entry), photo: photo))
    }

    static func message(_ outcome: Outcome) -> String {
        switch outcome {
        case .saved: return "Saved to Photos."
        case .denied: return "Photo library access is off. Turn on \"Add Photos Only\" for Daygrain in Settings to save moment cards."
        case .failed: return "The moment card could not be saved. Please try again."
        }
    }

    static func save(_ image: UIImage) async -> Outcome {
        var status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined { status = await PHPhotoLibrary.requestAuthorization(for: .addOnly) }
        guard status == .authorized || status == .limited else { return .denied }
        return await withCheckedContinuation { cont in
            PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAsset(from: image) }) { ok, _ in
                cont.resume(returning: ok ? .saved : .failed)
            }
        }
    }
}
