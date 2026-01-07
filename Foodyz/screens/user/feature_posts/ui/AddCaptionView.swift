import SwiftUI

/// Second screen in post creation flow - Add caption and upload
struct AddCaptionView: View {
    @Environment(\.dismiss) var dismiss
    let selectedMedia: [SelectedMedia]
    var onPostCreated: (() -> Void)? = nil
    
    @State private var caption = ""
    @State private var selectedFoodType: String? = nil
    @State private var priceText: String = ""
    @State private var preparationTimeText: String = ""
    @State private var showFoodTypePicker = false
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var uploadProgress: Double = 0
    @State private var foodTypes: [String] = []
    
    // Navigation to dismiss entire flow
    @Environment(\.presentationMode) var presentationMode
    
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
    
    // MARK: - View Components
    
    @ViewBuilder
    private var mediaPreviewSection: some View {
        if !selectedMedia.isEmpty {
            let hasVideo = selectedMedia.contains { $0.isVideo }
            let imageCount = selectedMedia.filter { !$0.isVideo }.count
            
            if selectedMedia.count == 1, let firstMedia = selectedMedia.first, let thumbnail = firstMedia.thumbnail {
                singleMediaPreview(media: firstMedia, thumbnail: thumbnail)
            } else {
                multipleMediaPreview(hasVideo: hasVideo, imageCount: imageCount)
            }
        }
    }
    
