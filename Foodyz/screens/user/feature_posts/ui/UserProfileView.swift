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
            Color(hex: "#FFFBEA")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Picture
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
                                                .foregroundColor(.white)
                                        )
                                @unknown default:
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                }
                            }
                        } else {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#F59E0B"), Color(hex: "#EF4444")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(viewModel.user?.displayName.prefix(1).uppercased() ?? "U")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // Username & Full Name
                        VStack(spacing: 4) {
                            Text(viewModel.user?.displayName ?? "Loading...")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(hex: "#1F2937"))
                            
                            if let fullName = viewModel.user?.fullName {
                                Text(fullName)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Stats
                        HStack(spacing: 32) {
                            VStack(spacing: 4) {
                                Text("\(viewModel.posts.count)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(hex: "#1F2937"))
                                Text("Posts")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(spacing: 4) {
                                Text("\(viewModel.user?.followerCount ?? 0)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(hex: "#1F2937"))
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(spacing: 4) {
                                Text("\(viewModel.user?.followingCount ?? 0)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(hex: "#1F2937"))
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 32)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 8)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Tab Switcher
                    HStack(spacing: 0) {
                        Button(action: {
                            selectedTab = .posts
                        }) {
                            VStack(spacing: 4) {
                                Text("Posts")
                                    .font(.system(size: 16, weight: selectedTab == .posts ? .bold : .regular))
                                    .foregroundColor(selectedTab == .posts ? Color(hex: "#1F2937") : .gray)
                                
                                Rectangle()
                                    .fill(selectedTab == .posts ? Color(hex: "#F59E0B") : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            selectedTab = .saves
                        }) {
                            VStack(spacing: 4) {
                                Text("Saves")
                                    .font(.system(size: 16, weight: selectedTab == .saves ? .bold : .regular))
                                    .foregroundColor(selectedTab == .saves ? Color(hex: "#1F2937") : .gray)
                                
                                Rectangle()
                                    .fill(selectedTab == .saves ? Color(hex: "#F59E0B") : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 12)
                    
                    // Content based on selected tab
                    if selectedTab == .posts {
                        // Posts Grid
                        if viewModel.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(Color(hex: "#F59E0B"))
                                Text("Loading posts...")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else if viewModel.posts.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No posts yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
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
                                                // Navigate to all posts list view
                                                path.wrappedValue.append(Screen.userPostsList(userId))
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    } else {
                        // Saved Posts Grid
                        if viewModel.isLoadingSaves {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(Color(hex: "#F59E0B"))
                                Text("Loading saved posts...")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else if viewModel.savedPosts.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bookmark")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No saved posts yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
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
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(Color(hex: "#F59E0B"))
                }
            }
        }
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
    
    func loadUserProfile(userId: String) async {
        isLoading = true
        errorMessage = nil
        
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
            
            // Extract user info from first post
            if let firstPost = posts.first, let postOwner = firstPost.owner {
                user = postOwner
            }
            
        } catch {
            if let postsError = error as? PostsError {
                errorMessage = postsError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            print("Error loading user profile: \(error)")
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
}

// MARK: - Preview
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UserProfileView(userId: "sample-user-id", path: nil)
        }
    }
}
