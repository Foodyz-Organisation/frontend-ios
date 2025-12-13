import SwiftUI

/// Screen for professionals to choose content type to create
struct ProfessionalAddContentScreen: View {
    @Binding var path: NavigationPath
    @State private var showCreatePost = false
    @State private var showComingSoonAlert = false
    @State private var comingSoonType = ""
    
    init(path: Binding<NavigationPath>) {
        self._path = path
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.foodyzBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Button(action: {
                        path.removeLast()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.foodyzOrange)
                        .font(.body)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 5)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header section
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.foodyzOrange)
                            
                            Text("Create Content")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text("Choose what you'd like to create")
                                .font(.subheadline)
                                .foregroundColor(.mediumGray)
                        }
                        .padding(.top, 40)
                        
                        // Content type options
                        VStack(spacing: 16) {
                            // Add Post
                            ContentTypeCard(
                                icon: "photo.fill.on.rectangle.fill",
                                title: "Add Post",
                                subtitle: "Share a photo or video",
                                color: .foodyzOrange
                            ) {
                                showCreatePost = true
                            }
                            
                            // Add Event
                            ContentTypeCard(
                                icon: "calendar.badge.plus",
                                title: "Add Event",
                                subtitle: "Create a special event",
                                color: Color(red: 0.2, green: 0.6, blue: 0.86)
                            ) {
                                comingSoonType = "Event"
                                showComingSoonAlert = true
                            }
                            
                            // Add Box Deal
                            ContentTypeCard(
                                icon: "gift.fill",
                                title: "Add Box-Deal",
                                subtitle: "Offer a special deal",
                                color: Color(red: 0.58, green: 0.4, blue: 0.93)
                            ) {
                                comingSoonType = "Box-Deal"
                                showComingSoonAlert = true
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showCreatePost) {
            MediaSelectionView(
                isPresented: $showCreatePost,
                onPostCreated: {
                    // When post is created, dismiss sheet and navigate back to HomeProfessionalScreen
                    showCreatePost = false
                    // Navigate back to home screen after a short delay to allow sheet to dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        path.removeLast()
                    }
                }
            )
        }
        .alert("Coming Soon", isPresented: $showComingSoonAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(comingSoonType) creation feature is coming soon!")
        }
    }
}

// MARK: - Content Type Card Component

struct ContentTypeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.mediumGray)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(.mediumGray)
                    .font(.body)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct ProfessionalAddContentScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProfessionalAddContentScreen(path: .constant(NavigationPath()))
    }
}
