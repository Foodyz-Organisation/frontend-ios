import SwiftUI
import AVKit
import Combine

struct ReelsScreen: View {
    @StateObject private var viewModel = ReelsViewModel()
    var onBack: () -> Void
    var onNavigateToProfessional: ((String) -> Void)? = nil
    var onFollowProfessional: ((String) -> Void)? = nil
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                        .tint(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            } else if viewModel.videoPosts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No reels available")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            } else {
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.videoPosts.enumerated()), id: \.element.id) { index, post in
                        ReelPlayerView(
                            post: post,
                            isActive: viewModel.currentIndex == index,
                            onNavigateToProfessional: onNavigateToProfessional,
                            onFollowProfessional: onFollowProfessional
                        )
                        .frame(width: size.width, height: size.height)
                        .rotationEffect(.init(degrees: -90)) // Rotate content back
                        .ignoresSafeArea()
                        .tag(index)
                    }
                }
                .rotationEffect(.init(degrees: 90)) // Rotate TabView to scroll vertically
                .frame(width: size.height) // Swap width/height for rotation
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(width: size.width)
                .onAppear {
                    // Start playing the first video
                    if viewModel.currentIndex == 0 {
                        viewModel.currentIndex = 0
                    }
                }
            }
            
            // Back Button Overlay
            VStack {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 48) // Adjust for status bar
                    Spacer()
                }
                Spacer()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            Task {
                await viewModel.fetchReels()
            }
        }
    }
}

struct ReelPlayerView: View {
    let post: Post
    let isActive: Bool
    var onNavigateToProfessional: ((String) -> Void)? = nil
    var onFollowProfessional: ((String) -> Void)? = nil
    
    @State private var player: AVPlayer?
    @State private var playerItem: AVPlayerItem?
    @State private var isMuted = false
    @State private var isPlaying = false
    @State private var isLiked: Bool
    @State private var currentLikeCount: Int
    @State private var showComments = false
    @State private var isFollowing = false
    @State private var playbackObserver: NSObjectProtocol?
    @State private var readinessTimer: Timer?
    
    init(post: Post, isActive: Bool = true, onNavigateToProfessional: ((String) -> Void)? = nil, onFollowProfessional: ((String) -> Void)? = nil) {
        self.post = post
        self.isActive = isActive
        self.onNavigateToProfessional = onNavigateToProfessional
        self.onFollowProfessional = onFollowProfessional
        // Initialize isLiked from LikesManager
        _isLiked = State(initialValue: LikesManager.shared.isLiked(postId: post.id))
        _currentLikeCount = State(initialValue: post.likeCount)
    }
    
    // Check if owner is a professional
    private var isProfessionalPost: Bool {
        return post.ownerModel == .professional
    }
    
    var body: some View {
        ZStack {
            // Use mediaUrls.first for video URL (not fullDisplayImageUrl which might be thumbnail)
            if let videoUrlString = post.mediaUrls.first,
               let videoUrl = URL(string: videoUrlString.replacingOccurrences(of: "10.0.2.2", with: "127.0.0.1")) {
                CustomVideoPlayer(player: player)
                    .onAppear {
                        setupPlayer(url: videoUrl)
                    }
                    .onChange(of: isActive) { newValue in
                        if newValue {
                            // Video became active - start playing
                            startPlaying()
                        } else {
                            // Video became inactive - pause
                            pausePlaying()
                        }
                    }
                    .onDisappear {
                        cleanupPlayer()
                    }
            } else {
                Color.black
                    .overlay(
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundColor(.white)
                            Text("Video URL not available")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    )
            }
            
            // Overlay Controls
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        // User Info
                        HStack(spacing: 8) {
                            if let profileUrl = post.owner?.profilePictureUrl, let url = URL(string: profileUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color.gray)
                                }
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 32, height: 32)
                                    .overlay(Text(post.owner?.displayName.prefix(1).uppercased() ?? "U").foregroundColor(.white))
                            }
                            
