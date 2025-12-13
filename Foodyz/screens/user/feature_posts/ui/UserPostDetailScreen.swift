import SwiftUI
import AVKit
import Combine

// MARK: - User Post Detail Screen
struct UserPostDetailScreen: View {
    let postId: String
    @Binding var path: NavigationPath
    
    @StateObject private var viewModel = UserPostDetailViewModel()
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
                        UserPostDetailCard(
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
        .navigationTitle("Post Details")
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
                        // Notify to refresh posts
                        NotificationCenter.default.post(name: NSNotification.Name("RefreshUserPosts"), object: nil)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .sheet(isPresented: $showComments) {
            NavigationStack {
                ReelCommentsView(postId: postId)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadPost(postId: postId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshUserPosts"))) { _ in
            Task {
                await viewModel.loadPost(postId: postId)
            }
        }
    }
}

// MARK: - User Post Detail Card
struct UserPostDetailCard: View {
    let post: Post
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onCommentsTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Media Section
            ZStack(alignment: .center) {
                Group {
                    if post.isVideo {
                        videoThumbnailView
                    } else {
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
            
            // Actions Row
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
            
            // Caption
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
            
            // Price (if available)
            if let price = post.price {
                HStack {
                    Text("\(price, specifier: "%.1f") TND")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .frame(maxWidth: .infinity)
            }
            
            // Preparation Time (if available)
            if let prepTime = post.preparationTime {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    Text("\(prepTime) minutes")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
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
           let url = URL(string: thumbnailUrl.replacingOccurrences(of: "10.0.2.2", with: "192.168.100.28")) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_), .empty:
                    clientGeneratedVideoThumbnail
                @unknown default:
                    clientGeneratedVideoThumbnail
                }
            }
        } else {
            clientGeneratedVideoThumbnail
        }
    }
    
    @ViewBuilder
    private var clientGeneratedVideoThumbnail: some View {
        if let videoUrlString = post.mediaUrls.first,
           let videoUrl = URL(string: videoUrlString.replacingOccurrences(of: "10.0.2.2", with: "192.168.100.28")) {
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

// MARK: - ViewModel
@MainActor
class UserPostDetailViewModel: ObservableObject {
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
        isLoading = true
        
        do {
            try await PostsAPI.shared.deletePost(postId: postId)
            isDeleted = true
            // Notify to refresh posts
            NotificationCenter.default.post(name: NSNotification.Name("RefreshUserPosts"), object: nil)
        } catch {
            errorMessage = error.localizedDescription
            print("Error deleting post: \(error)")
        }
        
        isLoading = false
    }
}

