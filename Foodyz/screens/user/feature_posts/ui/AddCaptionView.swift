import SwiftUI

/// Second screen in post creation flow - Add caption and upload
struct AddCaptionView: View {
    @Environment(\.dismiss) var dismiss
    let selectedMedia: [SelectedMedia]
    
    @State private var caption = ""
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var uploadProgress: Double = 0
    
    // Navigation to dismiss entire flow
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(hex: "#FFFBEA")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Media thumbnail
                    if let firstMedia = selectedMedia.first, let thumbnail = firstMedia.thumbnail {
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
                                    .foregroundColor(Color(hex: "#1F2937"))
                                
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
                    }
                    
                    // Caption input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Write a caption")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#1F2937"))
                        
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
                            .tint(Color(hex: "#F59E0B"))
                        
                        Text("Uploading your post...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if uploadProgress > 0 {
                            ProgressView(value: uploadProgress, total: 100)
                                .tint(Color(hex: "#F59E0B"))
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(Color(hex: "#F59E0B"))
                }
                .disabled(isUploading)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Post") {
                    Task {
                        await uploadPost()
                    }
                }
                .foregroundColor(caption.isEmpty || isUploading ? .gray : Color(hex: "#F59E0B"))
                .disabled(caption.isEmpty || isUploading)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
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
        
        isUploading = true
        uploadProgress = 0
        
        do {
            // Step 1: Upload media files
            uploadProgress = 10
            let mediaDataArray = selectedMedia.map { $0.data }
            let uploadResponse = try await PostsAPI.shared.uploadMedia(mediaData: mediaDataArray)
            
            guard !uploadResponse.urls.isEmpty else {
                throw PostsError.serverError("No URLs returned from upload")
            }
            
            uploadProgress = 50
            
            // Step 2: Determine media type
            let mediaType: MediaType = selectedMedia.first?.isVideo == true ? .reel : .image
            
            // Step 3: Create post
            uploadProgress = 70
            let post = try await PostsAPI.shared.createPost(
                userId: userId,
                caption: caption,
                mediaUrls: uploadResponse.urls,
                mediaType: mediaType
            )
            
            uploadProgress = 100
            
            print("Post created successfully: \(post.id)")
            
            // Dismiss the entire post creation flow
            // Navigate back to root (HomeUserScreen)
            await MainActor.run {
                // Dismiss current view and parent view
                presentationMode.wrappedValue.dismiss()
                
                // Post notification to refresh posts feed
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshPostsFeed"),
                    object: nil
                )
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

// MARK: - Preview
struct AddCaptionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddCaptionView(selectedMedia: [])
        }
    }
}
