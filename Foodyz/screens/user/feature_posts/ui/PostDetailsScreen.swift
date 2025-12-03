import SwiftUI
import Combine

struct PostDetailsScreen: View {
    let postId: String
    @StateObject private var viewModel = PostDetailsViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let post = viewModel.post {
                ScrollView {
                    VStack(spacing: 0) {
                        // User Header
                        HStack(spacing: 12) {
                            if let profileUrl = post.userId?.profilePictureUrl,
                               let url = URL(string: profileUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color.gray)
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 50, height: 50)
                            }
                            
                            Text(post.userId?.username ?? "Unknown")
                                .font(.headline)
                            
                            Spacer()
                            
                            // Rating Badge
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12))
                                Text("4.8")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.yellow)
                            .cornerRadius(12)
                        }
                        .padding()
                        
                        // Post Image/Video
                        if let imageUrl = post.fullDisplayImageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 250)
                                        .clipped()
                                case .failure(_):
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 250)
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 250)
                                        .overlay(ProgressView())
                                @unknown default:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 250)
                                }
                            }
                        }
                        
                        // Post Details
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.caption)
                                .font(.title2.bold())
                            
                            HStack {
                                Text("29 TND")
                                    .font(.headline)
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 14))
                                    Text("4.9 • \(post.commentCount) reviews")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        
                        Divider()
                        
                        // Reviews Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reviews")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            if viewModel.comments.isEmpty {
                                Text("No reviews yet")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(viewModel.comments) { comment in
                                    CommentRow(comment: comment)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Comment Input at Bottom
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        TextField("Add a comment...", text: $viewModel.commentText)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(25)
                        
                        Button(action: {
                            Task {
                                await viewModel.postComment()
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.commentText.isEmpty)
                    }
                    .padding()
                    .background(Color.white)
                }
            }
        }
        .navigationTitle("Post Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadPost(id: postId)
            }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Anonymous User")
                    .font(.subheadline.bold())
                Text(comment.text)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - ViewModel
@MainActor
class PostDetailsViewModel: ObservableObject {
    @Published var post: Post?
    @Published var comments: [Comment] = []
    @Published var commentText = ""
    @Published var isLoading = false
    
    func loadPost(id: String) async {
        isLoading = true
        do {
            post = try await PostsAPI.shared.getPost(id: id)
            try await loadComments(postId: id)
        } catch {
            print("Error loading post: \(error)")
        }
        isLoading = false
    }
    
    func loadComments(postId: String) async throws {
        comments = try await PostsAPI.shared.getComments(postId: postId)
    }
    
    func postComment() async {
        guard let postId = post?.id, !commentText.isEmpty else { return }
        
        do {
            let newComment = try await PostsAPI.shared.createComment(postId: postId, text: commentText)
            comments.append(newComment)
            commentText = ""
            
            // Update comment count
            if var currentPost = post {
                post = Post(
                    id: currentPost.id,
                    userId: currentPost.userId,
                    caption: currentPost.caption,
                    mediaUrls: currentPost.mediaUrls,
                    mediaType: currentPost.mediaType,
                    likeCount: currentPost.likeCount,
                    commentCount: currentPost.commentCount + 1,
                    saveCount: currentPost.saveCount,
                    thumbnailUrl: currentPost.thumbnailUrl,
                    viewsCount: currentPost.viewsCount,
                    duration: currentPost.duration,
                    aspectRatio: currentPost.aspectRatio,
                    createdAt: currentPost.createdAt,
                    updatedAt: currentPost.updatedAt
                )
            }
        } catch {
            print("Error posting comment: \(error)")
        }
    }
}
