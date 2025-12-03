import SwiftUI
import AVKit

/// First screen in post creation flow - Media selection
struct MediaSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedMedia: [SelectedMedia] = []
    @State private var showPicker = true
    @State private var navigateToCaption = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#FFFBEA")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if selectedMedia.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Select a photo or video")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Preview selected media
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(selectedMedia) { media in
                                    MediaPreviewCard(media: media)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(Color(hex: "#F59E0B"))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Next") {
                        navigateToCaption = true
                    }
                    .foregroundColor(selectedMedia.isEmpty ? .gray : Color(hex: "#F59E0B"))
                    .disabled(selectedMedia.isEmpty)
                }
            }
            .sheet(isPresented: $showPicker) {
                MediaPicker(selectedMedia: $selectedMedia, selectionLimit: 1)
            }
            .navigationDestination(isPresented: $navigateToCaption) {
                AddCaptionView(selectedMedia: selectedMedia)
            }
        }
    }
}

/// Preview card for selected media
struct MediaPreviewCard: View {
    let media: SelectedMedia
    
    var body: some View {
        VStack(spacing: 0) {
            if let thumbnail = media.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .clipped()
                    .cornerRadius(16)
                    .overlay(
                        Group {
                            if media.isVideo {
                                // Video indicator
                                ZStack {
                                    Color.black.opacity(0.3)
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                }
                                .cornerRadius(16)
                            }
                        }
                    )
            } else {
                // Placeholder if no thumbnail
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 400)
                    .cornerRadius(16)
                    .overlay(
                        Image(systemName: media.isVideo ? "video" : "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    )
            }
            
            // Media info
            HStack {
                Image(systemName: media.isVideo ? "video.fill" : "photo.fill")
                    .foregroundColor(Color(hex: "#F59E0B"))
                Text(media.isVideo ? "Video" : "Image")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text(formatBytes(media.data.count))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Preview
struct MediaSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        MediaSelectionView()
    }
}
