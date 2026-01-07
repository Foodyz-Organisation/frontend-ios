import SwiftUI
import Combine

// MARK: - Professional Profile Screen

struct ProfessionalProfileScreen: View {
    let professionalId: String
    var onPostTap: ((String) -> Void)? = nil
    var onSettingsTap: (() -> Void)? = nil
    
    @StateObject private var viewModel = ProfessionalProfileViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: ProfileTab = .reels
    
    // Hardcoded stats for now as requested
    private let followersCount = 0
    private let followingCount = 0
    private let postsCount = 2
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Top Bar with Back and Settings
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.gray.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        onSettingsTap?()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white) // Visible on gradient
                            .padding(8)
                            .background(Color.gray.opacity(0.5)) // Background for visibility
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 60) // Adjust for status bar
                .zIndex(10)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header Section with Gradient and Profile Pic
                            ZStack(alignment: .bottomLeading) {
                                // Background Image or Gradient
                                if let coverUrlStr = viewModel.professional?.coverUrl,
                                   let url = URL(string: coverUrlStr.replacingOccurrences(of: "10.0.2.2", with: "127.0.0.1")) {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image.resizable().scaledToFill()
                                        } else {
                                            LinearGradient(
                                                colors: [Color.gray.opacity(0.3), Color.black.opacity(0.8)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        }
                                    }
                                    .frame(height: 200)
                                    .clipped()
                                } else {
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.3), Color.black.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: 200)
                                }
                                
                                // Gradient Overlay for text readability
                                LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                                    .frame(height: 80)
                                
                                // Name
                                Text(viewModel.professional?.fullName ?? "Professional Name")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.leading, 20)
                                    .padding(.bottom, 20)
                            }
                            .frame(height: 200)
                            .overlay(
                                // Profile Picture Circle - Centered perfectly overlapping the edge
                                VStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .stroke(Color.orange, lineWidth: 3)
                                            .background(Circle().fill(Color.white))
                                            .frame(width: 100, height: 100)
                                        
                                        if let avatarUrlStr = viewModel.professional?.avatarUrl,
                                           let url = URL(string: avatarUrlStr.replacingOccurrences(of: "10.0.2.2", with: "127.0.0.1")) {
                                            AsyncImage(url: url) { phase in
                                                if let image = phase.image {
                                                    image.resizable().scaledToFill()
                                                } else {
                                                     Image(systemName: "person.fill").foregroundColor(.gray)
                                                }
                                            }
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 40))
                                        }
                                    }
                                    .offset(y: 50) // Move down to overlap
                                }
                            )
                            .zIndex(1) // Ensure it's above content below
                            
                            // Spacer for the half-profile pic that hangs down
                            Spacer().frame(height: 60)
                            
                            // Stats Row
                            HStack(spacing: 40) {
                                StatsItem(count: viewModel.professional?.followerCount ?? 0, label: "Followers", icon: "person.2.fill")
                                StatsItem(count: viewModel.professional?.followingCount ?? 0, label: "Following", icon: "person.fill.badge.plus")
                                StatsItem(count: viewModel.imagePosts.count + viewModel.videoPosts.count, label: "Posts", icon: "camera.fill")
                            }
                            .padding(.vertical, 10)
                            
                            Divider().padding(.horizontal, 20)
                            
                            // Bio / Info Section
                            VStack(alignment: .leading, spacing: 16) {
                                if let desc = viewModel.professional?.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 10)
                                }
                                
                                Divider().padding(.horizontal, 20)
                                
                                // Contact Details
                                VStack(alignment: .leading, spacing: 16) {
                                    if let phone = viewModel.professional?.phone, !phone.isEmpty {
                                        ContactRow(icon: "phone.fill", text: phone)
                                    }
                                    
                                    // Locations
                                    if let locations = viewModel.professional?.locations, !locations.isEmpty {
                                        ForEach(locations, id: \.id) { loc in
                                            ContactRow(icon: "mappin.circle.fill", text: loc.name ?? "Unknown Location")
                                        }
                                    }
                                    
                                    if let hours = viewModel.professional?.hours, !hours.isEmpty {
                                        ContactRow(icon: "clock.fill", text: hours)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Service Options Pills
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ServicePill(icon: "box.truck.fill", text: "Delivery")
                                    ServicePill(icon: "fork.knife", text: "Takeaway")
                                    ServicePill(icon: "cup.and.saucer.fill", text: "Dine In")
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                            }
                            
                            Divider()
                            
                            // Tabs (Reels / Photos)
                            HStack(spacing: 0) {
                                TabButtonUpdated(title: "Reels", isSelected: selectedTab == .reels) {
                                    selectedTab = .reels
                                }
                                TabButtonUpdated(title: "Photos", isSelected: selectedTab == .photos) {
                                    selectedTab = .photos
                                }
                            }
                            .padding(.top, 10)
                            
                            // Tab Content Grid
                            Group {
                                if selectedTab == .reels {
                                    ReelsTabContent(posts: viewModel.videoPosts, onPostTap: onPostTap)
                                } else {
                                    PhotosTabContent(posts: viewModel.imagePosts, onPostTap: onPostTap)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadData(professionalId: professionalId)
            }
        }
    }
}

// MARK: - Components

struct StatsItem: View {
    let count: Int
    let label: String
    let icon: String // Added icon support matching design
    
    var body: some View {
        VStack(spacing: 4) {
             Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.orange)
            
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

struct ContactRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .font(.system(size: 16))
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#4A5568")) // Dark gray
        }
    }
}

struct ServicePill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .font(.system(size: 14))
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange, lineWidth: 1)
        )
        .background(Color.white)
        .cornerRadius(20)
    }
}

struct TabButtonUpdated: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .orange : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.orange : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// Reuse existing content views
// START REUSED CONTENT
// Note: We need to include the reused components from the previous file to ensure compilation.
// To keep the file clean, I will re-include them but slightly optimized.

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
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                ForEach(posts) { post in
                    MediaGridItem(post: post, showVideoIndicator: true)
                        .onTapGesture { onPostTap?(post.id) }
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
                    .foregroundColor(.gray)
            }
             .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                ForEach(posts) { post in
                    MediaGridItem(post: post, showVideoIndicator: false)
                        .onTapGesture { onPostTap?(post.id) }
                }
            }
        }
    }
}

struct MediaGridItem: View {
    let post: Post
    let showVideoIndicator: Bool
    private let itemSize: CGFloat = (UIScreen.main.bounds.width - 4) / 3 // 3 columns
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let urlStr = post.thumbnailUrl ?? post.fullDisplayImageUrl,
               let url = URL(string: urlStr.replacingOccurrences(of: "10.0.2.2", with: "127.0.0.1")) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
            } else {
                Color.gray.opacity(0.3)
            }
            
            if showVideoIndicator {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.white)
                    .font(.title3)
                    .padding(4)
            }
        }
        .frame(width: itemSize, height: itemSize)
        .clipped()
    }
}

enum ProfileTab {
    case reels, photos
}


