import UIKit

struct FileWithMime {
    let url: URL
    let mimeType: String
}

class FileUtil {
    
    /// Converts UIImage to temporary file URL with MIME type for multipart upload
    static func createFile(from image: UIImage, fileName: String = "image.jpg") -> FileWithMime? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        do {
            try imageData.write(to: fileURL)
            return FileWithMime(url: fileURL, mimeType: "image/jpeg")
        } catch {
            print("FileUtil error: \(error)")
            return nil
        }
    }
    
    /// If you need to use local file URL directly
    static func createFile(from url: URL, mimeType: String = "application/octet-stream") -> FileWithMime {
        return FileWithMime(url: url, mimeType: mimeType)
    }
}
