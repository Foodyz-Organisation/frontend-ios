import SwiftUI
import PhotosUI
import AVFoundation

/// Represents selected media from the photo picker
struct SelectedMedia: Identifiable {
    let id = UUID()
    let data: Data
    let isVideo: Bool
    let thumbnail: UIImage?
}

/// SwiftUI wrapper for PHPickerViewController
struct MediaPicker: UIViewControllerRepresentable {
    @Binding var selectedMedia: [SelectedMedia]
    @Environment(\.presentationMode) var presentationMode
    
    var mediaTypes: [PHPickerFilter] = [.images, .videos]
    var selectionLimit: Int = 1
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: mediaTypes)
        configuration.selectionLimit = selectionLimit
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MediaPicker
        
        init(_ parent: MediaPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard !results.isEmpty else { return }
            
            let group = DispatchGroup()
            var selectedMedia: [SelectedMedia] = []
            
            for result in results {
                group.enter()
                
                let itemProvider = result.itemProvider
                
                // Check if it's a video
                if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                        defer { group.leave() }
                        
                        guard let url = url, error == nil else {
                            print("Error loading video: \(error?.localizedDescription ?? "unknown")")
                            return
                        }
                        
                        do {
                            let data = try Data(contentsOf: url)
                            let thumbnail = self.generateVideoThumbnail(url: url)
                            
                            DispatchQueue.main.async {
                                selectedMedia.append(SelectedMedia(
                                    data: data,
                                    isVideo: true,
                                    thumbnail: thumbnail
                                ))
                            }
                        } catch {
                            print("Error reading video data: \(error.localizedDescription)")
                        }
                    }
                }
                // Check if it's an image
                else if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        defer { group.leave() }
                        
                        guard let image = image as? UIImage, error == nil else {
                            print("Error loading image: \(error?.localizedDescription ?? "unknown")")
                            return
                        }
                        
                        guard let data = image.jpegData(compressionQuality: 0.8) else {
                            print("Error converting image to data")
                            return
                        }
                        
                        DispatchQueue.main.async {
                            selectedMedia.append(SelectedMedia(
                                data: data,
                                isVideo: false,
                                thumbnail: image
                            ))
                        }
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.parent.selectedMedia = selectedMedia
            }
        }
        
        /// Generate a thumbnail from video URL
        private func generateVideoThumbnail(url: URL) -> UIImage? {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                return UIImage(cgImage: cgImage)
            } catch {
                print("Error generating thumbnail: \(error.localizedDescription)")
                return nil
            }
        }
    }
}
