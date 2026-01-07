import SwiftUI
import Combine

// MARK: - Comments Drawer View
struct CommentsDrawer: View {
    let postId: String
    let postCaption: String
    let likeCount: Int
    let commentCount: Int
    @Binding var isPresented: Bool
    @StateObject private var viewModel: CommentsDrawerViewModel
    @State private var editingCommentId: String?
    @State private var editingText: String = ""
    @FocusState private var isInputFocused: Bool
    
    init(postId: String, postCaption: String, likeCount: Int, commentCount: Int, isPresented: Binding<Bool>) {
        self.postId = postId
        self.postCaption = postCaption
        self.likeCount = likeCount
        self.commentCount = commentCount
        self._isPresented = isPresented
        _viewModel = StateObject(wrappedValue: CommentsDrawerViewModel(postId: postId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            // Header
            HStack {
                Text("Comments")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Post Summary
            VStack(alignment: .leading, spacing: 8) {
                Text(postCaption)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                Text("\(likeCount) likes \(commentCount) comments")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Comments List
            if viewModel.isLoading {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(Color(hex: "#F59E0B"))
                    Text("Loading comments...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                Spacer()
            } else if viewModel.comments.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No comments yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    Text("Be the first to comment!")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.comments) { comment in
                            CommentItemView(
                                comment: comment,
                                isEditing: editingCommentId == comment.id,
                                editingText: $editingText,
                                onEdit: {
                                    editingCommentId = comment.id
                                    editingText = comment.text
                                },
                                onSaveEdit: {
                                    Task {
                                        await viewModel.updateComment(commentId: comment.id, newText: editingText)
                                        editingCommentId = nil
                                        editingText = ""
                                    }
                                },
                                onCancelEdit: {
                                    editingCommentId = nil
                                    editingText = ""
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteComment(commentId: comment.id)
                                    }
                                }
                            )
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            
            // Comment Input
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    if let editingId = editingCommentId {
                        // Edit mode
                        TextField("Edit comment...", text: $editingText)
                            .focused($isInputFocused)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(25)
                        
                        Button(action: {
                            Task {
                                await viewModel.updateComment(commentId: editingId, newText: editingText)
                                editingCommentId = nil
                                editingText = ""
                            }
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(editingText.isEmpty ? Color.gray : Color(hex: "#F59E0B"))
                                .clipShape(Circle())
                        }
                        .disabled(editingText.isEmpty || viewModel.isUpdatingComment)
                        
                        Button(action: {
                            editingCommentId = nil
                            editingText = ""
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                                .frame(width: 40, height: 40)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                    } else {
                        // Add mode
                        TextField("Add a comment...", text: $viewModel.commentText)
                            .focused($isInputFocused)
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
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(viewModel.commentText.isEmpty ? Color.gray : Color(hex: "#F59E0B"))
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.commentText.isEmpty || viewModel.isPostingComment)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
            }
        }
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
        .onAppear {
            Task {
                await viewModel.loadComments()
            }
        }
        .onChange(of: isPresented) { newValue in
            if newValue {
                isInputFocused = false
            }
        }
    }
    
    private func hexColor(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Comment Item View
struct CommentItemView: View {
    let comment: Comment
    let isEditing: Bool
    @Binding var editingText: String
    let onEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    private let currentUserId = TokenManager.shared.getUserId()
    
    var isOwnComment: Bool {
        guard let currentUserId = currentUserId else {
            return false
        }
        // Check both new backend field (authorId) and legacy field (userId.id)
        let commentUserId = comment.authorId ?? comment.userId?.id ?? ""
        return currentUserId == commentUserId
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Profile Picture
            Group {
                let userInfo = comment.userInfo
                if let profileUrl = userInfo.profilePictureUrl,
                   let url = URL(string: profileUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure(_), .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Text(userInfo.displayName.prefix(1).uppercased())
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(userInfo.displayName.prefix(1).uppercased())
                                .font(.caption2)
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Comment Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(comment.userInfo.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(formatDate(comment.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                if isEditing {
                    TextField("Edit comment...", text: $editingText, axis: .vertical)
                        .font(.system(size: 14))
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Text(comment.text)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            // Action Buttons (only for own comments)
            if isOwnComment {
                if isEditing {
                    HStack(spacing: 8) {
                        Button(action: onSaveEdit) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(hex: "#F59E0B"))
                                .clipShape(Circle())
                        }
                        
                        Button(action: onCancelEdit) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                                .frame(width: 28, height: 28)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                } else {
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            showDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .alert("Delete Comment", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d"
        }
    }
    
    private func hexColor(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ViewModel
@MainActor
final class CommentsDrawerViewModel: ObservableObject {
    let postId: String
    @Published var comments: [Comment] = []
    @Published var commentText = ""
    @Published var isLoading = false
    @Published var isPostingComment = false
    @Published var isUpdatingComment = false
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
            print("❌ Error loading comments: \(error)")
        }
        
        isLoading = false
    }
    
    func postComment() async {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isPostingComment = true
        let textToPost = commentText
        commentText = "" // Clear immediately for better UX
        
        do {
            let newComment = try await PostsAPI.shared.createComment(postId: postId, text: textToPost)
            comments.append(newComment)
            
            // Notify to refresh comment count
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshPostCommentCount"),
                object: nil,
                userInfo: ["postId": postId]
            )
        } catch {
            errorMessage = error.localizedDescription
            commentText = textToPost // Restore on error
            print("❌ Error posting comment: \(error)")
        }
        
        isPostingComment = false
    }
    
    func updateComment(commentId: String, newText: String) async {
        guard !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isUpdatingComment = true
        
        do {
            // Try to update using PATCH endpoint
            let updatedComment = try await PostsAPI.shared.updateComment(commentId: commentId, text: newText)
            
            // Update the comment in the local array
            if let index = comments.firstIndex(where: { $0.id == commentId }) {
                comments[index] = updatedComment
            }
            
            // Notify to refresh
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshPostCommentCount"),
                object: nil,
                userInfo: ["postId": postId]
            )
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error updating comment: \(error)")
            // If update fails, fallback to delete and recreate
            do {
                try await PostsAPI.shared.deleteComment(commentId: commentId)
                comments.removeAll { $0.id == commentId }
                let newComment = try await PostsAPI.shared.createComment(postId: postId, text: newText)
                comments.append(newComment)
            } catch {
                print("❌ Error in fallback update: \(error)")
            }
        }
        
        isUpdatingComment = false
    }
    
    func deleteComment(commentId: String) async {
        do {
            try await PostsAPI.shared.deleteComment(commentId: commentId)
            comments.removeAll { $0.id == commentId }
            
            // Notify to refresh comment count
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshPostCommentCount"),
                object: nil,
                userInfo: ["postId": postId]
            )
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error deleting comment: \(error)")
        }
    }
}

