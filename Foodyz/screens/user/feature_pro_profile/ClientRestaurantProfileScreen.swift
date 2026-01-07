import SwiftUI

// MARK: - Dynamic Client Restaurant Profile Screen
struct ClientRestaurantProfileScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ProfessionalProfileViewModel()
    @State private var selectedTab: RestaurantTab = .reels
    @State private var isFavorite: Bool = false
    
    let professionalId: String
    let onViewMenuClick: (String) -> Void
    
    enum RestaurantTab {
        case reels
        case photos
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color(hex: 0xFFFF6B00))
                    Text("Loading...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 16)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Retry") {
                        viewModel.loadProfessional(id: professionalId)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0xFFFF6B00))
                    .cornerRadius(8)
                }
            } else if let professional = viewModel.professional {
                RestaurantProfileView(
                    professional: professional,
                    professionalId: professionalId,
                    selectedTab: $selectedTab,
                    isFavorite: $isFavorite,
                    onViewMenuClick: onViewMenuClick,
                    onBackClick: { dismiss() }
                )
            }
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadProfessional(id: professionalId)
        }
    }
}

// MARK: - Restaurant Profile View
struct RestaurantProfileView: View {
    let professional: ProfessionalDto
    let professionalId: String
    @Binding var selectedTab: ClientRestaurantProfileScreen.RestaurantTab
    @Binding var isFavorite: Bool
    let onViewMenuClick: (String) -> Void
    let onBackClick: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Header Section
                    ZStack(alignment: .bottom) {
                        // Cover Image
                        ZStack(alignment: .top) {
                            if let coverUrl = professional.coverUrl, let url = URL(string: coverUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 220)
                                        .clipped()
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 220)
                                }
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3)) // Default cover
                                    .frame(height: 220)
                            }
                            
                            // Top Navigation Overlay
                            HStack {
                                Button(action: onBackClick) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    // Share action
                                }) {
                                    Image(systemName: "shareplay")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 50) // Adjust for safe area
                        }
                        
                        // Professional Name
                        HStack {
                            Text(professional.fullName ?? "Restaurant")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                            Spacer()
                        }
                        .padding(.leading, 20)
                        .padding(.bottom, 20) // Space for profile pic overlap
                        
                        // Profile Picture (Centered & Overlapping)
                        if let avatarUrl = professional.avatarUrl, let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color(hex: 0xFFFF6B00), lineWidth: 3)
                                    )
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                                    .frame(width: 100, height: 100)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color(hex: 0xFFFF6B00), lineWidth: 3)
                                    )
                            }
                            .offset(y: 50) // Overlap bottom
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                                .frame(width: 100, height: 100)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color(hex: 0xFFFF6B00), lineWidth: 3)
                                )
                                .offset(y: 50)
                        }
                    }
                    .padding(.bottom, 50) // Space for profile pic
                    
                    
                    // MARK: - Content Section
                    VStack(spacing: 24) {
                        
                        // Stats Row
                        HStack(spacing: 40) {
                            StatItem(count: professional.followerCount ?? 0, label: "Followers", icon: "person.2.fill")
                            StatItem(count: professional.followingCount ?? 0, label: "Following", icon: "person.fill.badge.plus")
                            StatItem(count: 2, label: "Posts", icon: "camera.fill") // Mock posts count for now
                        }
                        
                        Divider()
                        
                        // Description (Best Resto)
                        if let description = professional.description {
                            HStack {
                                Text(description)
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                        
                        Divider()
                        
                        // Contact Info
                        VStack(alignment: .leading, spacing: 16) {
                            if let phone = professional.phone {
                                ContactInfoRow(icon: "phone.fill", text: phone, iconColor: Color(hex: 0xFFFF6B00))
                            }
                            
                            // Locations
                            if let locations = professional.locations {
                                ForEach(locations, id: \.id) { location in
                                    ContactInfoRow(icon: "mappin.circle.fill", text: location.name ?? "Unknown Location", iconColor: Color(hex: 0xFFFF6B00))
                                }
                            } else {
                                // Fallback static address if no locations array yet (though DTO has it)
                                ContactInfoRow(icon: "mappin.circle.fill", text: "123 Avenue Habib Bourguiba, Tunis", iconColor: Color(hex: 0xFFFF6B00))
                            }
                            
                            if let hours = professional.hours {
                                ContactInfoRow(icon: "clock.fill", text: hours, iconColor: Color(hex: 0xFFFF6B00))
                            }
                        }
                        
                        // Service Options (Delivery, etc)
                        HStack(spacing: 12) {
                            RestaurantServicePill(icon: "moped.fill", text: "Delivery")
                            RestaurantServicePill(icon: "bag.fill", text: "Takeaway")
                            RestaurantServicePill(icon: "fork.knife", text: "Dine In")
                        }
                        
                        // Tabs
                        HStack(spacing: 0) {
                            RestaurantTabButton(
                                title: "Reels",
                                isSelected: selectedTab == .reels,
                                action: { selectedTab = .reels }
                            )
                            
                            RestaurantTabButton(
                                title: "Photos",
                                isSelected: selectedTab == .photos,
                                action: { selectedTab = .photos }
                            )
                        }
                        .padding(.vertical, 8)
                        
                        // Tab Content
                        Group {
                            switch selectedTab {
                            case .reels:
                                RestaurantReelsContent()
                            case .photos:
                                RestaurantPhotosContent()
                            }
                        }
                        .frame(minHeight: 200)
                        .frame(maxWidth: .infinity)
                        
                        Spacer(minLength: 100) // Space for bottom button
                    }
                    .padding(20)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // MARK: - View Menu Button
            VStack {
                Spacer()
                Button(action: {
                    onViewMenuClick(professionalId)
                }) {
                    Text("View Menu & Order")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: 0xFFFF6B00))
                        .cornerRadius(28)
                        .shadow(color: Color(hex: 0xFFFF6B00).opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Components

struct StatItem: View {
    let count: Int
    let label: String
    let icon: String // Added icon support
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20)) // Icon size
                .foregroundColor(Color(hex: 0xFFFF6B00)) // Orange color
            
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

struct ContactInfoRow: View {
    let icon: String
    let text: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15)) // Slightly larger
                .foregroundColor(Color(hex: 0xFF4B5563)) // Dark gray
            
            Spacer()
        }
    }
}

struct RestaurantServicePill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: 0xFFFF6B00))
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: 0xFFFF6B00))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: 0xFFFF6B00), lineWidth: 1)
        )
        .cornerRadius(20)
    }
}

struct RestaurantTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? Color(hex: 0xFFFF6B00) : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color(hex: 0xFFFF6B00) : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct RestaurantReelsContent: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.rectangle.fill") // Using a similar icon to the screenshot
                .font(.system(size: 64))
                .foregroundColor(Color(hex: 0xFF9CA3AF)) // Gray 400
            
            Text("No Reels available")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

struct RestaurantPhotosContent: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: 0xFF9CA3AF))
            
            Text("No Photos available")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
