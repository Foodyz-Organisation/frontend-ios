import Foundation
import SwiftUI

// MARK: - Custom Colors (No change)

extension Color {
    static let foodyzOrange = Color(red: 0.99, green: 0.69, blue: 0.16)
    static let foodyzBackground = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let acceptedGreen = Color(red: 0.23, green: 0.76, blue: 0.38)
    static let refusedRed = Color(red: 1.0, green: 0.25, blue: 0.25)
    static let iconGray = Color(red: 0.7, green: 0.7, blue: 0.7)
    static let iconBgOrange = Color(red: 1.0, green: 0.89, blue: 0.75)
    static let locationPurple = Color(red: 0.6, green: 0.4, blue: 0.8)
    static let iconBgPurple = Color(red: 0.96, green: 0.94, blue: 1.0)
    static let mediumGray = Color(white: 0.4)
}

// MARK: - Main View (HomeProfessionalView)

struct HomeProfessionalView: View {
    // Navigation binding from parent (AppNavigation)
    @Binding var path: NavigationPath
    let professionalId: String

    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Background
            Color.foodyzBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                
                // --- 1. Custom Top Bar (Now uses path binding) ---
                FoodyzTopBar(path: $path)
                
                // --- 2. Content Area ---
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // --- Tab Icons Row ---
                        TabIconRow(path: $path) // Pass navigation binding
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        
                        // --- Pending Orders Section ---
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pending Orders")
                                .font(.title2)
                                .fontWeight(.heavy)
                                .foregroundColor(.black)
                            Text("2 delivery orders waiting for confirmation")
                                .font(.subheadline)
                                .foregroundColor(.mediumGray)
                        }
                        .padding(.horizontal, 20)
                        
                        // --- Sample Pending Orders ---
                        VStack(spacing: 15) {
                            OrderCardView(
                                name: "Ahmed Ben Ali",
                                order: "Couscous Royal (x1), Mint Tea (x2)",
                                time: "5 minutes ago",
                                total: "25.50 TND",
                                location: "Avenue Habib Bourguiba, Tunis",
                                avatarImage: "person.circle.fill"
                            )
                            
                            OrderCardView(
                                name: "Leila Jebali",
                                order: "Vegetarian Mezze Platter (x1)",
                                time: "25 minutes ago",
                                total: "28.00 TND",
                                location: "Rue de Marseille, La Marsa",
                                avatarImage: "person.circle.fill"
                            )
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 120) // Space for bottom bar
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            
            // --- 3. Custom Bottom Bar ---
            FoodyzBottomBar()
        }
        // Hide system back button
        .navigationBarBackButtonHidden(true)
        // 🛑 REMOVED REDUNDANT .navigationDestination BLOCK
        // The .navigationDestination must only exist in AppNavigation.
    }
}


// MARK: - Component 1: FoodyzTopBar

struct FoodyzTopBar: View {
    // 🟢 CHANGED: Use path binding directly instead of optional closure
    @Binding var path: NavigationPath
    
    var body: some View {
        HStack {
            // Avatar
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 35, height: 35)
                .foregroundColor(.iconGray)
            
            Text("Foodyz Pro")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.leading, 4)
            
            Spacer()
            
            // Search Icon
            Image(systemName: "magnifyingglass")
                .font(.title3)
                .foregroundColor(.black)
                .padding(10)
            
            // Menu Icon (Navigation Trigger)
            Button(action: {
                // 🟢 FIX: Navigate using the correct Screen enum
                path.append(Screen.menu)
            }) {
                Image(systemName: "line.horizontal.3")
                .font(.title3)
                .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 15)
        .padding(.bottom, 15)
        .background(Color.white)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 5)
    }
}

// MARK: - Component 2: Tab Icon Row

struct TabIconRow: View {
    @Binding var path: NavigationPath

