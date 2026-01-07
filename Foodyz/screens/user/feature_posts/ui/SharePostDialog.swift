import SwiftUI
import Combine

// MARK: - Share Post Dialog
struct SharePostDialog: View {
    let postId: String
    let onDismiss: () -> Void
    let onShareSuccess: () -> Void
    
    @StateObject private var viewModel: SharePostDialogViewModel
    @State private var searchQuery: String = ""
    
    init(
        postId: String,
        onDismiss: @escaping () -> Void,
        onShareSuccess: @escaping () -> Void
    ) {
        self.postId = postId
        self.onDismiss = onDismiss
        self.onShareSuccess = onShareSuccess
        _viewModel = StateObject(wrappedValue: SharePostDialogViewModel(postId: postId))
    }
    
    var body: some View {
        ZStack {
            backgroundOverlay
            dialogContent
        }
        .onAppear {
            viewModel.loadPostData()
        }
        .onChange(of: viewModel.shareSuccess) { success in
            if success {
                onShareSuccess()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onDismiss()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture {
                onDismiss()
            }
    }
    
    private var dialogContent: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            postPreviewSection
            Divider()
            searchBarSection
            messageSection
            searchResultsSection
        }
        .frame(width: UIScreen.main.bounds.width * 0.95, height: UIScreen.main.bounds.height * 0.7)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(radius: 10)
    }
    
    private var headerSection: some View {
        HStack {
            Text("Share Post")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(hexColor("#1F2937"))
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
    }
    
    @ViewBuilder
    private var postPreviewSection: some View {
        if let postData = viewModel.postData {
            postPreviewContent(post: postData)
        } else if viewModel.isLoadingPost {
            ProgressView()
                .tint(hexColor("#F59E0B"))
                .frame(height: 80)
        }
    }
    
    private func postPreviewContent(post: Post) -> some View {
        HStack(spacing: 12) {
            postThumbnailView(post: post)
            Text(post.caption.isEmpty ? "Post" : post.caption)
                .font(.system(size: 14))
                .lineLimit(2)
                .foregroundColor(hexColor("#1F2937"))
            Spacer()
        }
        .padding(16)
        .background(hexColor("#FFFBEA"))
    }
    
    @ViewBuilder
    private func postThumbnailView(post: Post) -> some View {
        if let imageUrl = post.displayImageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            .clipped()
        } else {
            Color.gray.opacity(0.2)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
        }
    }
    
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search users or kitchens...", text: $searchQuery)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: searchQuery) { newValue in
                    viewModel.search(query: newValue)
                }
            
            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(hexColor("#F3F4F6"))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    @ViewBuilder
    private var messageSection: some View {
        if let successMessage = viewModel.shareSuccessMessage {
            messageBanner(text: successMessage, color: .green)
        }
        if let error = viewModel.shareError {
            messageBanner(text: error, color: .red)
        }
    }
    
    private func messageBanner(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(color)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.top, 8)
    }
    
    @ViewBuilder
    private var searchResultsSection: some View {
        if viewModel.isSearching {
            Spacer()
            ProgressView()
                .tint(hexColor("#F59E0B"))
            Spacer()
        } else if searchQuery.isEmpty {
            emptySearchState
        } else if viewModel.searchResults.isEmpty {
            noResultsState
        } else {
            searchResultsList
        }
    }
    
    private var emptySearchState: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.5))
                Text("Search for users or kitchens to share with")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    private var noResultsState: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "person.slash")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.5))
                Text("No users found")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.searchResults) { user in
                    UserResultItem(
                        user: user,
                        isSharing: viewModel.isSharing,
                        onShare: {
                            viewModel.sharePost(to: user.id)
                        }
                    )
                }
            }
            .padding(16)
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

// MARK: - User Result Item
struct UserResultItem: View {
    let user: SearchableUser
    let isSharing: Bool
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            if let avatarUrl = user.profilePictureUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Text(user.name.first?.uppercased() ?? "?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                ZStack {
                    Color.gray.opacity(0.2)
                    Text(user.name.first?.uppercased() ?? "?")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray)
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(hexColor("#1F2937"))
                
                // Badge
                Text(user.kind == "professional" ? "Kitchen" : "User")
                    .font(.system(size: 11))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        user.kind == "professional"
                            ? hexColor("#F59E0B").opacity(0.2)
                            : Color.blue.opacity(0.2)
                    )
                    .foregroundColor(
                        user.kind == "professional"
                            ? hexColor("#F59E0B")
                            : .blue
                    )
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Share Button
            Button(action: onShare) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(hexColor("#F59E0B"))
            }
            .disabled(isSharing)
        }
        .padding(12)
        .background(hexColor("#F3F4F6"))
        .cornerRadius(12)
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

// MARK: - Searchable User
struct SearchableUser: Identifiable {
    let id: String
    let name: String
    let profilePictureUrl: String?
    let email: String?
    let kind: String
}

// MARK: - Share Post Dialog ViewModel
@MainActor
final class SharePostDialogViewModel: ObservableObject {
    let postId: String
    
    @Published var postData: Post? = nil
    @Published var isLoadingPost: Bool = false
    @Published var searchResults: [SearchableUser] = []
    @Published var isSearching: Bool = false
    @Published var isSharing: Bool = false
    @Published var shareError: String? = nil
    @Published var shareSuccessMessage: String? = nil
    @Published var shareSuccess: Bool = false
    
    private var searchTask: Task<Void, Never>?
    
    init(postId: String) {
        self.postId = postId
    }
    
    func loadPostData() {
        Task {
            isLoadingPost = true
            do {
                postData = try await PostsAPI.shared.getPost(id: postId)
            } catch {
                shareError = "Failed to load post details"
            }
            isLoadingPost = false
        }
    }
    
    func search(query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            // Debounce: wait 500ms
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            guard !Task.isCancelled else { return }
            
            isSearching = true
            shareError = nil
            
            do {
                let peers = try await ChatAPI.shared.fetchPeers()
                
                // Filter peers by search query
                let filtered = peers.filter { peer in
                    peer.name.localizedCaseInsensitiveContains(query) ||
                    peer.email.localizedCaseInsensitiveContains(query)
                }
                
                // Map to SearchableUser
                searchResults = filtered.map { peer in
                    // Clean name (remove email in parentheses if present)
                    let cleanName = peer.name.split(separator: " (").first.map(String.init) ?? peer.name
                    
                    return SearchableUser(
                        id: peer.id,
                        name: cleanName,
                        profilePictureUrl: peer.avatarUrl,
                        email: peer.email,
                        kind: peer.kind
                    )
                }
            } catch {
                shareError = "Search failed: \(error.localizedDescription)"
                searchResults = []
            }
            
            isSearching = false
        }
    }
    
    func sharePost(to recipientId: String) {
        Task {
            isSharing = true
            shareError = nil
            shareSuccessMessage = nil
            
            do {
                let response = try await PostsAPI.shared.sharePost(
                    postId: postId,
                    recipientId: recipientId,
                    message: "Shared a post with you"
                )
                
                if response.success {
                    // Find recipient name
                    if let recipient = searchResults.first(where: { $0.id == recipientId }) {
                        shareSuccessMessage = "Post shared with \(recipient.name)!"
                    } else {
                        // Use the message from response if available, otherwise default
                        shareSuccessMessage = response.message.isEmpty ? "Post shared successfully!" : response.message
                    }
                    shareSuccess = true
                } else {
                    shareError = "Failed to share post"
                }
            } catch {
                shareError = "Failed to share post: \(error.localizedDescription)"
            }
            
            isSharing = false
        }
    }
}


