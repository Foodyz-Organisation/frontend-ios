import SwiftUI
import Combine
import AVKit

struct PostDetailsScreen: View {
    let postId: String
    @StateObject private var viewModel = PostDetailsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showFullScreenImages = false
    @State private var selectedImageIndex = 0
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let post = viewModel.post {
                VStack(spacing: 0) {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 0) {
                            // User Header Section
                            HStack(spacing: 10) {
                                // Profile Picture
                                if let profileUrl = post.owner?.profilePictureUrl,
                                   let url = URL(string: profileUrl) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                }
                                
                                // Username
                                Text(post.owner?.displayName ?? "Unknown")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                // Rating Badge
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 10))
                                    Text("4.8")
                                        .foregroundColor(.white)
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.yellow)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            
                            // Post Image/Video
                            if post.isVideo {
                                // Video/Reel
                                VideoPostView(post: post, onTap: {
                                    viewModel.showFullScreenVideo = true
                                })
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                            } else {
                                // Image or Carousel
                                if post.mediaType == .carousel && post.mediaUrls.count > 1 {
                                    // Carousel - show first image with indicator
                                    CarouselImageView(
                                        post: post,
                                        onTap: {
                                            selectedImageIndex = 0
                                            showFullScreenImages = true
                                        }
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 250)
                                } else {
                                    // Single Image
                                    if let imageUrl = post.fullDisplayImageUrl, let url = URL(string: imageUrl) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(maxWidth: .infinity)
                                                    .frame(height: 250)
                                                    .clipped()
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        selectedImageIndex = 0
                                                        showFullScreenImages = true
                                                    }
                                            case .failure(_):
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(height: 250)
                                                    .overlay(
                                                        Image(systemName: "photo")
                                                            .font(.system(size: 40))
                                                            .foregroundColor(.gray)
                                                    )
                                            case .empty:
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(height: 250)
                                                    .overlay(ProgressView())
                                            @unknown default:
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(height: 250)
                                            }
                                        }
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 250)
                                    }
                                }
                            }
                            
                            // Post Details Section
                            VStack(alignment: .leading, spacing: 12) {
                                // Caption
                                Text(post.caption)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                
                                // Price (if available)
                                if let price = post.price {
                                    Text("\(price, specifier: "%.1f") TND")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                }
                                
                                // Preparation Time (if available)
                                if let prepTime = post.preparationTime {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .foregroundColor(.gray)
                                        Text("\(prepTime) minutes")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                // Rating and Reviews Row
                                HStack {
                                    Spacer()
                                    
                                    // Rating and Reviews
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 12))
                                        Text("4.9 • \(post.commentCount) reviews")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            
                            // Reviews Section
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Reviews")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                
                                if viewModel.comments.isEmpty {
                                    Text("No comments yet. Be the first to comment!")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 6)
                                        .padding(.bottom, 12)
                                } else {
                                    ForEach(viewModel.comments) { comment in
                                        CommentRow(
                                            comment: comment,
                                            currentUserId: UserSession.shared.userId,
                                            onDelete: {
                                                Task {
                                                    await viewModel.deleteComment(commentId: comment.id)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .background(Color.white)
                            .padding(.bottom, 70) // Extra padding for comment input
                        }
                    }
                    
                    // Comment Input at Bottom
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack(spacing: 10) {
                            TextField("Add a comment...", text: $viewModel.commentText)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(18)
                            
                            Button(action: {
                                Task {
                                    await viewModel.postComment()
                                }
                            }) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12))
                                    .padding(8)
                                    .background(viewModel.commentText.isEmpty ? Color.gray : Color.blue)
                                    .clipShape(Circle())
                            }
                            .disabled(viewModel.commentText.isEmpty || viewModel.isPostingComment)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.white.frame(height: 0)
                    }
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text(error)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Try Again") {
                        Task {
                            await viewModel.loadPost(id: postId)
                        }
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .navigationTitle("Post Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.primary)
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showFullScreenVideo) {
            if let post = viewModel.post,
               let videoUrlString = post.mediaUrls.first,
               let videoUrl = URL(string: videoUrlString.replacingOccurrences(of: "10.0.2.2", with: "192.168.100.28")) {
                FullScreenVideoPlayerView(videoUrl: videoUrl, isPresented: $viewModel.showFullScreenVideo)
            }
        }
        .fullScreenCover(isPresented: $showFullScreenImages) {
            if let post = viewModel.post {
                FullScreenImageViewer(
                    post: post,
                    initialIndex: selectedImageIndex,
                    isPresented: $showFullScreenImages
                )
            }
        }
        .onAppear {
            Task {
                await viewModel.loadPost(id: postId)
            }
        }
    }
}