    let icons: [(systemName: String, isSelected: Bool, badge: Int)] = [
        ("house.fill", true, 0),
        ("plus.square.fill", false, 0),
        ("list.bullet.rectangle.fill", false, 0), // Menu/Order List
        ("bubble.left.fill", false, 1),
        ("bell.fill", false, 3)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(icons.indices, id: \.self) { index in
                let icon = icons[index]
                
                Button(action: {
                    if icon.systemName == "list.bullet.rectangle.fill" {
                        // 🟢 FIX: Navigate using the correct Screen enum
                        path.append(Screen.menu)
                    } else {
                        print("Tapped on \(icon.systemName)")
                    }
                }) {
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if icon.isSelected {
                                ZStack {
                                    Circle()
                                        .fill(Color.iconBgOrange)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: icon.systemName)
                                        .foregroundColor(.foodyzOrange)
                                        .font(.title3)
                                        .fontWeight(.medium)
                                }
                            } else {
                                Image(systemName: icon.systemName)
                                    .font(.title2)
                                    .foregroundColor(.black.opacity(0.7))
                                    .frame(width: 50, height: 50)
                            }
                        }
                        
                        if icon.badge == 1 {
                            Circle()
                                .fill(Color.refusedRed)
                                .frame(width: 8, height: 8)
                                .offset(x: 5, y: 5)
                        } else if icon.badge > 1 {
                            Text("\(icon.badge)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Circle().fill(Color.refusedRed))
                                .offset(x: 10, y: 0)
                        }
                    }
                }
                
                if index < icons.count - 1 {
                    Spacer()
                }
            }
        }
    }
}


// MARK: - Component 3: Order Card View (No change)

struct OrderCardView: View {
    let name: String
    let order: String
    let time: String
    let total: String
    let location: String
    let avatarImage: String
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(alignment: .top) {
                // Avatar (Placeholder)
                Image(systemName: avatarImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .foregroundColor(.iconGray)
                    .overlay(Circle().stroke(Color.foodyzBackground, lineWidth: 2))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(order)
                        .font(.subheadline)
                        .foregroundColor(.mediumGray)
                        .lineLimit(1)
                    
                    Text("Received \(time)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Order Total")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(total)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.acceptedGreen)
                }
            }
            
            // Divider
            Divider()
                .padding(.horizontal, -15)
            
            // Location
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.locationPurple)
                Text(location)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.locationPurple)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color.iconBgPurple)
            .cornerRadius(8)
            
            // Action Buttons
            HStack(spacing: 10) {
                // Accept Button
                ActionButton(
                    label: "Accept",
                    iconName: "checkmark.circle.fill",
                    color: .acceptedGreen
                )
                
                // Refuse Button
                ActionButton(
                    label: "Refuse",
                    iconName: "xmark.circle.fill",
                    color: .refusedRed
                )
                
                // Flag/Chat Button (Smaller)
                Button(action: {}) {
                    Image(systemName: "flag.fill")
                        .font(.title3)
                        .foregroundColor(.mediumGray)
                        .frame(width: 50, height: 50)
                        .background(Color.foodyzBackground)
                        .cornerRadius(10)
                }
            }
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
}

// Helper for Action Buttons (No change)
struct ActionButton: View {
    let label: String
    let iconName: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: iconName)
                Text(label)
                    .lineLimit(1)
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .cornerRadius(10)
        }
    }
}


// MARK: - Component 4: FoodyzBottomBar (Mode Selector) (No change)

struct FoodyzBottomBar: View {
    var body: some View {
        HStack(spacing: 10) {
            // Pick-up
            BottomBarItem(iconName: "cube.box.fill", label: "Pick-up", isSelected: false)
            
            // Res Table (Restaurant Table/Dine-in)
            BottomBarItem(iconName: "fork.knife", label: "Dine-in", isSelected: false)
            
            // Delivery (Selected/Primary)
            BottomBarItem(iconName: "bag.fill", label: "Delivery", isSelected: true)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: -5)
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
    }
}

struct BottomBarItem: View {
    let iconName: String
    let label: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.body)
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(isSelected ? .white : .mediumGray)
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.foodyzOrange : Color.white)
        .cornerRadius(20)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Navigation Host & Preview (No change)

// Host view to contain the NavigationStack and manage the path
struct HomeProfessionalHostView: View {
    @State private var path = NavigationPath()
    @State private var professionalId: String = "" // Store dynamic ID from login

    var body: some View {
        NavigationStack(path: $path) {
            HomeProfessionalView(path: $path, professionalId: professionalId)
                .navigationBarHidden(true)
        }
    }
}


#Preview {
    HomeProfessionalHostView()
}
