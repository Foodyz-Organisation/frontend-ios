import SwiftUI
import Combine

// MARK: - Saved Posts Screen
struct SavedPostsScreen: View {
    @StateObject private var viewModel = SavedPostsViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                contentView
            }
            .navigationTitle("Saved Posts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    backButton
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchSavedPosts()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(error: error)
        } else if viewModel.posts.isEmpty {
            emptyStateView
        } else {
            postsListView
        }
    }
    
    private var loadingView: some View {
        ProgressView()
            .tint(hexColor("#F59E0B"))
            .scaleEffect(1.5)
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red.opacity(0.7))
            Text(error)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task {
                    await viewModel.fetchSavedPosts()
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(hexColor("#F59E0B"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("No saved posts")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(hexColor("#1F2937"))
            Text("Posts you save will appear here")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var postsListView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.posts) { post in
                    SavedPostItem(
                        post: post,
                        onUnsave: {
                            Task {
                                await viewModel.unsavePost(postId: post.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(hexColor("#F59E0B"))
        }
    }
    
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
}

// MARK: - Saved Post Item
struct SavedPostItem: View {
    let post: Post
    let onUnsave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            postImageView
            actionRowView
            captionView
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var postImageView: some View {
        if let imageUrl = post.fullDisplayImageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .clipped()
                case .failure(_):
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        )
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay(ProgressView())
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                }
            }
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
        }
    }
    
    private var actionRowView: some View {
        HStack {
            Spacer()
            Button(action: onUnsave) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 22))
                    .foregroundColor(hexColor("#F59E0B"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var captionView: some View {
        if !post.caption.isEmpty {
            Text(post.caption)
                .font(.system(size: 15))
                .foregroundColor(hexColor("#1F2937"))
                .lineLimit(3)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
    }
    
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
}

// MARK: - Saved Posts ViewModel
@MainActor
final class SavedPostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func fetchSavedPosts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            posts = try await PostsAPI.shared.getSavedPosts()
        } catch {
            errorMessage = "Failed to load saved posts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func unsavePost(postId: String) async {
        do {
            _ = try await PostsAPI.shared.unsavePost(postId: postId)
            // Remove from list
            posts.removeAll { $0.id == postId }
            SavesManager.shared.removeSave(postId: postId)
        } catch {
            errorMessage = "Failed to unsave post: \(error.localizedDescription)"
        }
    }
}