// MARK: - Video Post View
struct VideoPostView: View {
    let post: Post
    let onTap: () -> Void
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            // Video thumbnail or player
            if let thumbnailUrl = post.thumbnailUrl,
               !thumbnailUrl.isEmpty,
               let url = URL(string: thumbnailUrl.replacingOccurrences(of: "10.0.2.2", with: "192.168.100.28")) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .clipped()
                    case .failure(_), .empty:
                        videoPlaceholder
                    @unknown default:
                        videoPlaceholder
                    }
                }
            } else if let videoUrlString = post.mediaUrls.first,
                      let videoUrl = URL(string: videoUrlString.replacingOccurrences(of: "10.0.2.2", with: "192.168.100.28")) {
                VideoThumbnailView(videoUrl: videoUrl)
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .clipped()
            } else {
                videoPlaceholder
            }
            
            // Play button overlay
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 250)
    }
    
    private var videoPlaceholder: some View {
        Rectangle()
            .fill(Color.black)
            .frame(height: 250)
            .overlay(
                Image(systemName: "video")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Carousel Image View
struct CarouselImageView: View {
    let post: Post
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            // Show first image with carousel indicator
            if let firstImageUrl = post.mediaUrls.first,
               let url = URL(string: firstImageUrl.replacingOccurrences(of: "10.0.2.2", with: "192.168.100.28")) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .clipped()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onTap()
                            }
                    case .failure(_), .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 250)
                    }
                }
            }
            
            // Carousel indicator overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.caption)
                        Text("\(post.mediaUrls.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

// MARK: - Full Screen Image Viewer
struct FullScreenImageViewer: View {
    let post: Post
    let initialIndex: Int
    @Binding var isPresented: Bool
    @State private var currentIndex: Int
    @State private var dragOffset: CGFloat = 0
    
    init(post: Post, initialIndex: Int, isPresented: Binding<Bool>) {
        self.post = post
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var isCarousel: Bool {
        post.mediaType == .carousel && post.mediaUrls.count > 1
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if isCarousel {
                // Carousel view with TabView
                TabView(selection: $currentIndex) {
                    ForEach(Array(post.mediaUrls.enumerated()), id: \.offset) { index, imageUrlString in
                        if let imageUrl = URL(string: imageUrlString.replacingOccurrences(of: "10.0.2.2", with: "192.168.100.28")) {
                            FullScreenImageView(imageUrl: imageUrl)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            } else {
                // Single image view
                if let imageUrlString = post.mediaUrls.first,
                   let imageUrl = URL(string: imageUrlString.replacingOccurrences(of: "10.0.2.2", with: "192.168.100.28")) {
                    FullScreenImageView(imageUrl: imageUrl)
                }
            }
            
            // Close button and page indicator
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Page indicator for carousel
                    if isCarousel {
                        HStack(spacing: 6) {
                            ForEach(0..<post.mediaUrls.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                        .padding(.trailing)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            currentIndex = initialIndex
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Dismiss on swipe down
                    if value.translation.height > 100 {
                        isPresented = false
                    }
                }
        )
    }
}

// MARK: - Full Screen Single Image View
struct FullScreenImageView: View {
    let imageUrl: URL
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: imageUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1.0), 5.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            // Double tap to reset zoom
                            withAnimation {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                case .failure(_):
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Failed to load image")
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                case .empty:
                    ProgressView()
                        .tint(.white)
                @unknown default:
                    ProgressView()
                        .tint(.white)
                }
            }
        }
    }
}

// MARK: - Full Screen Video Player
struct FullScreenVideoPlayerView: View {
    let videoUrl: URL
    @Binding var isPresented: Bool
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }
            
            // Close button
            VStack {
                HStack {
                    Button(action: {
                        player?.pause()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .onAppear {
            player = AVPlayer(url: videoUrl)
            player?.play()
            isPlaying = true
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: Comment
    let currentUserId: String?
    let onDelete: () -> Void
    
    var isOwnComment: Bool {
        guard let currentUserId = currentUserId,
              let commentUserId = comment.userId?.id else {
            return false
        }
        return currentUserId == commentUserId
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Profile picture
            if let profileUrl = comment.userId?.profilePictureUrl,
               let url = URL(string: profileUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(comment.userId?.displayName.prefix(1).uppercased() ?? "?")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(comment.userId?.displayName ?? "Unknown User")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Text(comment.text)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(formatDate(comment.createdAt))
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.7))
            }
            
            Spacer()
            
            // Delete button (only for comment owner)
            if isOwnComment {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - ViewModel
@MainActor
class PostDetailsViewModel: ObservableObject {
    @Published var post: Post?
    @Published var comments: [Comment] = []
    @Published var commentText = ""
    @Published var isLoading = false
    @Published var isPostingComment = false
    @Published var errorMessage: String?
    @Published var isLiked = false
    @Published var showComments = false
    @Published var showFullScreenVideo = false
    
    func loadPost(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            post = try await PostsAPI.shared.getPost(id: id)
            await loadComments(postId: id)
            // Check if user has liked this post
            isLiked = LikesManager.shared.isLiked(postId: id)
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading post: \(error)")
        }
        
        isLoading = false
    }
    
    func loadComments(postId: String) async {
        do {
            comments = try await PostsAPI.shared.getComments(postId: postId)
        } catch {
            print("Error loading comments: \(error)")
        }
    }
    
    func toggleLike() async {
        guard let post = post else { return }
        
        // Optimistically update UI
        let previousLikedState = isLiked
        isLiked.toggle()
        
        do {
            if previousLikedState {
                // Unlike
                let updatedPost = try await PostsAPI.shared.unlikePost(postId: post.id)
                self.post = updatedPost
                LikesManager.shared.removeLike(postId: post.id)
            } else {
                // Like
                let updatedPost = try await PostsAPI.shared.likePost(postId: post.id)
                self.post = updatedPost
                LikesManager.shared.addLike(postId: post.id)
            }
        } catch {
            // Revert optimistic update
            isLiked = previousLikedState
            
            // If error is conflict (already liked), it means user has already liked
            // So we should unlike it instead
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("already liked") || errorString.contains("conflict") {
                // User tried to like but already liked, so unlike it
                do {
                    let updatedPost = try await PostsAPI.shared.unlikePost(postId: post.id)
                    self.post = updatedPost
                    isLiked = false
                    LikesManager.shared.removeLike(postId: post.id)
                } catch {
                    print("Error unliking after conflict: \(error)")
                }
            } else {
                print("Error toggling like: \(error)")
            }
        }
    }
    
    func postComment() async {
        guard let postId = post?.id, !commentText.isEmpty else { return }
        
        isPostingComment = true
        
        do {
            let newComment = try await PostsAPI.shared.createComment(postId: postId, text: commentText)
            comments.append(newComment)
            commentText = ""
            
            // Update comment count
            if var currentPost = post {
                post = Post(
                    id: currentPost.id,
                    ownerId: currentPost.ownerId,
                    owner: currentPost.owner,
                    ownerModel: currentPost.ownerModel,
                    caption: currentPost.caption,
                    mediaUrls: currentPost.mediaUrls,
                    mediaType: currentPost.mediaType,
                    likeCount: currentPost.likeCount,
                    commentCount: currentPost.commentCount + 1,
                    saveCount: currentPost.saveCount,
                    thumbnailUrl: currentPost.thumbnailUrl,
                    viewsCount: currentPost.viewsCount,
                    duration: currentPost.duration,
                    aspectRatio: currentPost.aspectRatio,
                    createdAt: currentPost.createdAt,
                    updatedAt: currentPost.updatedAt,
                    foodType: currentPost.foodType,
                    price: currentPost.price,
                    preparationTime: currentPost.preparationTime
                )
            }
        } catch {
            print("Error posting comment: \(error)")
        }
        
        isPostingComment = false
    }
    
    func deleteComment(commentId: String) async {
        do {
            try await PostsAPI.shared.deleteComment(commentId: commentId)
            
            // Remove from local array
            comments.removeAll { $0.id == commentId }
            
            // Update comment count
            if var currentPost = post {
                post = Post(
                    id: currentPost.id,
                    ownerId: currentPost.ownerId,
                    owner: currentPost.owner,
                    ownerModel: currentPost.ownerModel,
                    caption: currentPost.caption,
                    mediaUrls: currentPost.mediaUrls,
                    mediaType: currentPost.mediaType,
                    likeCount: currentPost.likeCount,
                    commentCount: max(0, currentPost.commentCount - 1),
                    saveCount: currentPost.saveCount,
                    thumbnailUrl: currentPost.thumbnailUrl,
                    viewsCount: currentPost.viewsCount,
                    duration: currentPost.duration,
                    aspectRatio: currentPost.aspectRatio,
                    createdAt: currentPost.createdAt,
                    updatedAt: currentPost.updatedAt,
                    foodType: currentPost.foodType,
                    price: currentPost.price,
                    preparationTime: currentPost.preparationTime
                )
            }
        } catch {
            print("Error deleting comment: \(error)")
        }
    }
}
