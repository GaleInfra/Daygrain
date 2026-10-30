import Photos
import PhotosUI
import SwiftUI
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
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
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
