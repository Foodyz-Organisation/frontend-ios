import UIKit
import ImageIO

class ImageCompressor {
    private static let maxDimension: CGFloat = 1920
    private static let targetSizeKB = 800
    private static let minQuality: CGFloat = 0.2
    
    /// Compress image to base64 string under 800 KB
    /// - Parameters:
    ///   - image: UIImage to compress
    /// - Returns: Base64 string with data URI prefix
    static func compressImageToBase64(_ image: UIImage) throws -> String {
        print("🔄 Starting image compression - Original size: \(Int(image.size.width))x\(Int(image.size.height))")
        
        // Step 1: Resize first (faster than fixing orientation on large images)
        let resizedImage = resizeIfNeeded(image)
        
        // Step 2: Fix orientation on smaller image (much faster)
        let orientedImage = resizedImage.fixedOrientation()
        
        // Step 3: Compress with quality adjustment
        let compressedData = try compressToTargetSize(orientedImage)
        
        // Step 4: Convert to base64
        let base64String = compressedData.base64EncodedString(options: .lineLength64Characters)
        let finalSizeKB = compressedData.count / 1024
        print("✅ Compression complete! Final size: \(finalSizeKB) KB")
        
        return "data:image/jpeg;base64,\(base64String)"
    }
    
    /// Resize image if dimensions exceed max
    private static func resizeIfNeeded(_ image: UIImage) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        
        // Check if resize is needed
        if width <= maxDimension && height <= maxDimension {
            print("📐 No resize needed: \(width)x\(height)")
            return image
        }
        
        // Calculate new dimensions maintaining aspect ratio
        let ratio = width > height ? maxDimension / width : maxDimension / height
        let newWidth = width * ratio
        let newHeight = height * ratio
        
        print("📐 Resizing from \(width)x\(height) to \(newWidth)x\(newHeight)")
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    /// Compress image to meet target size
    private static func compressToTargetSize(_ image: UIImage) throws -> Data {
        // Binary search for optimal quality (faster than linear search)
        var lowQuality: CGFloat = minQuality
        var highQuality: CGFloat = 0.85
        var bestData: Data?
        var bestQuality: CGFloat = 0.85
        
        // First, try high quality
        if let data = image.jpegData(compressionQuality: highQuality), data.count <= targetSizeKB * 1024 {
            print("🗜️ Quality \(Int(highQuality * 100))%: \(data.count / 1024) KB - Success!")
            return data
        }
        
        // Binary search for optimal quality
        var attempts = 0
        let maxAttempts = 10 // Prevent infinite loops
        
        while attempts < maxAttempts && highQuality - lowQuality > 0.05 {
            let midQuality = (lowQuality + highQuality) / 2.0
            attempts += 1
            
            guard let data = image.jpegData(compressionQuality: midQuality) else {
                throw NSError(domain: "ImageCompressor", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }
            
            let sizeKB = data.count / 1024
            print("🗜️ Attempt \(attempts): Quality \(Int(midQuality * 100))% = \(sizeKB) KB")
            
            if data.count <= targetSizeKB * 1024 {
                // This quality works, try higher
                bestData = data
                bestQuality = midQuality
                lowQuality = midQuality
            } else {
                // Too large, try lower quality
                highQuality = midQuality
            }
        }
        
        // If we found a good quality, use it
        if let data = bestData {
            print("✅ Compression complete! Quality: \(Int(bestQuality * 100))%, Size: \(data.count / 1024) KB")
            return data
        }
        
        // Fallback: use the lowest quality
        guard let fallbackData = image.jpegData(compressionQuality: minQuality) else {
            throw NSError(domain: "ImageCompressor", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        print("⚠️ Using minimum quality: \(Int(minQuality * 100))%, Size: \(fallbackData.count / 1024) KB")
        return fallbackData
    }
}

// MARK: - UIImage Extension for Orientation Fix
extension UIImage {
    /// Fix image orientation based on EXIF data
    func fixedOrientation() -> UIImage {
        // If orientation is already up, return as is
        if imageOrientation == .up {
            return self
        }
        
        // Calculate proper transform
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
            
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        default:
            break
        }
        
        // Draw the image
        guard let cgImage = self.cgImage else { return self }
        guard let colorSpace = cgImage.colorSpace else { return self }
        
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else { return self }
        
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let newCGImage = context.makeImage() else { return self }
        return UIImage(cgImage: newCGImage, scale: 1, orientation: .up)
    }
}

