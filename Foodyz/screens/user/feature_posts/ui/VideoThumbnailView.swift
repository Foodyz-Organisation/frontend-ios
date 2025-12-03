import SwiftUI
import AVFoundation

struct VideoThumbnailView: View {
    let videoUrl: URL
    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        VStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "video.slash")
                                    .foregroundColor(.white)
                            }
                        }
                    )
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        // Don't regenerate if we already have it
        guard thumbnail == nil else { return }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: videoUrl)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            
            do {
                let time = CMTime(seconds: 1, preferredTimescale: 60)
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    self.thumbnail = uiImage
                    self.isLoading = false
                }
            } catch {
                print("Error generating thumbnail: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}
