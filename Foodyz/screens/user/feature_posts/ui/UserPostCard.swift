import SwiftUI

/// Card component for displaying user posts (Instagram-like)
struct UserPostCard: View {
    let post: Post
    @State private var isLiked = false
    @State private var isBookmarked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header (User info)
            HStack(spacing: 12) {
                // Profile picture
                if let profileUrl = post.userId?.profilePictureUrl, !profileUrl.isEmpty, let url = URL(string: profileUrl) {
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
                            Text(post.userId?.username.prefix(1).uppercased() ?? "U")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userId?.username ?? "Unknown User")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#1F2937"))
                    
                    if let fullName = post.userId?.fullName {
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
                
                // Video indicator
                if post.isVideo {
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
                    .padding(12)
                }
            }
            
            // MARK: - Action Buttons
            HStack(spacing: 16) {
                Button(action: { isLiked.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : Color(hex: "#1F2937"))
                        Text("\(post.likeCount + (isLiked ? 1 : 0))")
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
                
                Button(action: { isBookmarked.toggle() }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isBookmarked ? Color(hex: "#F59E0B") : Color(hex: "#1F2937"))
                }
            }
            .font(.system(size: 22))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // MARK: - Caption
            if !post.caption.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Text(post.userId?.username ?? "User")
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
        let sampleUser = User(
            id: "1",
            username: "foodlover",
            fullName: "Food Lover",
            profilePictureUrl: nil,
            followerCount: 150,
            followingCount: 200
        )
        
        let samplePost = Post(
            id: "1",
            userId: sampleUser,
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
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        UserPostCard(post: samplePost)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
