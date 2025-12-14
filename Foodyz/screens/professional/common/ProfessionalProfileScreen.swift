import SwiftUI
import Combine

// MARK: - Professional Profile Screen

struct ProfessionalProfileScreen: View {
    let professionalId: String
    var onPostTap: ((String) -> Void)? = nil  // Callback for post tap
    @StateObject private var viewModel = ProfessionalProfilePostsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: ProfileTab = .about
    
    var body: some View {
        ZStack {
            Color.foodyzBackground
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Cover Image with Overlay
                    ZStack(alignment: .topLeading) {
                        // Cover Image
                        Image(systemName: "photo.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 280)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.2, green: 0.15, blue: 0.1), Color(red: 0.4, green: 0.3, blue: 0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipped()
                        
                        // Top Controls
                        HStack {
                            Button(action: { dismiss() }) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.black)
                                            .font(.system(size: 18, weight: .semibold))
                                    )
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: {}) {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "bookmark")
                                                .foregroundColor(.black)
                                                .font(.system(size: 18))
                                        )
                                }
                                
                                Button(action: {}) {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "square.and.arrow.up")
                                                .foregroundColor(.black)
                                                .font(.system(size: 18))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 50)
                        
                        // Restaurant Name at Bottom
                        VStack {
                            Spacer()
                            HStack {
                                Text("Chili's")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }
                    }
                    .frame(height: 280)
                    
                    // Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        // Rating, Price, Tags
                        HStack(spacing: 12) {
                            // Rating
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(Color(hex: "#F59E0B"))
                                    .font(.system(size: 16))
                                Text("4.7")
                                    .font(.system(size: 16, weight: .bold))
                                Text("(1243)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(20)
                            
                            // Price
                            Text("$$")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .cornerRadius(20)
                            
                            // Cuisine
                            Text("Italian, Pizza, Pasta")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .cornerRadius(20)
                        }
                        
                        // Service Options
                        HStack(spacing: 12) {
                            ServiceOptionCard(
                                icon: "box.truck.fill",
                                title: "Delivery",
                                subtitle: "30-45 min",
                                bgColor: Color(red: 1.0, green: 0.98, blue: 0.92)
                            )
                            
                            ServiceOptionCard(
                                icon: "bag.fill",
                                title: "Takeaway",
                                subtitle: "Ready in 15 min",
                                bgColor: Color(red: 1.0, green: 0.95, blue: 0.95)
                            )
                            
                            ServiceOptionCard(
                                icon: "fork.knife",
                                title: "Dine-in",
                                subtitle: "Available",
                                bgColor: Color(red: 1.0, green: 0.94, blue: 1.0)
                            )
                        }
                        
                        // CTA Buttons
                        HStack(spacing: 12) {
                            Button(action: {}) {
                                Text("View Menu & Order")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(hex: "#FF6B00"), Color(hex: "#FF4500")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "heart")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                                    .frame(width: 50, height: 50)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Contact Info
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(Color(hex: "#FF6B00"))
                                    .font(.system(size: 20))
                                Text("123 Avenue Habib Bourguiba, Tunis")
                                    .font(.system(size: 15))
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "phone.circle.fill")
                                    .foregroundColor(Color(hex: "#FF6B00"))
                                    .font(.system(size: 20))
                                Text("+216 71 123 456")
                                    .font(.system(size: 15))
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "clock.circle.fill")
                                    .foregroundColor(Color(hex: "#FF6B00"))
                                    .font(.system(size: 20))
                                Text("10:00 AM - 11:00 PM")
                                    .font(.system(size: 15))
                                Spacer()
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(red: 1.0, green: 0.98, blue: 0.92))
                        .cornerRadius(12)
                        
                        // Tab Selector
                        HStack(spacing: 0) {
                            TabButton(title: "About", isSelected: selectedTab == .about) {
                                selectedTab = .about
                            }
                            TabButton(title: "Reels", isSelected: selectedTab == .reels) {
                                selectedTab = .reels
                            }
                            TabButton(title: "Photos", isSelected: selectedTab == .photos) {
                                selectedTab = .photos
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Tab Content
                        Group {
                            if selectedTab == .about {
                                AboutTabContent()
                            } else if selectedTab == .reels {
                                ReelsTabContent(posts: viewModel.videoPosts, onPostTap: onPostTap)
                            } else {
                                PhotosTabContent(posts: viewModel.imagePosts, onPostTap: onPostTap)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .offset(y: -24)
                }
            }
            .edgesIgnoringSafeArea(.top)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                await viewModel.loadProfessionalPosts(professionalId: professionalId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshPostsFeed"))) { _ in
            Task {
                await viewModel.loadProfessionalPosts(professionalId: professionalId)
            }
        }
    }
}

// MARK: - Service Option Card

struct ServiceOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let bgColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "#FF6B00"))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(bgColor)
        .cornerRadius(12)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color(hex: "#FF6B00") : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isSelected {
                            Color(hex: "#FF6B00").opacity(0.1)
                        } else {
                            Color.clear
                        }
                    }
                )
        }
    }
}

