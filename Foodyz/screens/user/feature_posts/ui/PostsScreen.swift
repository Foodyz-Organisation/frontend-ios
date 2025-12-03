import SwiftUI
import Combine
import Combine

// MARK: - PostsScreen
struct PostsScreen: View {
    @StateObject private var viewModel = PostsViewModel()
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
                await viewModel.fetchPosts()
            }
        }
        .refreshable {
            await viewModel.fetchPosts()
        }
    }
}

// MARK: - PostsViewModel
@MainActor
class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchPosts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPosts = try await PostsAPI.shared.getAllPosts()
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
            print("Error fetching posts: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - RecipeCard
struct RecipeCard: View {
    let post: Post
    @State private var isFavorite = false
    @State private var isBookmarked = false
    @State private var showProfile = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Display actual image or thumbnail from post
                if let imageUrl = post.fullDisplayImageUrl, let url = URL(string: imageUrl) {
                    // If it's a video and the URL looks like a video file (no thumbnail from backend), use VideoThumbnailView
                    if post.isVideo && (imageUrl.hasSuffix(".mp4") || imageUrl.hasSuffix(".mov")) {
                        VideoThumbnailView(videoUrl: url)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(24, corners: [.topLeft, .topRight])
                    } else {
                        // Try loading as image
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(24, corners: [.topLeft, .topRight])
                            case .failure(_):
                                // Fallback for video if image load fails
                                if post.isVideo {
                                    VideoThumbnailView(videoUrl: url)
                                        .frame(height: 200)
                                        .clipped()
                                        .cornerRadius(24, corners: [.topLeft, .topRight])
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 200)
                                        .overlay(
                                            VStack {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.red)
                                                Text("Failed to load")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            }
                                        )
                                        .cornerRadius(24, corners: [.topLeft, .topRight])
                                }
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 200)
                                    .overlay(ProgressView())
                                    .cornerRadius(24, corners: [.topLeft, .topRight])
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                                    .cornerRadius(24, corners: [.topLeft, .topRight])
                            }
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(Text("No Image URL").foregroundColor(.white))
                        .cornerRadius(24, corners: [.topLeft, .topRight])
                }
                
                // User info badge (clickable)
                Button(action: {
                    if post.userId != nil {
                        showProfile = true
                    }
                }) {
                    HStack(spacing: 6) {
                        // User avatar
                        if let profileUrl = post.userId?.profilePictureUrl,
                           !profileUrl.isEmpty,
                           let url = URL(string: profileUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 24, height: 24)
                                        .clipShape(Circle())
                                case .failure(_), .empty:
                                    Circle()
                                        .fill(Color(hex: "#F59E0B"))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Text(post.userId?.username.prefix(1).uppercased() ?? "U")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                @unknown default:
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 24, height: 24)
                                }
                            }
                        } else {
                            Circle()
                                .fill(Color(hex: "#F59E0B"))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(post.userId?.username.prefix(1).uppercased() ?? "U")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        Text(post.userId?.username ?? "User")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#1F2937"))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .padding(12)
                }
                
                // Favorite icon
                HStack {
                    Spacer()
                    Button {
                        Task {
                            do {
                                try await PostsAPI.shared.likePost(postId: post.id)
                                isFavorite.toggle()
                                print("✅ Like toggled successfully")
                                // Refresh the posts feed to show updated like count
                                NotificationCenter.default.post(name: NSNotification.Name("RefreshPostsFeed"), object: nil)
                            } catch {
                                print("❌ Failed to toggle like: \(error)")
                            }
                        }
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .white)
                            .font(.system(size: 24))
                            .padding(12)
                    }
                }
                
                // Video indicator or rating badge
                VStack {
                    Spacer()
                    HStack {
                        if post.isVideo {
                            HStack(spacing: 4) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 12))
                                if let duration = post.duration {
                                    Text(formatDuration(duration))
                                        .font(.system(size: 12, weight: .medium))
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(12)
                        } else {
                            Label("\(post.likeCount)", systemImage: "heart.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                    .padding(12)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Title = caption (first line or truncated)
                Text(post.caption.components(separatedBy: "\n").first ?? post.caption)
                    .font(.system(size: 20, weight: .bold))
                    .lineLimit(2)
                
                // Subtitle = time ago
                Text(timeAgo(from: post.createdAt))
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray)
                
                // Tags = interaction counts
                HStack(spacing: 8) {
                    Text("❤️ \(post.likeCount)")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#E5E7EB"))
                        .cornerRadius(10)
                    
                    Text("💬 \(post.commentCount)")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#E5E7EB"))
                        .cornerRadius(10)
                    
                    if post.isVideo {
                        Text("👁️ \(formatCount(post.viewsCount))")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#E5E7EB"))
                            .cornerRadius(10)
                    }
                }
                
                HStack {
                    // Price = placeholder for now
                    Text("Free")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    HStack(spacing: 16) {
                        Image(systemName: "message")
                        Image(systemName: "square.and.arrow.up")
                        Image(systemName: "star")
                        Button { isBookmarked.toggle() } label: {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(isBookmarked ? Color(hex: "#4F46E5") : Color.gray)
                        }
                    }
                    .font(.system(size: 20))
                    .foregroundColor(Color.gray)
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(radius: 4)
        .navigationDestination(isPresented: $showProfile) {
            if let userId = post.userId?.id {
                UserProfileView(userId: userId)
            }
        }
    }
    
    // MARK: - Helper Functions
    
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
        PostsScreen()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
