import SwiftUI
import Combine

// MARK: - Edit Post Screen
struct EditPostScreen: View {
    let postId: String
    @Binding var path: NavigationPath
    
    @StateObject private var viewModel = EditPostViewModel()
    @State private var caption: String = ""
    @FocusState private var isCaptionFocused: Bool
    
    var body: some View {
        ZStack {
            Color.foodyzBackground
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.post == nil {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Post Preview
                        if let post = viewModel.post {
                            PostPreviewCard(post: post)
                        }
                        
                        // Caption Editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Edit Caption")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            TextEditor(text: $caption)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .focused($isCaptionFocused)
                            
                            // Character count
                            HStack {
                                Spacer()
                                Text("\(caption.count) characters")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Save Button
                        Button(action: {
                            Task {
                                await viewModel.updatePost(postId: postId, newCaption: caption)
                                if viewModel.isUpdated {
                                    path.removeLast()
                                }
                            }
                        }) {
                            HStack {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save Changes")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.foodyzOrange, Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isSaving || caption.isEmpty)
                        .padding(.horizontal, 16)
                        
                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .navigationTitle("Edit Post")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { path.removeLast() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.foodyzOrange)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadPost(postId: postId)
                if let post = viewModel.post {
                    caption = post.caption
                }
            }
        }
        .onTapGesture {
            isCaptionFocused = false
        }
    }
}

// MARK: - Post Preview Card
struct PostPreviewCard: View {
    let post: Post
    
    var body: some View {
        VStack(spacing: 0) {
            // Media thumbnail
            ZStack {
                if let imageUrl = post.fullDisplayImageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        case .failure(_), .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: post.isVideo ? "video" : "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 200)
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                }
                
                // Video indicator
                if post.isVideo {
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "video.fill")
                                    .font(.caption)
                                Text("Video")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            Spacer()
                        }
                        .padding(12)
                    }
                }
            }
            
            // Post info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.isVideo ? "Reel" : "Photo")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Posted \(formatTimeAgo(post.createdAt))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                HStack(spacing: 12) {
                    Label("\(post.likeCount)", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    Label("\(post.commentCount)", systemImage: "message")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(Color.white)
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
    
    private func formatTimeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return "recently"
        }
        
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Edit Post ViewModel
@MainActor
class EditPostViewModel: ObservableObject {
    @Published var post: Post?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var isUpdated = false
    
    func loadPost(postId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            post = try await PostsAPI.shared.getPost(id: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updatePost(postId: String, newCaption: String) async {
        isSaving = true
        errorMessage = nil
        
        do {
            try await PostsAPI.shared.updatePost(postId: postId, caption: newCaption)
            isUpdated = true
            // Notify to refresh posts
            NotificationCenter.default.post(name: NSNotification.Name("RefreshPostsFeed"), object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
}

// MARK: - Preview
struct EditPostScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EditPostScreen(postId: "123", path: .constant(NavigationPath()))
        }
    }
}