// MARK: - Profile Tabs

enum ProfileTab {
    case about, reels, photos
}

// MARK: - Tab Content Views

struct AboutTabContent: View {
    var body: some View {
        Text("Experience authentic Italian cuisine in the heart of Tunis. Our chefs use only the freshest ingredients to create traditional dishes with a modern twist. From wood-fired pizzas to homemade pasta, each dish is crafted with passion and care.")
            .font(.system(size: 15))
            .foregroundColor(.gray)
            .lineSpacing(4)
            .padding(.vertical, 8)
    }
}

struct ReelsTabContent: View {
    let posts: [Post]
    var onPostTap: ((String) -> Void)? = nil
    
    var body: some View {
        if posts.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "video.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.5))
                Text("No reels yet")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ], spacing: 2) {
                ForEach(posts) { post in
                    MediaGridItem(post: post, showVideoIndicator: true)
                        .onTapGesture {
                            onPostTap?(post.id)
                        }
                }
            }
        }
    }
}

struct PhotosTabContent: View {
    let posts: [Post]
    var onPostTap: ((String) -> Void)? = nil
    
    var body: some View {
        if posts.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.5))
                Text("No photos yet")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ], spacing: 2) {
                ForEach(posts) { post in
                    MediaGridItem(post: post, showVideoIndicator: false)
                        .onTapGesture {
                            onPostTap?(post.id)
                        }
                }
            }
        }
    }
}

// MARK: - Media Grid Item

struct MediaGridItem: View {
    let post: Post
    let showVideoIndicator: Bool
    
    private let itemSize: CGFloat = (UIScreen.main.bounds.width - 36) / 3
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // For videos: check if we have a server thumbnail, otherwise generate one
            if post.isVideo {
                if let thumbnailUrl = post.thumbnailUrl,
                   !thumbnailUrl.isEmpty,
                   let url = URL(string: thumbnailUrl.replacingOccurrences(of: "10.0.2.2", with: "192.168.100.28")) {
                    // Use server-generated thumbnail
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: itemSize, height: itemSize)
                                .clipped()
                        case .failure(_), .empty:
                            // Fallback to client-side thumbnail generation
                            videoThumbnailFallback
                        @unknown default:
                            videoThumbnailFallback
                        }
                    }
                } else {
                    // No server thumbnail - generate on client
                    videoThumbnailFallback
                }
            } else {
                // For images: use AsyncImage directly
                if let imageUrl = post.fullDisplayImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: itemSize, height: itemSize)
                                .clipped()
                        case .failure(_):
                            imagePlaceholder
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: itemSize, height: itemSize)
                                .overlay(ProgressView())
                        @unknown default:
                            imagePlaceholder
                        }
                    }
                } else {
                    imagePlaceholder
                }
            }
            
            // Video indicator
            if showVideoIndicator {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 24))
                    .shadow(radius: 2)
                    .padding(8)
            }
        }
    }
    
    // Fallback: Generate thumbnail from video URL on client
    @ViewBuilder
    private var videoThumbnailFallback: some View {
        if let videoUrlString = post.mediaUrls.first,
           let videoUrl = URL(string: videoUrlString.replacingOccurrences(of: "10.0.2.2", with: "192.168.100.28")) {
            VideoThumbnailView(videoUrl: videoUrl)
                .frame(width: itemSize, height: itemSize)
                .clipped()
        } else {
            imagePlaceholder
        }
    }
    
    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: itemSize, height: itemSize)
            .overlay(
                Image(systemName: post.isVideo ? "video.slash" : "photo")
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - ViewModel

@MainActor
class ProfessionalProfilePostsViewModel: ObservableObject {
    @Published var allPosts: [Post] = []
    @Published var videoPosts: [Post] = []
    @Published var imagePosts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadProfessionalPosts(professionalId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("📍 Loading posts for professional: \(professionalId)")
            
            // Fetch all posts and filter by ownerId
            let fetchedPosts = try await PostsAPI.shared.getAllPosts()
            
            // Filter posts belonging to this professional
            allPosts = fetchedPosts.filter { $0.ownerId == professionalId }
            
            // Sort by creation date (newest first)
            allPosts.sort { post1, post2 in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let date1 = formatter.date(from: post1.createdAt) ?? Date.distantPast
                let date2 = formatter.date(from: post2.createdAt) ?? Date.distantPast
                return date1 > date2
            }
            
            // Filter posts by media type
            videoPosts = allPosts.filter { $0.isVideo }
            imagePosts = allPosts.filter { !$0.isVideo }
            
            print("✅ Loaded \(allPosts.count) posts for professional: \(videoPosts.count) videos, \(imagePosts.count) images")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load professional posts: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Preview

struct ProfessionalProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProfessionalProfileScreen(professionalId: "123")
    }
}
