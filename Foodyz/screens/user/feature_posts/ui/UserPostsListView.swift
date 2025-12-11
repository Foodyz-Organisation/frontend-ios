import SwiftUI
import AVKit
import Combine

// MARK: - User Posts List View
struct UserPostsListView: View {
    let userId: String
    let initialPostId: String? // The post that was tapped to open this view
    @Binding var path: NavigationPath
    @StateObject private var viewModel = UserPostsListViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var selectedPostForComments: String?
    
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.97, blue: 1.0)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if viewModel.posts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No posts yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.posts) { post in
                            UserPostDetailCard(
                                post: post,
                                onEdit: {
                                    path.append(Screen.editPost(post.id))
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deletePost(postId: post.id)
                                    }
                                },
                                onCommentsTap: {
                                    selectedPostForComments = post.id
                                }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("All Posts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { path.removeLast() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                }
            }
        }
        .alert("Delete Post", isPresented: $viewModel.showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let postIdToDelete = viewModel.postIdToDelete {
                    Task {
                        await viewModel.confirmDeletePost(postId: postIdToDelete)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .onAppear {
            Task {
                await viewModel.loadUserPosts(userId: userId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshUserPosts"))) { _ in
            Task {
                await viewModel.loadUserPosts(userId: userId)
            }
        }
        .sheet(item: Binding(
            get: { selectedPostForComments.map { PostIdWrapper(id: $0) } },
            set: { selectedPostForComments = $0?.id }
        )) { wrapper in
            NavigationStack {
                ReelCommentsView(postId: wrapper.id)
            }
        }
    }
}

// Helper struct for sheet binding
struct PostIdWrapper: Identifiable {
    let id: String
}

// MARK: - ViewModel
@MainActor
class UserPostsListViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showDeleteAlert = false
    @Published var postIdToDelete: String?
    
    func loadUserPosts(userId: String) async {
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
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading user posts: \(error)")
        }
        
        isLoading = false
    }
    
    func deletePost(postId: String) async {
        postIdToDelete = postId
        showDeleteAlert = true
    }
    
    func confirmDeletePost(postId: String) async {
        isLoading = true
        
        do {
            try await PostsAPI.shared.deletePost(postId: postId)
            
            // Remove from local array
            posts.removeAll { $0.id == postId }
            
            // Notify to refresh posts in profile
            NotificationCenter.default.post(name: NSNotification.Name("RefreshUserPosts"), object: nil)
        } catch {
            errorMessage = error.localizedDescription
            print("Error deleting post: \(error)")
        }
        
        isLoading = false
        showDeleteAlert = false
        postIdToDelete = nil
    }
}