                            Text(post.owner?.displayName ?? "Unknown")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Follow Button
                            Button(action: {
                                if let ownerId = post.owner?.id {
                                    isFollowing.toggle()
                                    onFollowProfessional?(ownerId)
                                }
                            }) {
                                Text(isFollowing ? "Following" : "Follow")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(isFollowing ? Color.white.opacity(0.3) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                                    .foregroundColor(.white)
                            }
                            
                            // Order Button (only for professional posts)
                            if isProfessionalPost, let ownerId = post.owner?.id {
                                Button(action: {
                                    onNavigateToProfessional?(ownerId)
                                }) {
                                    Text("Order")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "#F59E0B"))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        
                        // Caption
                        if !post.caption.isEmpty {
                            Text(post.caption)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                        
                        // Music/Audio indicator
                        HStack {
                            Image(systemName: "music.note")
                            Text("Original Audio")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Side Actions
                    VStack(spacing: 20) {
                        Button(action: {
                            Task {
                                await toggleLike()
                            }
                        }) {
                            ActionButtons(
                                icon: isLiked ? "heart.fill" : "heart",
                                text: "\(currentLikeCount)",
                                isLiked: isLiked
                            )
                        }
                        
                        Button(action: {
                            showComments = true
                        }) {
                            ActionButtons(icon: "bubble.right", text: "\(post.commentCount)")
                        }
                        
                        ActionButtons(icon: "paperplane", text: nil)
                        
                        Button(action: {
                            // More options
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        // Music Album Art (Rotating)
                        if let profileUrl = post.owner?.profilePictureUrl, let url = URL(string: profileUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray)
                            }
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .padding(4)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                        }
                    }
                }
                .padding(.bottom, 20) // Adjust for bottom nav bar
                .padding(.horizontal)
            }
            .padding(.bottom, 50) // Extra padding for tab bar
        }
        .background(Color.black)
        .onTapGesture {
            // Toggle play/pause on tap
            if isPlaying {
                player?.pause()
                isPlaying = false
            } else {
                player?.play()
                isPlaying = true
            }
        }
        .overlay {
            if showComments {
                // Background overlay to dim the video
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showComments = false
                        }
                    }
                
