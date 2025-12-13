import SwiftUI
import AVKit

/// First screen in post creation flow - Media selection
struct MediaSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    var onPostCreated: (() -> Void)? = nil
    @State private var selectedMedia: [SelectedMedia] = []
    @State private var showPicker = true
    @State private var navigateToCaption = false
    
    // Maximum number of images for carousel (10 is a reasonable limit)
    private let maxImagesForCarousel = 10
    
    init(isPresented: Binding<Bool> = .constant(true), onPostCreated: (() -> Void)? = nil) {
        self._isPresented = isPresented
        self.onPostCreated = onPostCreated
    }
    
    // Helper to create color from hex string to avoid ambiguity
    private func hexColor(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            r = 1; g = 1; b = 1
        }
        return Color(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: 1.0)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                hexColor("#FFFBEA")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if selectedMedia.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Select photos or a video")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            Text("Select up to \(maxImagesForCarousel) photos for a carousel, or 1 video")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Preview selected media
                        ScrollView {
                            VStack(spacing: 16) {
                                // Show selection count if multiple items
                                if selectedMedia.count > 1 {
                                    HStack {
                                        Text("\(selectedMedia.count) items selected")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Button(action: {
                                            selectedMedia.removeAll()
                                        }) {
                                            Text("Clear All")
                                                .font(.caption)
                                                .foregroundColor(hexColor("#F59E0B"))
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                ForEach(selectedMedia) { media in
                                    MediaPreviewCard(media: media, onRemove: {
                                        selectedMedia.removeAll { $0.id == media.id }
                                    }, canRemove: selectedMedia.count > 1)
                                }
                                
                                // Add more button (only show if images selected and under limit, and no video)
                                let hasVideo = selectedMedia.contains { $0.isVideo }
                                let imageCount = selectedMedia.filter { !$0.isVideo }.count
                                if !hasVideo && imageCount < maxImagesForCarousel {
                                    Button(action: {
                                        showPicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add More Photos")
                                        }
                                        .foregroundColor(hexColor("#F59E0B"))
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(hexColor("#F59E0B"), lineWidth: 1)
                                        )
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(hexColor("#F59E0B"))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Next") {
                        navigateToCaption = true
                    }
                    .foregroundColor(selectedMedia.isEmpty ? .gray : hexColor("#F59E0B"))
                    .disabled(selectedMedia.isEmpty)
                }
            })
            .sheet(isPresented: $showPicker) {
                // Determine selection limit based on current selection
                let hasVideo = selectedMedia.contains { $0.isVideo }
                let imageCount = selectedMedia.filter { !$0.isVideo }.count
                let isAddingMore = imageCount > 0 && !hasVideo
                
                // If video is already selected, don't allow more. Otherwise allow up to maxImagesForCarousel images
                let selectionLimit = hasVideo ? 1 : maxImagesForCarousel
                let remainingSlots = hasVideo ? 0 : (maxImagesForCarousel - imageCount)
                
                MediaPicker(
                    selectedMedia: $selectedMedia,
                    selectionLimit: min(selectionLimit, max(1, remainingSlots)),
                    allowVideos: !hasVideo && imageCount == 0,
                    appendToExisting: isAddingMore
                )
            }
            .navigationDestination(isPresented: $navigateToCaption) {
                MediaResizeView(selectedMedia: selectedMedia, onPostCreated: {
                    // Dismiss the sheet
                    isPresented = false
                    // Call the parent's onPostCreated callback if provided
                    onPostCreated?()
                })
            }
        }
    }
}

/// Preview card for selected media
struct MediaPreviewCard: View {
    let media: SelectedMedia
    var onRemove: (() -> Void)? = nil
    var canRemove: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
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
                
                // Remove button overlay
                if canRemove, let onRemove = onRemove {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onRemove) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            
            // Media info
            HStack {
                Image(systemName: media.isVideo ? "video.fill" : "photo.fill")
                    .foregroundColor(Color(red: 0.99, green: 0.69, blue: 0.16))
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
