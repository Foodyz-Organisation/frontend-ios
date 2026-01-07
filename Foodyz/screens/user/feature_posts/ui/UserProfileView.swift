import SwiftUI
import Combine

/// Basic user profile view showing user info and their posts
struct UserProfileView: View {
    let userId: String
    var path: Binding<NavigationPath>?
    @StateObject private var viewModel = UserProfileViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: UserProfileTab = .posts
    
    // Check if this is the current user's own profile
    var isOwnProfile: Bool {
        UserSession.shared.userId == userId
    }
    
    init(userId: String, path: Binding<NavigationPath>? = nil) {
        self.userId = userId
        self.path = path
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Custom Top Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text(viewModel.user?.displayName ?? "roua")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        if let path = path {
                            path.wrappedValue.append(Screen.settings)
                        }
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: - Beige Header Section
                        Rectangle()
                            .fill(Color(red: 0.93, green: 0.91, blue: 0.85))
                            .frame(height: 120)
                        
                        // MARK: - Profile Content
                        VStack(spacing: 16) {
                            // Profile Picture (overlapping beige section)
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 110, height: 110)
                                
                                if let user = viewModel.user,
                                   let profileUrl = user.profilePictureUrl,
                                   !profileUrl.isEmpty,
                                   let url = URL(string: profileUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                        case .failure(_), .empty:
                                            Circle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 100, height: 100)
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.gray)
                                                )
                                        @unknown default:
                                            Circle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 100, height: 100)
                                        }
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                        )
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.orange, lineWidth: 3)
                                    .frame(width: 100, height: 100)
                            )
                            .offset(y: -60)
                            .padding(.bottom, -60)
                            
                            // Username
                            Text("@\(viewModel.user?.displayName ?? "roua")")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            // Posts Count
                            VStack(spacing: 4) {
                                Text("\(viewModel.posts.count)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Posts")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            // Edit Profile Button
                            if isOwnProfile {
                                Button(action: {
                                    // Navigate to edit profile
                                }) {
                                    Text("Edit Profile")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.orange, Color(red: 1.0, green: 0.7, blue: 0.0)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                        }
                        .padding(.top, 20)
                        .background(Color.white)
                        
                        // MARK: - Tab Switcher
                        HStack(spacing: 0) {
                            Button(action: {
                                selectedTab = .posts
                            }) {
                                VStack(spacing: 8) {
                                    Text("Posts")
                                        .font(.system(size: 16, weight: selectedTab == .posts ? .bold : .medium))
                                        .foregroundColor(selectedTab == .posts ? .black : .gray)
                                    
                                    Rectangle()
                                        .fill(selectedTab == .posts ? Color.orange : Color.clear)
                                        .frame(height: 3)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            Button(action: {
                                selectedTab = .saves
                            }) {
                                VStack(spacing: 8) {
                                    Text("Saved")
                                        .font(.system(size: 16, weight: selectedTab == .saves ? .bold : .medium))
                                        .foregroundColor(selectedTab == .saves ? .black : .gray)
                                    
                                    Rectangle()
                                        .fill(selectedTab == .saves ? Color.orange : Color.clear)
                                        .frame(height: 3)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 24)
                        .background(Color.white)
                        
                        // MARK: - Content based on selected tab
                        if selectedTab == .posts {
                            // Posts Grid
                            if viewModel.isLoading {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(Color.orange)
                                    Text("Loading posts...")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 80)
                            } else if viewModel.posts.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 70))
                                        .foregroundColor(.gray.opacity(0.4))
                                    Text("No posts yet")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.gray)
                                    Text("Start sharing your moments")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 80)
                                .padding(.bottom, 100)
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2)
                                ], spacing: 2) {
                                    ForEach(viewModel.posts) { post in
                                        PostGridItem(post: post, isOwnProfile: isOwnProfile)
                                            .onTapGesture {
                                                if isOwnProfile, let path = path {
                                                    path.wrappedValue.append(Screen.userPostsList(userId))
                                                }
                                            }
                                    }
                                }
                                .padding(.top, 16)
                            }
                        } else {
                            // Saved Posts Grid
                            if viewModel.isLoadingSaves {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(Color.orange)
                                    Text("Loading saved posts...")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 80)
                            } else if viewModel.savedPosts.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 70))
                                        .foregroundColor(.gray.opacity(0.4))
                                    Text("No saved posts yet")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 80)
                                .padding(.bottom, 100)
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2)
                                ], spacing: 2) {
                                    ForEach(viewModel.savedPosts) { post in
                                        PostGridItem(post: post, isOwnProfile: false)
                                    }
                                }
                                .padding(.top, 16)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadUserProfile(userId: userId)
            }
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == .saves && viewModel.savedPosts.isEmpty && !viewModel.isLoadingSaves {
                Task {
                    await viewModel.loadSavedPosts()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshSavedPosts"))) { _ in
            if selectedTab == .saves {
                Task {
                    await viewModel.loadSavedPosts()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshUserPosts"))) { _ in
            Task {
                await viewModel.loadUserProfile(userId: userId)
            }
        }
    }
}

// MARK: - Post Grid Item
struct PostGridItem: View {
    let post: Post
    let isOwnProfile: Bool
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let imageUrl = post.fullDisplayImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width / 3 - 6, height: UIScreen.main.bounds.width / 3 - 6)
                            .clipped()
                    case .failure(_), .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: UIScreen.main.bounds.width / 3 - 6, height: UIScreen.main.bounds.width / 3 - 6)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: UIScreen.main.bounds.width / 3 - 6, height: UIScreen.main.bounds.width / 3 - 6)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: UIScreen.main.bounds.width / 3 - 6, height: UIScreen.main.bounds.width / 3 - 6)
            }
            
            // Video indicator
            if post.isVideo {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.white)
                    .font(.title3)
                    .padding(8)
                    .shadow(radius: 2)
            }
        }
    }
}

