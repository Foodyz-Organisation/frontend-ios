import SwiftUI
import Combine

// MARK: - PostsScreen
struct PostsScreen: View {
    @ObservedObject var viewModel: PostsViewModel
    @Binding var selectedFoodType: String?
    var onPostClick: ((String) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Ready to be ordered 🍽️")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "#1F2937"))
                .padding(.bottom, 8)
                .padding(.horizontal, 16)
            
            // Display posts or loading/error state
            if viewModel.isLoading && viewModel.posts.isEmpty {
                // Initial loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color(hex: "#F59E0B"))
                    Text("Loading posts...")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else if let error = viewModel.errorMessage, viewModel.posts.isEmpty {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Failed to load posts")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await viewModel.fetchPosts()
                        }
                    }
                    .foregroundColor(Color(hex: "#F59E0B"))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else if viewModel.posts.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No posts yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Be the first to share something!")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                // Posts list
                VStack(spacing: 20) {
                    ForEach(viewModel.posts) { post in
                        RecipeCard(post: post)
                            .onTapGesture {
                                onPostClick?(post.id)
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .onAppear {
            Task {
                await viewModel.fetchPosts()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshPostsFeed"))) { _ in
            Task {
                if selectedFoodType == nil {
                    await viewModel.fetchPosts()
                } else if let foodType = selectedFoodType {
                    await viewModel.fetchPostsByFoodType(foodType)
                }
            }
        }
        .refreshable {
            if selectedFoodType == nil {
                await viewModel.fetchPosts()
            } else if let foodType = selectedFoodType {
                await viewModel.fetchPostsByFoodType(foodType)
            }
        }
    }
}

// MARK: - PostsViewModel
@MainActor
class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var foodTypes: [String] = []
    @Published var isLoadingFoodTypes = false
    
    init() {
        Task {
            await fetchFoodTypes()
        }
    }
    
    /// Fetch personalized posts (Cosign Formulary)
    /// Backend returns posts ordered by user preferences based on interactions
    /// No manual sorting needed - backend handles prioritization
    func fetchPosts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Backend returns posts already ordered by:
            // 1. Posts from food categories user has interacted with (first)
            // 2. Other posts (after)
            // No need to sort manually - backend handles prioritization
            let fetchedPosts = try await PostsAPI.shared.getAllPosts()
            posts = fetchedPosts
            print("✅ [PostsViewModel] Fetched \(fetchedPosts.count) personalized posts")
        } catch {
            if let postsError = error as? PostsError {
                errorMessage = postsError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            print("❌ [PostsViewModel] Error fetching posts: \(error)")
        }
        
        isLoading = false
    }
    
    func fetchPostsByFoodType(_ foodType: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPosts = try await PostsAPI.shared.getPostsByFoodType(foodType)
            // Sort by creation date (newest first)
            posts = fetchedPosts.sorted { post1, post2 in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                let date1 = formatter.date(from: post1.createdAt) ?? Date.distantPast
                let date2 = formatter.date(from: post2.createdAt) ?? Date.distantPast
                
                return date1 > date2
            }
        } catch {
            if let postsError = error as? PostsError {
                errorMessage = postsError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            print("Error fetching posts by food type: \(error)")
        }
        
        isLoading = false
    }
    
    func fetchFoodTypes() async {
        isLoadingFoodTypes = true
        do {
            foodTypes = try await PostsAPI.shared.getFoodTypes()
        } catch {
            print("Failed to fetch food types: \(error.localizedDescription)")
        }
        isLoadingFoodTypes = false
    }
}

// MARK: - RecipeCard
struct RecipeCard: View {
    let post: Post
    @State private var isFavorite: Bool
    @State private var isSaved: Bool
    @State private var saveCount: Int
    @State private var commentCount: Int
    @State private var showProfile = false
    @State private var showShareDialog = false
    @State private var showCommentsDrawer = false
    
    init(post: Post) {
        self.post = post
        // Initialize isFavorite from LikesManager
        _isFavorite = State(initialValue: LikesManager.shared.isLiked(postId: post.id))
        // Initialize isSaved from SavesManager
        _isSaved = State(initialValue: SavesManager.shared.isSaved(postId: post.id))
        _saveCount = State(initialValue: post.saveCount)
        _commentCount = State(initialValue: post.commentCount)
    }
    
    private var cardWidth: CGFloat {
        UIScreen.main.bounds.width - 40 // Substract padding (20 + 20)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Top: Image with Overlay
            ZStack(alignment: .topLeading) {
                // Image Section
                if let imageUrl = post.fullDisplayImageUrl, let url = URL(string: imageUrl) {
                    if post.isVideo && (imageUrl.hasSuffix(".mp4") || imageUrl.hasSuffix(".mov")) {
                        VideoThumbnailView(videoUrl: url)
                            .frame(width: cardWidth) // Constrain width
                            .frame(height: 300)
                            .clipped()
                    } else {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: cardWidth) // Constrain width
                                    .frame(height: 300)
                                    .clipped()
                            case .failure(_):
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: cardWidth)
                                    .frame(height: 300)
                                    .overlay(Image(systemName: "exclamationmark.triangle").foregroundColor(.red))
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: cardWidth)
                                    .frame(height: 300)
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: cardWidth)
                                    .frame(height: 300)
                            }
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: cardWidth)
                        .frame(height: 300)
                        .overlay(Text("No Image").foregroundColor(.white))
                }
                
                // User Pill Overlay (Top Left)
                HStack(spacing: 8) {
                    if let displayName = post.owner?.displayName {
                         // User avatar
                         Group {
                             if let profileUrl = post.owner?.profilePictureUrl,
                                let url = URL(string: profileUrl) {
                                 AsyncImage(url: url) { image in
                                     image.resizable().aspectRatio(contentMode: .fill)
                                 } placeholder: {
                                     Color.gray
                                 }
                             } else {
                                 Circle().fill(Color.gray)
                             }
                         }
                         .frame(width: 32, height: 32)
                         .clipShape(Circle())
                         
                        Text(displayName)
                             .font(.system(size: 14, weight: .bold))
                             .foregroundColor(Color.black)
                    } else {
                        // Fallback
                        Circle().fill(Color.gray).frame(width: 32, height: 32)
                        Text("Foodyz Chef")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.black)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.95))
                .clipShape(Capsule())
                .padding(12) // Padding from the edges of the card
                .onTapGesture {
                    if post.owner != nil {
                        showProfile = true
                    }
                }
            }
            .frame(width: cardWidth) // Ensure ZStack is constrained
            .background(Color.gray.opacity(0.1))
            
            // MARK: - Bottom: Actions & Details
            VStack(alignment: .leading, spacing: 10) {
                // Action Icons Row
                HStack(spacing: 20) {
                    // Like Button
                    Button {
                        Task { await toggleLike() }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor(isFavorite ? Color(hex: "#F59E0B") : .black)
                    }
                    
                    // Comment Button
                    Button(action: {
                        showCommentsDrawer = true
                    }) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                    }
                    
                    // Share Button
                    Button(action: {
                        showShareDialog = true
                    }) {
                        Image(systemName: "paperplane")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    // Bookmark Button
                    Button(action: {
                        Task { await toggleSave() }
                    }) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 22))
                            .foregroundColor(isSaved ? Color(hex: "#F59E0B") : .black)
                    }
                }
                .padding(.top, 4)
                
                // Likes Count
                Text("\(post.likeCount) likes")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                
                // Comment Count (tappable)
                Button(action: {
                    showCommentsDrawer = true
                }) {
                    Text("\(commentCount) comments")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Save Count (if saved)
                if saveCount > 0 {
                    Text("\(saveCount) saves")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                // Caption / Description
                if !post.caption.isEmpty {
                    Text(post.caption)
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .lineLimit(2)
                }
            }
            .padding(16)
        }
        .frame(width: cardWidth) // Fix the main card width
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .navigationDestination(isPresented: $showProfile) {
            if let userId = post.owner?.id {
                UserProfileView(userId: userId)
            }
        }
        .sheet(isPresented: $showShareDialog) {
            SharePostDialog(
                postId: post.id,
                onDismiss: { showShareDialog = false },
                onShareSuccess: {
                    // Optionally show success message
                }
            )
        }
        .sheet(isPresented: $showCommentsDrawer) {
            CommentsDrawer(
                postId: post.id,
                postCaption: post.caption,
                likeCount: post.likeCount,
                commentCount: commentCount,
                isPresented: $showCommentsDrawer
            )
            .presentationDetents([.large, .medium])
            .presentationDragIndicator(.visible)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshPostCommentCount"))) { notification in
                if let userInfo = notification.userInfo,
                   let refreshedPostId = userInfo["postId"] as? String,
                   refreshedPostId == post.id {
                    // Refresh comment count
                    Task {
                        await refreshCommentCount()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func refreshCommentCount() async {
        do {
            let updatedPost = try await PostsAPI.shared.getPost(id: post.id)
            await MainActor.run {
                commentCount = updatedPost.commentCount
            }
        } catch {
            print("Error refreshing comment count: \(error)")
        }
    }
    
    private func timeAgo(from dateString: String) -> String {
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
            return "\(minutes) min ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if seconds < 604800 {
            let days = Int(seconds / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else {
            let weeks = Int(seconds / 604800)
            return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
        }
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count < 1000 {
            return "\(count)"
        } else if count < 1_000_000 {
            let k = Double(count) / 1000.0
            return String(format: "%.1fK", k)
        } else {
            let m = Double(count) / 1_000_000.0
            return String(format: "%.1fM", m)
        }
    }
    
    // MARK: - Actions
    
    private func toggleLike() async {
        // Optimistically update UI
        let previousLikedState = isFavorite
        isFavorite.toggle()
        
        do {
            if previousLikedState {
                // Unlike
                _ = try await PostsAPI.shared.unlikePost(postId: post.id)
                LikesManager.shared.removeLike(postId: post.id)
            } else {
                // Like
                _ = try await PostsAPI.shared.likePost(postId: post.id)
                LikesManager.shared.addLike(postId: post.id)
            }
            // Refresh the posts feed to show updated like count
            NotificationCenter.default.post(name: NSNotification.Name("RefreshPostsFeed"), object: nil)
        } catch {
            // Revert optimistic update
            isFavorite = previousLikedState
            
            // If error is conflict (already liked), it means user has already liked
            // So we should unlike it instead
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("already liked") || errorString.contains("conflict") {
                // User tried to like but already liked, so unlike it
                do {
                    _ = try await PostsAPI.shared.unlikePost(postId: post.id)
                    isFavorite = false
                    LikesManager.shared.removeLike(postId: post.id)
                    // Refresh the posts feed
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshPostsFeed"), object: nil)
                } catch {
                    print("Error unliking after conflict: \(error)")
                }
            } else {
                print("❌ Failed to toggle like: \(error)")
            }
        }
    }
    
    private func toggleSave() async {
        // Optimistically update UI
        let previousSavedState = isSaved
        isSaved.toggle()
        
        if isSaved {
            saveCount += 1
            SavesManager.shared.addSave(postId: post.id)
        } else {
            saveCount = max(0, saveCount - 1)
            SavesManager.shared.removeSave(postId: post.id)
        }
        
        do {
            if previousSavedState {
                // Unsave
                let updatedPost = try await PostsAPI.shared.unsavePost(postId: post.id)
                saveCount = updatedPost.saveCount
            } else {
                // Save
                let updatedPost = try await PostsAPI.shared.savePost(postId: post.id)
                saveCount = updatedPost.saveCount
            }
            // Refresh the posts feed to show updated save count
            NotificationCenter.default.post(name: NSNotification.Name("RefreshPostsFeed"), object: nil)
        } catch {
            // Revert optimistic update
            isSaved = previousSavedState
            if previousSavedState {
                saveCount += 1
                SavesManager.shared.addSave(postId: post.id)
            } else {
                saveCount = max(0, saveCount - 1)
                SavesManager.shared.removeSave(postId: post.id)
            }
            print("❌ Failed to toggle save: \(error)")
        }
    }
}


// MARK: - Helpers (Redefined here for PostsScreen to be self-contained as per your prompt)
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 0.0
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
struct PostsScreen_Previews: PreviewProvider {
    static var previews: some View {
        PostsScreen(
            viewModel: PostsViewModel(),
            selectedFoodType: .constant(nil)
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
