import Foundation

extension Data {
    func dataURI(mimeType: String = "image/jpeg") -> String {
        "data:\(mimeType);base64,\(self.base64EncodedString())"
    }
}
