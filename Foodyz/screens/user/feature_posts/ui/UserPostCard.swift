import SwiftUI

/// Card component for displaying user posts (Instagram-like)
struct UserPostCard: View {
    let post: Post
    @State private var isLiked: Bool
    @State private var isSaved: Bool
    @State private var saveCount: Int
    @State private var showShareDialog = false
    
    init(post: Post) {
        self.post = post
        // Initialize isLiked from LikesManager
        _isLiked = State(initialValue: LikesManager.shared.isLiked(postId: post.id))
        // Initialize isSaved from SavesManager
        _isSaved = State(initialValue: SavesManager.shared.isSaved(postId: post.id))
        _saveCount = State(initialValue: post.saveCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            mediaSection
            actionButtonsSection
            captionSection
            priceSection
            viewCountSection
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showShareDialog) {
            SharePostDialog(
                postId: post.id,
                onDismiss: { showShareDialog = false },
                onShareSuccess: {
                    // Optionally show success message
                }
            )
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            profilePictureView
            userInfoView
            Spacer()
            Text(timeAgo(from: post.createdAt))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var profilePictureView: some View {
        Group {
            if let profileUrl = post.owner?.profilePictureUrl, !profileUrl.isEmpty {
                if let url = URL(string: profileUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        case .failure(_), .empty:
                            fallbackProfileCircle
                        @unknown default:
                            fallbackProfileCircle
                        }
                    }
                } else {
                    gradientProfileCircle
                }
            } else {
                gradientProfileCircle
            }
        }
    }
    
    private var fallbackProfileCircle: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
            )
    }
    
    private var gradientProfileCircle: some View {
        let initial = post.owner?.displayName.prefix(1).uppercased() ?? "U"
        return Circle()
            .fill(LinearGradient(
                colors: [hexColor("#F59E0B"), hexColor("#EF4444")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 40, height: 40)
            .overlay(
                Text(initial)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(post.owner?.displayName ?? "Unknown User")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(hexColor("#1F2937"))
            
            if let fullName = post.owner?.fullName {
                Text(fullName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var mediaSection: some View {
        ZStack(alignment: .bottomLeading) {
            mediaImageView
            preparationTimeBadge
            videoIndicator
        }
    }
    
    @ViewBuilder
    private var mediaImageView: some View {
        if let imageUrl = post.fullDisplayImageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .clipped()
                case .failure(_):
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 400)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        )
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 400)
                        .overlay(ProgressView())
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 400)
                }
            }
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 400)
        }
    }
    
    @ViewBuilder
    private var preparationTimeBadge: some View {
        if let prepTime = post.preparationTime {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text("\(prepTime) minutes")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.9))
            .foregroundColor(hexColor("#1F2937"))
            .cornerRadius(12)
            .padding(12)
        }
    }
    
    @ViewBuilder
    private var videoIndicator: some View {
        if post.isVideo {
            VStack(alignment: .leading, spacing: 8) {
                if post.preparationTime == nil {
                    Spacer()
                }
                HStack(spacing: 4) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 12))
                    if let duration = post.duration {
                        Text(formatDuration(duration))
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(12)
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            likeButton
            commentButton
            shareButton
            Spacer()
            saveButton
        }
        .font(.system(size: 22))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var likeButton: some View {
        Button(action: {
            Task {
                await toggleLike()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : hexColor("#1F2937"))
                Text("\(currentLikeCount)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(hexColor("#1F2937"))
            }
        }
    }
    
    private var commentButton: some View {
        Button(action: {}) {
            HStack(spacing: 4) {
                Image(systemName: "bubble.right")
                    .foregroundColor(hexColor("#1F2937"))
                Text("\(post.commentCount)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(hexColor("#1F2937"))
            }
        }
    }
    
    private var shareButton: some View {
        Button(action: {
            showShareDialog = true
        }) {
            Image(systemName: "paperplane")
                .foregroundColor(hexColor("#1F2937"))
        }
    }
    
    private var saveButton: some View {
        let iconName = isSaved ? "bookmark.fill" : "bookmark"
        let iconColor: Color = isSaved ? hexColor("#F59E0B") : hexColor("#1F2937")
        return Button(action: {
            Task { await toggleSave() }
        }) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
        }
    }
    
    @ViewBuilder
    private var captionSection: some View {
        if !post.caption.isEmpty {
            HStack(alignment: .top, spacing: 4) {
                Text(post.owner?.displayName ?? "User")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(hexColor("#1F2937"))
                
                Text(post.caption)
                    .font(.system(size: 14))
                    .foregroundColor(hexColor("#1F2937"))
                    .lineLimit(3)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    @ViewBuilder
    private var priceSection: some View {
        if let price = post.price {
            HStack {
                Text("\(price, specifier: "%.1f") TND")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(hexColor("#1F2937"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    @ViewBuilder
    private var viewCountSection: some View {
        if post.isVideo, post.viewsCount > 0 {
            Text("\(formatCount(post.viewsCount)) views")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentLikeCount: Int {
        post.likeCount + (isLiked ? 1 : 0)
    }
    
    // MARK: - Actions
    
    private func toggleLike() async {
        // Optimistically update UI
        let previousLikedState = isLiked
        isLiked.toggle()
        
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
            // Notify parent to refresh
            NotificationCenter.default.post(name: NSNotification.Name("RefreshPostsFeed"), object: nil)
        } catch {
            // Revert optimistic update
            isLiked = previousLikedState
            
            // If error is conflict (already liked), it means user has already liked
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("already liked") || errorString.contains("conflict") {
                // User tried to like but already liked, so unlike it
                do {
                    _ = try await PostsAPI.shared.unlikePost(postId: post.id)
                    isLiked = false
                    LikesManager.shared.removeLike(postId: post.id)
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
            // Notify parent to refresh
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
    
    // MARK: - Helper Functions
    
    /// Format timestamp to "time ago" string
    private func timeAgo(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return "now"
        }
        
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h"
        } else if seconds < 604800 {
            let days = Int(seconds / 86400)
            return "\(days)d"
        } else {
            let weeks = Int(seconds / 604800)
            return "\(weeks)w"
        }
    }
    
    /// Format duration in seconds to MM:SS
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Format large numbers (e.g., 1.2K, 1.5M)
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
}

    // MARK: - Helper Functions
    
    // Helper function to avoid Color(hex:) ambiguity
    private func hexColor(_ hex: String) -> Color {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        return Color(red: r, green: g, blue: b)
    }

// MARK: - Preview
struct UserPostCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleOwner = Owner(
            id: "1",
            email: "foodlover@example.com",
            username: "foodlover",
            fullName: "Food Lover",
            profilePictureUrl: nil,
            followerCount: 150,
            followingCount: 200
        )
        
        let samplePost = Post(
            id: "1",
            ownerId: "1",
            owner: sampleOwner,
            ownerModel: .user,
            caption: "Check out this amazing dish! 🍕 #foodie",
            mediaUrls: [],
            mediaType: .image,
            likeCount: 42,
            commentCount: 8,
            saveCount: 15,
            thumbnailUrl: nil,
            viewsCount: 0,
            duration: nil,
            aspectRatio: "1:1",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            foodType: "Spicy",
            price: 30.0,
            preparationTime: 15
        )
        
        UserPostCard(post: samplePost)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
