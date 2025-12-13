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
    
    var body: some View {
        ZStack {
            hexColor("#FFFBEA")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Media preview
                    if !selectedMedia.isEmpty {
                        let hasVideo = selectedMedia.contains { $0.isVideo }
                        let imageCount = selectedMedia.filter { !$0.isVideo }.count
                        
                        if selectedMedia.count == 1, let firstMedia = selectedMedia.first, let thumbnail = firstMedia.thumbnail {
                            // Single media preview
                            HStack(spacing: 12) {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(12)
                                    .overlay(
                                        Group {
                                            if firstMedia.isVideo {
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
                                    Text(firstMedia.isVideo ? "Video selected" : "Photo selected")
                                        .font(.headline)
                                        .foregroundColor(hexColor("#1F2937"))
                                    
                                    Text(formatBytes(firstMedia.data.count))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 4)
                        } else {
                            // Multiple media preview (carousel)
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(imageCount > 1 ? "Carousel (\(imageCount) photos)" : "Media selected")
                                        .font(.headline)
                                        .foregroundColor(hexColor("#1F2937"))
                                    Spacer()
                                }
                                
                                // Grid preview of all images
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
                                                        // Photo number indicator
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
                    }
                    
                    // Caption input
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
                    }
                    
                    // Character count
                    HStack {
                        Spacer()
                        Text("\(caption.count) characters")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Food Type Picker (Required)
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
                    
                    // Price Input (Optional)
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
                    
                    // Preparation Time Input (Optional)
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
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            
            // Loading overlay
            if isUploading {
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
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

// MARK: - Preview
struct AddCaptionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddCaptionView(selectedMedia: [])
        }
    }
}
