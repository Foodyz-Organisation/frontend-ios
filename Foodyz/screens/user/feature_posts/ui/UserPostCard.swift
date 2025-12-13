import SwiftUI

/// Card component for displaying user posts (Instagram-like)
struct UserPostCard: View {
    let post: Post
    @State private var isLiked: Bool
    
    init(post: Post) {
        self.post = post
        // Initialize isLiked from LikesManager
        _isLiked = State(initialValue: LikesManager.shared.isLiked(postId: post.id))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header (User info)
            HStack(spacing: 12) {
                // Profile picture
                if let profileUrl = post.owner?.profilePictureUrl, !profileUrl.isEmpty, let url = URL(string: profileUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        case .failure(_), .empty:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                        }
                    }
                } else {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#F59E0B"), Color(hex: "#EF4444")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(post.owner?.displayName.prefix(1).uppercased() ?? "U")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.owner?.displayName ?? "Unknown User")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#1F2937"))
                    
                    if let fullName = post.owner?.fullName {
                        Text(fullName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Time ago
                Text(timeAgo(from: post.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // MARK: - Media
            ZStack(alignment: .bottomLeading) {
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
                                .overlay(
                                    ProgressView()
                                )
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
                
                // Preparation Time Badge (if available) - top leading
                if let prepTime = post.preparationTime {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("\(prepTime) minutes")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(Color(hex: "#1F2937"))
                    .cornerRadius(12)
                    .padding(12)
                }
                
                // Video indicator - bottom leading (if no prep time) or below it
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
            
            // MARK: - Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        await toggleLike()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : Color(hex: "#1F2937"))
                        Text("\(currentLikeCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#1F2937"))
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(Color(hex: "#1F2937"))
                        Text("\(post.commentCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#1F2937"))
                    }
                }
                
                Button(action: {}) {
                    Image(systemName: "paperplane")
                        .foregroundColor(Color(hex: "#1F2937"))
                }
                
                Spacer()
            }
            .font(.system(size: 22))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // MARK: - Caption
            if !post.caption.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Text(post.owner?.displayName ?? "User")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#1F2937"))
                    
                    Text(post.caption)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#1F2937"))
                        .lineLimit(3)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            // MARK: - Price (if available)
            if let price = post.price {
                HStack {
                    Text("\(price, specifier: "%.1f") TND")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#1F2937"))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            // MARK: - View count (for videos)
            if post.isVideo, post.viewsCount > 0 {
                Text("\(formatCount(post.viewsCount)) views")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
            // So we should unlike it instead
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("already liked") || errorString.contains("conflict") {
                // User tried to like but already liked, so unlike it
                do {
                    _ = try await PostsAPI.shared.unlikePost(postId: post.id)
                    isLiked = false
                    LikesManager.shared.removeLike(postId: post.id)
                    // Notify parent to refresh
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshPostsFeed"), object: nil)
                } catch {
                    print("Error unliking after conflict: \(error)")
                }
            } else {
                print("Error toggling like: \(error)")
            }
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
