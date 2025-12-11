import SwiftUI
import AVKit
import Combine

struct TrendingScreen: View {
    @StateObject private var viewModel = TrendingViewModel()
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
            } else if viewModel.posts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No trending posts")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            } else {
                TabView {
                    ForEach(viewModel.posts) { post in
                        TrendingPostView(post: post, viewModel: viewModel)
                            .frame(width: size.width, height: size.height)
                            .rotationEffect(.init(degrees: -90))
                            .ignoresSafeArea()
                    }
                }
                .rotationEffect(.init(degrees: 90))
                .frame(width: size.height)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(width: size.width)
            }
            
            // Back Button Overlay
            VStack {
                HStack(spacing: 16) {
                    Button(action: onBack) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text("Trending")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 48) // Adjust for status bar
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            Task {
                await viewModel.fetchTrending()
            }
        }
    }
}

struct TrendingPostView: View {
    let post: Post
    @ObservedObject var viewModel: TrendingViewModel
    @State private var player: AVPlayer?
    @State private var isMuted = false
    
    var body: some View {
        ZStack {
            // Media Content
            if post.isVideo {
                if let videoUrl = post.fullDisplayImageUrl, let url = URL(string: videoUrl) {
                    CustomVideoPlayer(player: player)
                        .onAppear {
                            if player == nil {
                                player = AVPlayer(url: url)
                            }
                            player?.play()
                            
                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { _ in
                                player?.seek(to: .zero)
                                player?.play()
                            }
                        }
                        .onDisappear {
                            player?.pause()
                        }
                }
            } else {
                if let imageUrl = post.fullDisplayImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        case .failure(_):
                            Color.gray
                        case .empty:
                            ProgressView()
                        @unknown default:
                            Color.gray
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            // Overlay Controls
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        // User Info
                        HStack {
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
                    }
                    
                    Spacer()
                    
                    // Side Actions removed as requested
                }
                .padding(.bottom, 20)
                .padding(.horizontal)
            }
            .padding(.bottom, 50)
        }
        .background(Color.black)
        .onTapGesture {
            if post.isVideo {
                isMuted.toggle()
                player?.isMuted = isMuted
            }
        }
    }
}

// MARK: - ViewModel
@MainActor
class TrendingViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    
    func fetchTrending() async {
        isLoading = true
        do {
            posts = try await PostsAPI.shared.getTrendingPosts()
        } catch {
            print("Error fetching trending: \(error)")
        }
        isLoading = false
    }
    
    func likePost(_ postId: String) async {
        do {
            try await PostsAPI.shared.likePost(postId: postId)
            // Optimistically update UI or re-fetch
        } catch {
            print("Error liking post: \(error)")
        }
    }
    
    func savePost(_ postId: String) async {
        do {
            try await PostsAPI.shared.savePost(postId: postId)
        } catch {
            print("Error saving post: \(error)")
        }
    }
}