                // Comments Drawer
                VStack {
                    Spacer()
                    CommentsDrawer(
                        postId: post.id,
                        postCaption: post.caption,
                        likeCount: currentLikeCount,
                        commentCount: post.commentCount,
                        isPresented: $showComments
                    )
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
                }
                .transition(.move(edge: .bottom))
                .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showComments)
    }
    
    // MARK: - Player Management
    
    private func setupPlayer(url: URL) {
        // Clean up existing player if any
        cleanupPlayer()
        
        print("🎬 Setting up player for video: \(post.id)")
        print("📹 Video URL: \(url.absoluteString)")
        
        // Create new player item
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Configure player for automatic playback
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.allowsExternalPlayback = false
        
        // Set up audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 Audio session configured")
        } catch {
            print("❌ Failed to set up audio session: \(error)")
        }
        
        // Set up loop notification
        let postId = post.id
        playbackObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { notification in
            if let item = notification.object as? AVPlayerItem,
               let player = player {
                player.seek(to: .zero)
                player.play()
                print("🔄 Video looped: \(postId)")
            }
        }
        
        // Start playing if this view is active
        if isActive {
            startPlaying()
        }
    }
    
    private func startPlaying() {
        guard let currentPlayer = player, let currentPlayerItem = playerItem else {
            print("⚠️ Cannot start playing: player is nil")
            return
        }
        
        print("▶️ Attempting to start playback for: \(post.id)")
        
        // Check if player item is ready
        if currentPlayerItem.status == .readyToPlay {
            currentPlayer.play()
            DispatchQueue.main.async {
                isPlaying = true
            }
            print("✅ Started playing immediately: \(post.id)")
        } else {
            // Poll for readiness (simpler than KVO for SwiftUI)
            let postId = post.id
            let maxAttempts = 20 // 2 seconds max wait
            var attempts = 0
            
            // Capture player and playerItem references (they're already unwrapped from guard above)
            let capturedPlayer = currentPlayer
            let capturedPlayerItem = currentPlayerItem
            
            readinessTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                attempts += 1
                
                if capturedPlayerItem.status == AVPlayerItem.Status.readyToPlay {
                    capturedPlayer.play()
                    print("✅ Started playing after \(attempts * 100)ms: \(postId)")
                    timer.invalidate()
                    
                    // Update isPlaying state on main thread
                    DispatchQueue.main.async {
                        isPlaying = true
                    }
                } else if attempts >= maxAttempts || capturedPlayerItem.status == AVPlayerItem.Status.failed {
                    print("❌ Player failed to become ready after \(attempts * 100)ms")
                    timer.invalidate()
                }
            }
        }
    }
    
    private func pausePlaying() {
        player?.pause()
        isPlaying = false
        print("⏸️ Paused video: \(post.id)")
    }
    
    private func cleanupPlayer() {
        print("🧹 Cleaning up player for: \(post.id)")
        
        // Invalidate timer
        readinessTimer?.invalidate()
        readinessTimer = nil
        
        // Remove observers
        if let playerItem = playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
        
        if let observer = playbackObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackObserver = nil
        }
        
        player?.pause()
        player = nil
        playerItem = nil
        isPlaying = false
    }
    
    // MARK: - Actions
    
    private func toggleLike() async {
        // Optimistically update UI
        let previousLikedState = isLiked
        let previousLikeCount = currentLikeCount
        isLiked.toggle()
        currentLikeCount += previousLikedState ? -1 : 1
        
        do {
            if previousLikedState {
                // Unlike
                let updatedPost = try await PostsAPI.shared.unlikePost(postId: post.id)
                currentLikeCount = updatedPost.likeCount
                LikesManager.shared.removeLike(postId: post.id)
            } else {
                // Like
                let updatedPost = try await PostsAPI.shared.likePost(postId: post.id)
                currentLikeCount = updatedPost.likeCount
                LikesManager.shared.addLike(postId: post.id)
            }
            // Notify parent to refresh
            NotificationCenter.default.post(name: NSNotification.Name("RefreshPostsFeed"), object: nil)
        } catch {
            // Revert optimistic update
            isLiked = previousLikedState
            currentLikeCount = previousLikeCount
            
            // If error is conflict (already liked), it means user has already liked
            // So we should unlike it instead
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("already liked") || errorString.contains("conflict") {
                // User tried to like but already liked, so unlike it
                do {
                    let updatedPost = try await PostsAPI.shared.unlikePost(postId: post.id)
                    currentLikeCount = updatedPost.likeCount
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
}

struct ActionButtons: View {
    var icon: String
    var text: String?
    var isLiked: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(isLiked ? .red : .white)
            
            if let text = text {
                Text(text)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}

// Custom Video Player using AVPlayerLayer for better control
struct CustomVideoPlayer: UIViewControllerRepresentable {
    var player: AVPlayer?
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

// MARK: - ViewModel
@MainActor
class ReelsViewModel: ObservableObject {
    @Published var videoPosts: [Post] = []
    @Published var isLoading = false
    @Published var currentIndex: Int = 0 {
        didSet {
            print("📹 Current reel index changed to: \(currentIndex)")
        }
    }
    
    func fetchReels() async {
        isLoading = true
        do {
            let allPosts = try await PostsAPI.shared.getAllPosts()
            // Filter for videos only
            videoPosts = allPosts.filter { $0.isVideo }
            print("✅ Loaded \(videoPosts.count) video reels")
        } catch {
            print("❌ Error fetching reels: \(error)")
        }
        isLoading = false
    }
}
