import SwiftUI
import AVFoundation
import AVKit

/// Screen for resizing/cropping media before posting
struct MediaResizeView: View {
    @Environment(\.dismiss) var dismiss
    let selectedMedia: [SelectedMedia]
    var onPostCreated: (() -> Void)? = nil
    
    @State private var processedMedia: [SelectedMedia] = []
    @State private var navigateToCaption = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Image cropping state
    @State private var cropRect: CGRect = .zero
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    
    // Video trimming state
    @State private var trimStartTime: Double = 0
    @State private var trimEndTime: Double = 0
    @State private var videoDuration: Double = 0
    
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
        ZStack {
            hexColor("#FFFBEA")
                .ignoresSafeArea()
            
            if !selectedMedia.isEmpty {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(hexColor("#F59E0B"))
                        }
                        
                        Spacer()
                        
                        Text("Resize Media")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button(action: {
                            // For multiple images (carousel), skip resize and use originals
                            // For single image/video, apply crop if not already applied
                            if processedMedia.isEmpty {
                                processedMedia = selectedMedia
                            }
                            navigateToCaption = true
                        }) {
                            Text("Next")
                                .foregroundColor(hexColor("#F59E0B"))
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    
                    // Media resize area
                    ScrollView {
                        VStack(spacing: 20) {
                            let hasVideo = selectedMedia.contains { $0.isVideo }
                            let imageCount = selectedMedia.filter { !$0.isVideo }.count
                            
                            if hasVideo {
                                // Video resize view (only first video if multiple)
                                if let firstVideo = selectedMedia.first(where: { $0.isVideo }) {
                                    VideoResizeView(
                                        media: firstVideo,
                                        processedMedia: $processedMedia
                                    )
                                }
                            } else if imageCount > 1 {
                                // Multiple images - show carousel preview
                                CarouselPreviewView(
                                    selectedMedia: selectedMedia,
                                    processedMedia: $processedMedia
                                )
                            } else if let firstImage = selectedMedia.first(where: { !$0.isVideo }) {
                                // Single image crop/resize view
                                ImageResizeView(
                                    media: firstImage,
                                    processedMedia: $processedMedia
                                )
                            }
                            
                            // Instructions (only show for single media editing)
                            if selectedMedia.count == 1 {
                                let firstMedia = selectedMedia.first!
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(firstMedia.isVideo ? "Video Editing Tips" : "Image Editing Tips")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    
                                    Text(firstMedia.isVideo 
                                        ? "• Use pinch gestures to zoom in/out\n• Drag to reposition the video frame\n• Use trim controls to select the portion you want"
                                        : "• Pinch to zoom in or out\n• Drag to reposition the image\n• The frame shows what will be visible")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Initialize processed media with original media
            processedMedia = selectedMedia
            if let firstMedia = selectedMedia.first, firstMedia.isVideo {
                loadVideoDuration(media: firstMedia)
            }
        }
        .onChange(of: navigateToCaption) { newValue in
            if newValue {
                // Before navigating, ensure we have processed media
                if processedMedia.isEmpty {
                    processedMedia = selectedMedia
                }
            }
        }
        .navigationDestination(isPresented: $navigateToCaption) {
            AddCaptionView(
                selectedMedia: processedMedia.isEmpty ? selectedMedia : processedMedia,
                onPostCreated: onPostCreated
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadVideoDuration(media: SelectedMedia) {
        // Create a temporary file to get video duration
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        
        do {
            try media.data.write(to: tempURL)
            let asset = AVAsset(url: tempURL)
            videoDuration = asset.duration.seconds
            trimEndTime = videoDuration
            
            // Clean up
            try? FileManager.default.removeItem(at: tempURL)
        } catch {
            print("Error loading video duration: \(error.localizedDescription)")
            videoDuration = 0
            trimEndTime = 0
        }
    }
}

// MARK: - Image Resize View

struct ImageResizeView: View {
    let media: SelectedMedia
    @Binding var processedMedia: [SelectedMedia]
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var imageSize: CGSize = .zero
    @State private var uiImage: UIImage?
    
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
        VStack(spacing: 20) {
            Text("Adjust your photo")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            if let uiImage = uiImage {
                GeometryReader { geometry in
                    let containerSize = geometry.size
                    let imageViewSize = CGSize(
                        width: containerSize.width * scale,
                        height: (containerSize.width * scale) * (imageSize.height / imageSize.width)
                    )
                    
                    ZStack {
                        // Background
                        Color.black.opacity(0.1)
                        
                        // Image view
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .frame(width: imageViewSize.width, height: imageViewSize.height)
                            .clipped()
                            .frame(width: containerSize.width, height: containerSize.width)
                        
                        // Crop overlay (square frame)
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: containerSize.width, height: containerSize.width)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1.0), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                    // Constrain offset to keep image within bounds
                                    let maxOffsetX = max(0, (imageViewSize.width - containerSize.width) / 2)
                                    let maxOffsetY = max(0, (imageViewSize.height - containerSize.width) / 2)
                                    offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
                                    offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
                                    lastOffset = offset
                                }
                        )
                    )
                    .onAppear {
                        // Constrain initial position
                        let maxOffsetX = max(0, (imageViewSize.width - containerSize.width) / 2)
                        let maxOffsetY = max(0, (imageViewSize.height - containerSize.width) / 2)
                        offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
                        offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 8)
                .padding(.horizontal)
                
                        // Action buttons
                        HStack(spacing: 20) {
                            Button(action: resetImage) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset")
                                }
                                .foregroundColor(hexColor("#F59E0B"))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(hexColor("#F59E0B"), lineWidth: 1)
                                )
                            }
                            
                            Button(action: applyImageCrop) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Apply")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(hexColor("#F59E0B"))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
            } else {
                ProgressView()
                    .frame(height: 300)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let image = UIImage(data: media.data) else { return }
        uiImage = image
        imageSize = image.size
        
        // Set initial scale to fill square
        let containerWidth: CGFloat = UIScreen.main.bounds.width - 40
        let imageAspect = image.size.width / image.size.height
        if imageAspect > 1 {
            // Landscape
            scale = containerWidth / image.size.height
        } else {
            // Portrait or square
            scale = containerWidth / image.size.width
        }
    }
    
    private func resetImage() {
        scale = 1.0
        lastScale = 1.0
        offset = .zero
        lastOffset = .zero
        loadImage()
    }
    
    private func applyImageCrop() {
        guard let croppedImage = cropImage(),
              let imageData = croppedImage.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        processedMedia = [SelectedMedia(
            data: imageData,
            isVideo: false,
            thumbnail: croppedImage
        )]
    }
    
    private func cropImage() -> UIImage? {
        guard let uiImage = uiImage else { return nil }
        
        let containerWidth = UIScreen.main.bounds.width - 40
        
        // Calculate the actual displayed size (square container)
        let displaySize = containerWidth
        
        // Calculate the scale factor from original image to displayed image
        let imageAspectRatio = uiImage.size.width / uiImage.size.height
        let displayedWidth: CGFloat
        let displayedHeight: CGFloat
        
        if imageAspectRatio > 1 {
            // Landscape - width fills container
            displayedWidth = displaySize * scale
            displayedHeight = displayedWidth / imageAspectRatio
        } else {
            // Portrait or square - height fills container
            displayedHeight = displaySize * scale
            displayedWidth = displayedHeight * imageAspectRatio
        }
        
        // Calculate the center point of the displayed image
        let imageCenterX = displayedWidth / 2
        let imageCenterY = displayedHeight / 2
        
        // Calculate the crop region in displayed coordinates (square in center)
        let cropSize = displaySize
        let cropCenterX = imageCenterX + offset.width
        let cropCenterY = imageCenterY + offset.height
        
        let cropRectDisplay = CGRect(
            x: cropCenterX - cropSize / 2,
            y: cropCenterY - cropSize / 2,
            width: cropSize,
            height: cropSize
        )
        
        // Clamp crop rect to image bounds
        let clampedCropRect = CGRect(
            x: max(0, min(cropRectDisplay.origin.x, displayedWidth - cropSize)),
            y: max(0, min(cropRectDisplay.origin.y, displayedHeight - cropSize)),
            width: min(cropSize, displayedWidth),
            height: min(cropSize, displayedHeight)
        )
        
        // Convert to original image coordinates
        let scaleX = uiImage.size.width / displayedWidth
        let scaleY = uiImage.size.height / displayedHeight
        
        let cropRectOriginal = CGRect(
            x: clampedCropRect.origin.x * scaleX,
            y: clampedCropRect.origin.y * scaleY,
            width: clampedCropRect.size.width * scaleX,
            height: clampedCropRect.size.height * scaleY
        )
        
        // Crop the image
        guard let cgImage = uiImage.cgImage?.cropping(to: cropRectOriginal) else {
            // If cropping fails, return original image scaled to square
            return resizeToSquare(uiImage, size: 1080)
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: uiImage.scale, orientation: uiImage.imageOrientation)
        return resizeToSquare(croppedImage, size: 1080)
    }
    
    private func resizeToSquare(_ image: UIImage, size: CGFloat) -> UIImage {
        let size = CGSize(width: size, height: size)
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? image
    }
}

// MARK: - Video Resize View

struct VideoResizeView: View {
    let media: SelectedMedia
    @Binding var processedMedia: [SelectedMedia]
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var videoURL: URL?
    @State private var player: AVPlayer?
    @State private var trimStart: Double = 0
    @State private var trimEnd: Double = 0
    @State private var duration: Double = 0
    
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
        VStack(spacing: 20) {
            Text("Adjust your video")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            if let videoURL = videoURL, let player = player {
                GeometryReader { geometry in
                    let containerSize = geometry.size
                    
                    ZStack {
                        // Background
                        Color.black
                        
                        // Video player view
                        VideoPlayer(player: player)
                            .scaleEffect(scale)
                            .offset(offset)
                            .frame(width: containerSize.width * scale, height: containerSize.height * scale)
                            .clipped()
                            .frame(width: containerSize.width, height: containerSize.width)
                        
                        // Crop overlay
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: containerSize.width, height: containerSize.width)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1.0), 3.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                }
                .aspectRatio(1, contentMode: .fit)
                .background(Color.black)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 8)
                .padding(.horizontal)
                
                // Trim controls
                VStack(spacing: 12) {
                    Text("Trim Video")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Start: \(formatTime(trimStart))")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 70, alignment: .leading)
                            
                            Slider(
                                value: $trimStart,
                                in: 0...max(0.1, trimEnd - 0.1),
                                onEditingChanged: { editing in
                                    if !editing {
                                        seekToTime(trimStart)
                                    }
                                }
                            )
                        }
                        
                        HStack {
                            Text("End: \(formatTime(trimEnd))")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 70, alignment: .leading)
                            
                            Slider(
                                value: $trimEnd,
                                in: min(trimStart + 0.1, duration)...max(trimStart + 0.1, duration),
                                onEditingChanged: { editing in
                                    if !editing {
                                        seekToTime(trimStart)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: resetVideo) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .foregroundColor(hexColor("#F59E0B"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(hexColor("#F59E0B"), lineWidth: 1)
                        )
                    }
                    
                    Button(action: applyVideoTrim) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Apply")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(hexColor("#F59E0B"))
                        .cornerRadius(8)
                    }
                }
            } else {
                ProgressView("Loading video...")
                    .frame(height: 300)
            }
        }
        .onAppear {
            loadVideo()
        }
    }
    
    private func loadVideo() {
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        do {
            try media.data.write(to: tempURL)
            videoURL = tempURL
            
            let asset = AVAsset(url: tempURL)
            duration = asset.duration.seconds
            trimEnd = duration
            
            let newPlayer = AVPlayer(url: tempURL)
            player = newPlayer
            
                    // Update trim values
                    trimStart = 0
                    trimEnd = duration
                    
                    // Play video
                    newPlayer.play()
                    
                    // Loop playback
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: newPlayer.currentItem,
                        queue: .main
                    ) { _ in
                        newPlayer.seek(to: CMTime(seconds: trimStart, preferredTimescale: 600))
                        newPlayer.play()
                    }
        } catch {
            print("Error loading video: \(error.localizedDescription)")
        }
    }
    
    private func resetVideo() {
        scale = 1.0
        lastScale = 1.0
        offset = .zero
        lastOffset = .zero
        trimStart = 0
        if let videoURL = videoURL {
            let asset = AVAsset(url: videoURL)
            trimEnd = asset.duration.seconds
        }
        seekToTime(0)
    }
    
    private func seekToTime(_ time: Double) {
        guard let player = player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func applyVideoTrim() {
        guard let videoURL = videoURL else { return }
        
        // Show loading indicator (optional - can be added if needed)
        let asset = AVAsset(url: videoURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            return
        }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        
        // Ensure valid time range
        let startTime = max(0, trimStart)
        let endTime = min(trimEnd, duration)
        let duration = endTime - startTime
        
        guard duration > 0 else {
            // If invalid duration, use original video (already set as default)
            return
        }
        
        exportSession.timeRange = CMTimeRange(
            start: CMTime(seconds: startTime, preferredTimescale: 600),
            duration: CMTime(seconds: duration, preferredTimescale: 600)
        )
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                do {
                    let videoData = try Data(contentsOf: outputURL)
                    let thumbnail = self.generateVideoThumbnail(url: outputURL)
                    
                    DispatchQueue.main.async {
                        self.processedMedia = [SelectedMedia(
                            data: videoData,
                            isVideo: true,
                            thumbnail: thumbnail
                        )]
                    }
                    
                    // Clean up
                    try? FileManager.default.removeItem(at: outputURL)
                } catch {
                    print("Error processing video: \(error.localizedDescription)")
                    // On error, use original video
                    DispatchQueue.main.async {
                        self.processedMedia = [media]
                    }
                }
            case .failed, .cancelled:
                print("Export failed or cancelled: \(exportSession.error?.localizedDescription ?? "unknown")")
                // On failure, use original video
                DispatchQueue.main.async {
                    self.processedMedia = [media]
                }
            default:
                break
            }
        }
    }
    
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

