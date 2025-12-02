import SwiftUI
import UIKit

struct AvatarView: View {
    let avatarURL: String?
    let size: CGFloat
    let fallback: String?

    var body: some View {
        content
            .frame(width: size, height: size)
            .clipShape(Circle())
    }

    @ViewBuilder
    private var content: some View {
        if let image = decodedInlineImage(from: avatarURL) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let url = remoteURL(from: avatarURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failure:
                    placeholder
                case .success(let image):
                    image.resizable().scaledToFill()
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(AppColors.primary.opacity(0.15))
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundColor(AppColors.primary)
            )
    }

    private var initials: String {
        guard let fallback, !fallback.isEmpty else { return "?" }
        let parts = fallback.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.map { String($0) }.joined().uppercased()
    }

    private func decodedInlineImage(from dataString: String?) -> UIImage? {
        guard let dataString, !dataString.isEmpty else { return nil }
        let cleaned: String
        if let commaIndex = dataString.firstIndex(of: ",") {
            cleaned = String(dataString[dataString.index(after: commaIndex)...])
        } else {
            cleaned = dataString
        }
        guard let data = Data(base64Encoded: cleaned) else { return nil }
        return UIImage(data: data)
    }

    private func remoteURL(from urlString: String?) -> URL? {
        guard let urlString, urlString.hasPrefix("http"), let url = URL(string: urlString) else { return nil }
        return url
    }
}
