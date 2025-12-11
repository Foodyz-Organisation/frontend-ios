import SwiftUI
import AVKit
import Combine

// MARK: - Professional Post Detail Screen
struct ProfessionalPostDetailScreen: View {
    let postId: String
    @Binding var path: NavigationPath
    
    @StateObject private var viewModel = ProfessionalPostDetailViewModel()
    @State private var showDeleteAlert = false
    @State private var showComments = false
    
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.97, blue: 1.0)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let post = viewModel.post {
                ScrollView {
                    VStack(spacing: 16) {
                        // Post Card
                        PostDetailCard(
                            post: post,
                            onEdit: {
                                path.append(Screen.editPost(postId))
                            },
                            onDelete: {
                                showDeleteAlert = true
                            },
                            onCommentsTap: {
                                showComments = true
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        Spacer(minLength: 40)
                    }
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text(error)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Try Again") {
                        Task {
                            await viewModel.loadPost(postId: postId)
                        }
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .navigationTitle("All Posts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { path.removeLast() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                }
            }
        }
        .alert("Delete Post", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deletePost(postId: postId)
                    if viewModel.isDeleted {
                        path.removeLast()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .sheet(isPresented: $showComments) {
            CommentsSheetView(postId: postId)
        }
        .onAppear {
            Task {
                await viewModel.loadPost(postId: postId)
            }
        }
    }
}

// MARK: - Post Detail Card
struct PostDetailCard: View {
    let post: Post
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onCommentsTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Media Section - Same structure for both photos and videos
            ZStack(alignment: .center) {
                // Background media (thumbnail or image)
                Group {
                    if post.isVideo {
                        // For videos: try thumbnail first, then generate from video
                        videoThumbnailView
                    } else {
                        // For photos: load image directly
                        photoImageView
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()
                
                // Play button overlay (only for videos)
                if post.isVideo {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .cornerRadius(16, corners: [.topLeft, .topRight])
            
            // Actions Row - Always visible for both photos and videos
            HStack(spacing: 20) {
                // Like count
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                    Text("\(post.likeCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
                
                // Comment count (tappable)
                Button(action: onCommentsTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "message")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                        Text("\(post.commentCount)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
                
                Spacer()
                
                // Edit button
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .frame(maxWidth: .infinity)
            
            // Caption - Always visible if not empty
            if !post.caption.isEmpty {
                HStack {
                    Text(post.caption)
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .lineLimit(nil)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Video Thumbnail View
    @ViewBuilder
    private var videoThumbnailView: some View {
        if let thumbnailUrl = post.thumbnailUrl,
           !thumbnailUrl.isEmpty,
           let url = URL(string: thumbnailUrl.replacingOccurrences(of: "10.0.2.2", with: "localhost")) {
            // Use server-generated thumbnail
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_), .empty:
                    // Fallback to client-side generation
                    clientGeneratedVideoThumbnail
                @unknown default:
                    clientGeneratedVideoThumbnail
                }
            }
        } else {
            // Generate thumbnail from video on client
            clientGeneratedVideoThumbnail
        }
    }
    
    @ViewBuilder
    private var clientGeneratedVideoThumbnail: some View {
        if let videoUrlString = post.mediaUrls.first,
           let videoUrl = URL(string: videoUrlString.replacingOccurrences(of: "10.0.2.2", with: "localhost")) {
            VideoThumbnailView(videoUrl: videoUrl)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "video")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                )
        }
    }
    
    // MARK: - Photo Image View
    @ViewBuilder
    private var photoImageView: some View {
        if let imageUrl = post.fullDisplayImageUrl,
           let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                }
            }
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                )
        }
    }
}

// MARK: - Video Player View
struct VideoPlayerView: View {
    let videoUrl: URL
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .overlay(ProgressView().tint(.white))
            }
        }
        .onAppear {
            player = AVPlayer(url: videoUrl)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

// MARK: - Comments Sheet View
struct CommentsSheetView: View {
    let postId: String
    @StateObject private var viewModel = CommentsViewModel()
    @State private var newCommentText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.comments.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No comments yet")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List(viewModel.comments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(comment.text)
                                .font(.body)
                            Text(formatDate(comment.createdAt))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadComments(postId: postId)
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Comments ViewModel
@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    
    func loadComments(postId: String) async {
        isLoading = true
        do {
            comments = try await PostsAPI.shared.getComments(postId: postId)
        } catch {
            print("Error loading comments: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Professional Post Detail ViewModel
@MainActor
class ProfessionalPostDetailViewModel: ObservableObject {
    @Published var post: Post?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isDeleted = false
    
    func loadPost(postId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            post = try await PostsAPI.shared.getPost(id: postId)
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading post: \(error)")
        }
        
        isLoading = false
    }
    
    func deletePost(postId: String) async {
        do {
            try await PostsAPI.shared.deletePost(postId: postId)
            isDeleted = true
            // Notify to refresh posts
            NotificationCenter.default.post(name: NSNotification.Name("RefreshPostsFeed"), object: nil)
        } catch {
            errorMessage = error.localizedDescription
            print("Error deleting post: \(error)")
        }
    }
}

// MARK: - Preview
struct ProfessionalPostDetailScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfessionalPostDetailScreen(
                postId: "123",
                path: .constant(NavigationPath())
            )
        }
    }
}