// MARK: - User Profile Tab
enum UserProfileTab {
    case posts
    case saves
}

// MARK: - UserProfileViewModel
@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var user: Owner?
    @Published var posts: [Post] = []
    @Published var savedPosts: [Post] = []
    @Published var isLoading = false
    @Published var isLoadingSaves = false
    @Published var errorMessage: String?
    
    private let userAPI = UserAPI.shared
    
    func loadUserProfile(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        // 1. Fetch User Profile directly from API
        do {
            let userProfileDto = try await userAPI.fetchProfile(userId: userId)
            self.user = mapDtoToOwner(dto: userProfileDto)
        } catch {
            print("Error loading user profile details: \(error)")
            // Fallback: don't stop, try loading posts which might contain owner info
        }
        
        // 2. Fetch User Posts
        do {
            // Fetch all posts and filter by ownerId
            let allPosts = try await PostsAPI.shared.getAllPosts()
            
            // Filter posts belonging to this user
            let userPosts = allPosts.filter { $0.ownerId == userId }
            
            // Sort by creation date (newest first)
            posts = userPosts.sorted { post1, post2 in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                let date1 = formatter.date(from: post1.createdAt) ?? Date.distantPast
                let date2 = formatter.date(from: post2.createdAt) ?? Date.distantPast
                
                return date1 > date2
            }
            
            // If we failed to fetch user profile earlier (e.g. API error), try to extract from posts
            if self.user == nil, let firstPost = posts.first, let postOwner = firstPost.owner {
                self.user = postOwner
            }
            
        } catch {
            if let postsError = error as? PostsError {
                errorMessage = postsError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            print("Error loading user posts: \(error)")
        }
        
        isLoading = false
    }
    
    func loadSavedPosts() async {
        isLoadingSaves = true
        errorMessage = nil
        
        do {
            savedPosts = try await PostsAPI.shared.getSavedPosts()
        } catch {
            if let postsError = error as? PostsError {
                errorMessage = postsError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            print("Error loading saved posts: \(error)")
        }
        
        isLoadingSaves = false
    }
    
    /// Helper to convert UserProfileDTO to Owner struct
    private func mapDtoToOwner(dto: UserProfileDTO) -> Owner {
        // Prioritize uploaded avatar, fallback to Google profile picture
        let rawUrl = dto.avatarUrl ?? dto.profilePictureUrl
        let finalUrl = sanitizeURL(rawUrl)
        
        return Owner(
            id: dto.id,
            email: dto.email,
            username: dto.username,
            fullName: nil, // DTO doesn't have fullName yet
            profilePictureUrl: finalUrl,
            followerCount: 0,
            followingCount: 0
        )
    }
    
    /// Helper: Sanitize URL for iOS (localhost/relative paths)
    private func sanitizeURL(_ urlString: String?) -> String? {
        guard let urlString = urlString, !urlString.isEmpty else { return nil }
        
        // Pass through data URIs (Base64 images) untouched
        if urlString.hasPrefix("data:") {
            return urlString
        }
        
        // If it's already a full web URL (http/https)
        if urlString.hasPrefix("http") {
             // Fix Android Emulator localhost (10.0.2.2) -> iOS localhost (127.0.0.1)
            return urlString.replacingOccurrences(of: "10.0.2.2", with: "127.0.0.1")
        }
        
        // If it's a relative path, prepend the base URL
        // Assuming backend is at http://127.0.0.1:3000
        let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
        return "http://127.0.0.1:3000/\(cleanPath)"
    }
}

// MARK: - Preview
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UserProfileView(userId: "sample-user-id", path: nil)
        }
    }
}
