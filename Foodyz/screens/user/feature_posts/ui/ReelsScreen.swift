import SwiftUI
import AVKit
import Combine

struct ReelsScreen: View {
    @StateObject private var viewModel = ReelsViewModel()
    var onBack: () -> Void
    
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
                TabView {
                    ForEach(viewModel.videoPosts) { post in
                        ReelPlayerView(post: post)
                            .frame(width: size.width, height: size.height)
                            .rotationEffect(.init(degrees: -90)) // Rotate content back
                            .ignoresSafeArea()
                    }
                }
                .rotationEffect(.init(degrees: 90)) // Rotate TabView to scroll vertically
                .frame(width: size.height) // Swap width/height for rotation
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(width: size.width)
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
    @State private var player: AVPlayer?
    @State private var isMuted = false
    
    var body: some View {
        ZStack {
            if let videoUrl = post.fullDisplayImageUrl, let url = URL(string: videoUrl) {
                CustomVideoPlayer(player: player)
                    .onAppear {
                        if player == nil {
                            player = AVPlayer(url: url)
                        }
                        player?.play()
                        
                        // Loop video
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { _ in
                            player?.seek(to: .zero)
                            player?.play()
                        }
                    }
                    .onDisappear {
                        player?.pause()
                    }
            } else {
                Color.black
            }
            
            // Overlay Controls
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        // User Info
                        HStack {
                            if let profileUrl = post.userId?.profilePictureUrl, let url = URL(string: profileUrl) {
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
                                    .overlay(Text(post.userId?.username.prefix(1).uppercased() ?? "U").foregroundColor(.white))
                            }
                            
                            Text(post.userId?.username ?? "Unknown")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Button("Follow") {
                                // Follow action
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .foregroundColor(.white)
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
                        ActionButtons(icon: "heart", text: "\(post.likeCount)")
                        ActionButtons(icon: "bubble.right", text: "\(post.commentCount)")
                        ActionButtons(icon: "paperplane", text: nil)
                        
                        Button(action: {
                            // More options
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        // Music Album Art (Rotating)
                        if let profileUrl = post.userId?.profilePictureUrl, let url = URL(string: profileUrl) {
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
            isMuted.toggle()
            player?.isMuted = isMuted
        }
    }
}

struct ActionButtons: View {
    var icon: String
    var text: String?
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
            
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
    
    func fetchReels() async {
        isLoading = true
        do {
            let allPosts = try await PostsAPI.shared.getAllPosts()
            // Filter for videos only
            videoPosts = allPosts.filter { $0.isVideo }
        } catch {
            print("Error fetching reels: \(error)")
        }
        isLoading = false
    }
}