    private func singleMediaPreview(media: SelectedMedia, thumbnail: UIImage) -> some View {
        HStack(spacing: 12) {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(12)
                .overlay(
                    Group {
                        if media.isVideo {
                            ZStack {
                                Color.black.opacity(0.3)
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title3)
                            }
                            .cornerRadius(12)
                        }
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(media.isVideo ? "Video selected" : "Photo selected")
                    .font(.headline)
                    .foregroundColor(hexColor("#1F2937"))
                
                Text(formatBytes(media.data.count))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
    
    private func multipleMediaPreview(hasVideo: Bool, imageCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(imageCount > 1 ? "Carousel (\(imageCount) photos)" : "Media selected")
                    .font(.headline)
                    .foregroundColor(hexColor("#1F2937"))
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(selectedMedia.enumerated()), id: \.element.id) { index, media in
                        if let thumbnail = media.thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(12)
                                .overlay(
                                    Group {
                                        if media.isVideo {
                                            ZStack {
                                                Color.black.opacity(0.3)
                                                Image(systemName: "play.circle.fill")
                                                    .foregroundColor(.white)
                                                    .font(.caption)
                                            }
                                            .cornerRadius(12)
                                        }
                                    }
                                )
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle()),
                                    alignment: .topTrailing
                                )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            Text("Total size: \(formatBytes(selectedMedia.reduce(0) { $0 + $1.data.count }))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
    
    private var captionInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Write a caption")
                .font(.headline)
                .foregroundColor(hexColor("#1F2937"))
            
            TextEditor(text: $caption)
                .frame(minHeight: 150)
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if caption.isEmpty {
                            Text("Share your thoughts...")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.leading, 16)
                                .padding(.top, 20)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
            
            HStack {
                Spacer()
                Text("\(caption.count) characters")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var foodTypePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Food Type *")
                .font(.headline)
                .foregroundColor(hexColor("#1F2937"))
            
            Button(action: {
                showFoodTypePicker = true
            }) {
                HStack {
                    Text(selectedFoodType ?? "Select a food type...")
                        .foregroundColor(selectedFoodType == nil ? .gray : hexColor("#1F2937"))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedFoodType == nil ? Color.red.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    private var priceInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price (TND)")
                .font(.headline)
                .foregroundColor(hexColor("#1F2937"))
            
            TextField("Ex: 30.0", text: $priceText)
                .keyboardType(.decimalPad)
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var preparationTimeInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preparation Time (minutes)")
                .font(.headline)
                .foregroundColor(hexColor("#1F2937"))
            
            TextField("Ex: 15", text: $preparationTimeText)
                .keyboardType(.numberPad)
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(hexColor("#F59E0B"))
                
                Text("Uploading your post...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if uploadProgress > 0 {
                    ProgressView(value: uploadProgress, total: 100)
                        .tint(hexColor("#F59E0B"))
                        .frame(width: 200)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .shadow(radius: 10)
        }
    }
    
    var body: some View {
        ZStack {
            hexColor("#FFFBEA")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    mediaPreviewSection
                    captionInputSection
                    foodTypePickerSection
                    priceInputSection
                    preparationTimeInputSection
                    Spacer(minLength: 40)
                }
                .padding()
            }
            
            if isUploading {
                loadingOverlay
            }
        }
        .navigationTitle("New Post")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(hexColor("#F59E0B"))
                }
                .disabled(isUploading)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Post") {
                    Task {
                        await uploadPost()
                    }
                }
                .foregroundColor(caption.isEmpty || selectedFoodType == nil || isUploading ? .gray : hexColor("#F59E0B"))
                .disabled(caption.isEmpty || selectedFoodType == nil || isUploading)
            }
        })
        .sheet(isPresented: $showFoodTypePicker) {
            FoodTypePickerView(selectedFoodType: $selectedFoodType, foodTypes: foodTypes)
        }
        .overlay(
            Group {
                if showError {
                    CustomErrorAlert(
                        message: extractFoodRelatedMessage(from: errorMessage),
                        onDismiss: {
                            showError = false
                        }
                    )
                }
            }
        )
        .onAppear {
            Task {
                await loadFoodTypes()
            }
        }
    }
    
    // MARK: - Load Food Types
    private func loadFoodTypes() async {
        do {
            foodTypes = try await PostsAPI.shared.getFoodTypes()
        } catch {
            print("Failed to load food types: \(error.localizedDescription)")
            // Fallback to enum values if API fails
            foodTypes = FoodType.getAllValues()
        }
    }
    
    // MARK: - Upload Post
    private func uploadPost() async {
        guard let userId = UserSession.shared.userId else {
            errorMessage = "Please log in to create a post"
            showError = true
            return
        }
        
        guard !selectedMedia.isEmpty else {
            errorMessage = "No media selected"
            showError = true
            return
        }
        
        guard let foodType = selectedFoodType else {
            errorMessage = "Please select a food type"
            showError = true
            return
        }
        
        // Validate price
        var price: Double? = nil
        if !priceText.isEmpty {
            if let parsedPrice = Double(priceText) {
                if parsedPrice < 0 {
                    errorMessage = "Price must be >= 0"
                    showError = true
                    return
                }
                price = parsedPrice
            } else {
                errorMessage = "Invalid price format"
                showError = true
                return
            }
        }
        
        // Validate preparation time
        var preparationTime: Int? = nil
        if !preparationTimeText.isEmpty {
            if let parsedPrepTime = Int(preparationTimeText) {
                if parsedPrepTime < 0 {
                    errorMessage = "Preparation time must be >= 0"
                    showError = true
                    return
                }
                preparationTime = parsedPrepTime
            } else {
                errorMessage = "Invalid preparation time format"
                showError = true
                return
            }
        }
        
        isUploading = true
        uploadProgress = 0
        
        do {
            // Step 1: Upload media files
            uploadProgress = 10
            let mediaDataArray = selectedMedia.map { $0.data }
            let isVideoArray = selectedMedia.map { $0.isVideo }
            let uploadResponse = try await PostsAPI.shared.uploadMedia(mediaData: mediaDataArray, isVideoArray: isVideoArray)
            
            guard !uploadResponse.urls.isEmpty else {
                throw PostsError.serverError("No URLs returned from upload")
            }
            
            uploadProgress = 50
            
            // Step 2: Determine media type
            // - If any media is video, it's a reel (single video only)
            // - If multiple images, it's a carousel
            // - If single image, it's an image
            let hasVideo = selectedMedia.contains { $0.isVideo }
            let imageCount = selectedMedia.filter { !$0.isVideo }.count
            
            let mediaType: MediaType
            if hasVideo {
                mediaType = .reel
            } else if imageCount > 1 {
                mediaType = .carousel
            } else {
                mediaType = .image
            }
            
            // Step 3: Determine owner type based on user role
            let userRole = UserSession.shared.userRole ?? "user"
            let ownerType = userRole == "professional" ? "ProfessionalAccount" : "UserAccount"
            
            // Step 4: Create post
            uploadProgress = 70
            let post = try await PostsAPI.shared.createPost(
                userId: userId,
                ownerType: ownerType,
                caption: caption,
                mediaUrls: uploadResponse.urls,
                mediaType: mediaType,
                foodType: foodType,
                price: price,
                preparationTime: preparationTime
            )
            
            uploadProgress = 100
            
            print("Post created successfully: \(post.id)")
            
            // Dismiss the entire post creation flow
            // Navigate back to root (HomeUserScreen)
            await MainActor.run {
                // Post notification to refresh posts feed first
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshPostsFeed"),
                    object: nil
                )
                
                // Call the completion handler to dismiss the entire sheet
                onPostCreated?()
                
                // Also dismiss navigation (fallback)
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                isUploading = false
                
                if let postsError = error as? PostsError {
                    errorMessage = postsError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
                showError = true
            }
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // MARK: - Extract Food Related Message
    /// Extracts the food-related message from error response
    private func extractFoodRelatedMessage(from errorString: String) -> String {
        var cleanErrorString = errorString
        
        // Remove "Server Error: " prefix if present
        if cleanErrorString.hasPrefix("Server Error: ") {
            cleanErrorString = String(cleanErrorString.dropFirst("Server Error: ".count))
        }
        
        // Try to parse JSON error response
        if let jsonData = cleanErrorString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let message = json["message"] as? String {
            // Check if it's a food-related error
            if message.lowercased().contains("food") || message.lowercased().contains("does not appear to contain") {
                // Extract just the main message, removing file name and confidence if present
                var cleanMessage = message
                // Remove file name references like "file0.jpg"
                cleanMessage = cleanMessage.replacingOccurrences(of: #"\"file\d+\.\w+\""#, with: "", options: .regularExpression)
                // Remove confidence percentage if present
                cleanMessage = cleanMessage.replacingOccurrences(of: #"\s*\(Confidence:\s*\d+\.\d+%\)"#, with: "", options: .regularExpression)
                // Clean up extra spaces
                cleanMessage = cleanMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                cleanMessage = cleanMessage.replacingOccurrences(of: "  ", with: " ")
                
                // If message contains "does not appear to contain", simplify it
                if cleanMessage.contains("does not appear to contain food-related content") {
                    return "The uploaded image does not appear to contain food-related content. Please upload images of food items only."
                }
                
                return cleanMessage.isEmpty ? "The uploaded image is not food-related. Please upload images of food items only." : cleanMessage
            }
            return message
        }
        
        // If it's not JSON, check if it contains food-related keywords
        if cleanErrorString.lowercased().contains("food") || cleanErrorString.lowercased().contains("does not appear to contain") {
            return "The uploaded image is not food-related. Please upload images of food items only."
        }
        
        // Return original message if no food-related content found
        return cleanErrorString
    }
}

// MARK: - Food Type Picker View
struct FoodTypePickerView: View {
    @Binding var selectedFoodType: String?
    @Environment(\.dismiss) var dismiss
    let foodTypes: [String]
    
    var body: some View {
        NavigationView {
            List(foodTypes, id: \.self) { foodType in
                Button(action: {
                    selectedFoodType = foodType
                    dismiss()
                }) {
                    HStack {
                        Text(foodType)
                        Spacer()
                        if selectedFoodType == foodType {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color(red: 0.99, green: 0.69, blue: 0.16))
                        }
                    }
                }
            }
            .navigationTitle("Select Food Type")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Custom Error Alert
struct CustomErrorAlert: View {
    let message: String
    let onDismiss: () -> Void
    
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
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Alert card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(hexColor("#F59E0B"))
                    
                    Text("Error")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(hexColor("#1F2937"))
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // Message
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(hexColor("#1F2937"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                
                // OK Button
                Button(action: onDismiss) {
                    Text("OK")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(hexColor("#F59E0B"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: 320)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
}

// MARK: - Preview
struct AddCaptionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddCaptionView(selectedMedia: [])
        }
    }
}
