import SwiftUI
import Combine

struct ReelCommentsView: View {
    let postId: String
    @StateObject private var viewModel: ReelCommentsViewModel
    @Environment(\.dismiss) var dismiss
    
    init(postId: String) {
        self.postId = postId
        _viewModel = StateObject(wrappedValue: ReelCommentsViewModel(postId: postId))
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Comments List
                ScrollView {
                    VStack(spacing: 0) {
                        if viewModel.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(Color(hex: "#F59E0B"))
                                Text("Loading comments...")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else if viewModel.comments.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No comments yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Be the first to comment!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else {
                            ForEach(viewModel.comments) { comment in
                                CommentRow(
                                    comment: comment,
                                    currentUserId: UserSession.shared.userId,
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteComment(commentId: comment.id)
                                        }
                                    }
                                )
                                Divider()
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Comment Input at Bottom
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField("Add a comment...", text: $viewModel.commentText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(25)
                        
                        Button(action: {
                            Task {
                                await viewModel.postComment()
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .padding(12)
                                .background(viewModel.commentText.isEmpty ? Color.gray : Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.commentText.isEmpty || viewModel.isPostingComment)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color.white)
                }
            }
        }
        .navigationTitle("Comments")
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
                await viewModel.loadComments()
            }
        }
    }
}

// MARK: - ViewModel
@MainActor
class ReelCommentsViewModel: ObservableObject {
    let postId: String
    @Published var comments: [Comment] = []
    @Published var commentText = ""
    @Published var isLoading = false
    @Published var isPostingComment = false
    @Published var errorMessage: String?
    
    init(postId: String) {
        self.postId = postId
    }
    
    func loadComments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            comments = try await PostsAPI.shared.getComments(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading comments: \(error)")
        }
        
        isLoading = false
    }
    
    func postComment() async {
        guard !commentText.isEmpty else { return }
        
        isPostingComment = true
        
        do {
            let newComment = try await PostsAPI.shared.createComment(postId: postId, text: commentText)
            comments.append(newComment)
            commentText = ""
            
            // Notify to refresh comment count in parent
            NotificationCenter.default.post(name: NSNotification.Name("RefreshReelComments"), object: nil)
        } catch {
            print("Error posting comment: \(error)")
        }
        
        isPostingComment = false
    }
    
    func deleteComment(commentId: String) async {
        do {
            try await PostsAPI.shared.deleteComment(commentId: commentId)
            
            // Remove from local array
            comments.removeAll { $0.id == commentId }
            
            // Notify to refresh comment count in parent
            NotificationCenter.default.post(name: NSNotification.Name("RefreshReelComments"), object: nil)
        } catch {
            print("Error deleting comment: \(error)")
        }
    }
}