// MARK: - Carousel Preview View

struct CarouselPreviewView: View {
    let selectedMedia: [SelectedMedia]
    @Binding var processedMedia: [SelectedMedia]
    
    @State private var selectedIndex: Int? = nil
    @State private var editingMedia: SelectedMedia? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Carousel Photos")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text("Tap a photo to resize or crop it")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // Grid preview with tap to edit
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(Array(processedMedia.enumerated()), id: \.element.id) { index, media in
                        if let thumbnail = media.thumbnail {
                            Button(action: {
                                selectedIndex = index
                                editingMedia = media
                            }) {
                                ZStack {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: (UIScreen.main.bounds.width - 56) / 3, height: (UIScreen.main.bounds.width - 56) / 3)
                                        .clipped()
                                        .cornerRadius(12)
                                    
                                    // Photo number indicator
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Text("\(index + 1)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(6)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                        }
                                        Spacer()
                                    }
                                    .padding(4)
                                    
                                    // Edit indicator
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(4)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                            Spacer()
                                        }
                                    }
                                    .padding(4)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 400)
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Carousel Info")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text("• Tap any photo to resize or crop it\n• All \(processedMedia.count) photos will be uploaded\n• Users can swipe through the photos\n• Photos are displayed in the order shown above")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .onAppear {
            // Initialize processed media with original selection if not already set
            if processedMedia.isEmpty {
                processedMedia = selectedMedia
            }
        }
        .sheet(item: Binding(
            get: { editingMedia != nil ? editingMedia : nil },
            set: { editingMedia = $0 }
        )) { media in
            NavigationStack {
                CarouselImageEditView(
                    media: media,
                    index: selectedIndex ?? 0,
                    onSave: { editedMedia in
                        if let index = selectedIndex, index < processedMedia.count {
                            processedMedia[index] = editedMedia
                        }
                        editingMedia = nil
                        selectedIndex = nil
                    },
                    onCancel: {
                        editingMedia = nil
                        selectedIndex = nil
                    }
                )
            }
        }
    }
}

