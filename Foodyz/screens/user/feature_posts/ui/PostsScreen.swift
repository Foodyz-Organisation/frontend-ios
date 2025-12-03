import SwiftUI

// MARK: - PostsScreen
struct PostsScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Ready to be ordered 🍽️")
                .font(.system(size: 22, weight: .bold))
                // Note: Using a direct hex color since AppColors is defined externally
                .foregroundColor(Color(hex: "#1F2937"))
                .padding(.bottom, 8)
                // Aligning header with the card content
                .padding(.horizontal, 16)
            
            // Example posts
            VStack(spacing: 20) {
                RecipeCard(
                    imageName: "pasta",
                    prepareTime: 15,
                    rating: 4.9,
                    title: "Rainbow Buddha Bowl",
                    subtitle: "Green Garden",
                    tags: ["Vegan", "Healthy"],
                    price: "28 DT"
                )
                
                RecipeCard(
                    imageName: "rice",
                    prepareTime: 25,
                    rating: 4.7,
                    title: "Creamy Pesto Pasta",
                    subtitle: "Italian Delights",
                    tags: ["Vegetarian", "Dinner"],
                    price: "35 DT"
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16) // Added padding to bottom of the list
        }
        // Note: Removing ScrollView here. The main screen (HomeUserScreen) will wrap this in its ScrollView.
        .background(Color.white) // Using Color.white directly
    }
}

// MARK: - RecipeCard
struct RecipeCard: View {
    let imageName: String
    let prepareTime: Int
    let rating: Double
    let title: String
    let subtitle: String
    let tags: [String]
    let price: String
    
    @State private var isFavorite = false
    @State private var isBookmarked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Image Placeholder (Replace with actual Image in a real project)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(Text("Image: \(imageName)").foregroundColor(.white)) // Use image name as placeholder text
                    .clipped()
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                
                // Prepare time badge
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 12))
                    Text("Prepare \(prepareTime) min").font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.white.opacity(0.9)).cornerRadius(12)
                .padding(12)
                
                // Favorite icon
                HStack {
                    Spacer()
                    Button { isFavorite.toggle() } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .white)
                            .font(.system(size: 24))
                            .padding(12)
                    }
                }
                
                // Rating badge
                VStack {
                    Spacer()
                    HStack {
                        Label("\(String(format: "%.1f", rating))", systemImage: "star.fill")
                            .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.yellow).cornerRadius(12)
                        Spacer()
                    }
                    .padding(12)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.system(size: 20, weight: .bold))
                Text(subtitle).font(.system(size: 14)).foregroundColor(Color.gray)
                
                // Tags
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color(hex: "#E5E7EB")) // Using direct hex
                            .cornerRadius(10)
                    }
                }
                
                HStack {
                    Text(price).font(.system(size: 18, weight: .bold))
                    Spacer()
                    HStack(spacing: 16) {
                        Image(systemName: "message")
                        Image(systemName: "square.and.arrow.up")
                        Image(systemName: "star")
                        Button { isBookmarked.toggle() } label: {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(isBookmarked ? Color(hex: "#4F46E5") : Color.gray) // Using direct hex
                        }
                    }
                    .font(.system(size: 20)).foregroundColor(Color.gray)
                }
            }
            .padding(16)
        }
        .background(Color.white).cornerRadius(24).shadow(radius: 4)
    }
}

// MARK: - Helpers (Redefined here for PostsScreen to be self-contained as per your prompt)
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 0.0
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
struct PostsScreen_Previews: PreviewProvider {
    static var previews: some View {
        PostsScreen()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