// MARK: - Carousel Image Edit View

struct CarouselImageEditView: View {
    let media: SelectedMedia
    let index: Int
    let onSave: (SelectedMedia) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var imageSize: CGSize = .zero
    @State private var uiImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    // Helper to create color from hex string
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
        ZStack {
            hexColor("#FFFBEA")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Editing Photo \(index + 1)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                if let uiImage = uiImage {
                    GeometryReader { geometry in
                        let containerSize = geometry.size
                        let imageViewSize = CGSize(
                            width: containerSize.width * scale,
                            height: (containerSize.width * scale) * (imageSize.height / imageSize.width)
                        )
                        
                        ZStack {
                            // Background
                            Color.black.opacity(0.1)
                            
                            // Image view
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(scale)
                                .offset(offset)
                                .frame(width: imageViewSize.width, height: imageViewSize.height)
                                .clipped()
                                .frame(width: containerSize.width, height: containerSize.width)
                            
                            // Crop overlay (square frame)
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: containerSize.width, height: containerSize.width)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1.0), 5.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                        // Constrain offset to keep image within bounds
                                        let maxOffsetX = max(0, (imageViewSize.width - containerSize.width) / 2)
                                        let maxOffsetY = max(0, (imageViewSize.height - containerSize.width) / 2)
                                        offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
                                        offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
                                        lastOffset = offset
                                    }
                            )
                        )
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 8)
                    .padding(.horizontal)
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        Button(action: resetImage) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .foregroundColor(hexColor("#F59E0B"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(hexColor("#F59E0B"), lineWidth: 1)
                            )
                        }
                        
                        Button(action: applyImageCrop) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Apply")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(hexColor("#F59E0B"))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    ProgressView()
                        .frame(height: 300)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let image = UIImage(data: media.data) else { return }
        uiImage = image
        imageSize = image.size
        
        // Set initial scale to fill square
        let containerWidth: CGFloat = UIScreen.main.bounds.width - 40
        let imageAspect = image.size.width / image.size.height
        if imageAspect > 1 {
            // Landscape
            scale = containerWidth / image.size.height
        } else {
            // Portrait or square
            scale = containerWidth / image.size.width
        }
    }
    
    private func resetImage() {
        scale = 1.0
        lastScale = 1.0
        offset = .zero
        lastOffset = .zero
        loadImage()
    }
    
    private func applyImageCrop() {
        guard let croppedImage = cropImage(),
              let imageData = croppedImage.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let editedMedia = SelectedMedia(
            data: imageData,
            isVideo: false,
            thumbnail: croppedImage
        )
        
        onSave(editedMedia)
        dismiss()
    }
    
    private func cropImage() -> UIImage? {
        guard let uiImage = uiImage else { return nil }
        
        let containerWidth = UIScreen.main.bounds.width - 40
        
        // Calculate the actual displayed size (square container)
        let displaySize = containerWidth
        
        // Calculate the scale factor from original image to displayed image
        let imageAspectRatio = uiImage.size.width / uiImage.size.height
        let displayedWidth: CGFloat
        let displayedHeight: CGFloat
        
        if imageAspectRatio > 1 {
            // Landscape - width fills container
            displayedWidth = displaySize * scale
            displayedHeight = displayedWidth / imageAspectRatio
        } else {
            // Portrait or square - height fills container
            displayedHeight = displaySize * scale
            displayedWidth = displayedHeight * imageAspectRatio
        }
        
        // Calculate the center point of the displayed image
        let imageCenterX = displayedWidth / 2
        let imageCenterY = displayedHeight / 2
        
        // Calculate the crop region in displayed coordinates (square in center)
        let cropSize = displaySize
        let cropCenterX = imageCenterX + offset.width
        let cropCenterY = imageCenterY + offset.height
        
        let cropRectDisplay = CGRect(
            x: cropCenterX - cropSize / 2,
            y: cropCenterY - cropSize / 2,
            width: cropSize,
            height: cropSize
        )
        
        // Clamp crop rect to image bounds
        let clampedCropRect = CGRect(
            x: max(0, min(cropRectDisplay.origin.x, displayedWidth - cropSize)),
            y: max(0, min(cropRectDisplay.origin.y, displayedHeight - cropSize)),
            width: min(cropSize, displayedWidth),
            height: min(cropSize, displayedHeight)
        )
        
        // Convert to original image coordinates
        let scaleX = uiImage.size.width / displayedWidth
        let scaleY = uiImage.size.height / displayedHeight
        
        let cropRectOriginal = CGRect(
            x: clampedCropRect.origin.x * scaleX,
            y: clampedCropRect.origin.y * scaleY,
            width: clampedCropRect.size.width * scaleX,
            height: clampedCropRect.size.height * scaleY
        )
        
        // Crop the image
        guard let cgImage = uiImage.cgImage?.cropping(to: cropRectOriginal) else {
            // If cropping fails, return original image scaled to square
            return resizeToSquare(uiImage, size: 1080)
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: uiImage.scale, orientation: uiImage.imageOrientation)
        return resizeToSquare(croppedImage, size: 1080)
    }
    
    private func resizeToSquare(_ image: UIImage, size: CGFloat) -> UIImage {
        let size = CGSize(width: size, height: size)
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? image
    }
}

