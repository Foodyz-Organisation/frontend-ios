import SwiftUI

// MARK: - Professional Drawer Component
struct ProfessionalDrawer: View {
    var onCloseDrawer: () -> Void
    var navigateTo: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                onCloseDrawer()
                navigateTo("profile")
            }) {
                HStack(spacing: 16) {
                    Button(action: onCloseDrawer) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    
                    Text("Menu")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60) // Add top padding for safe area manually since we ignore safe area
                .padding(.bottom, 20)
                .background(Color.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Menu Items List
            ScrollView {
                VStack(spacing: 16) {
                    DrawerCardItem(icon: "tag.fill", title: "Deals Management", color: Color(red: 1.0, green: 0.97, blue: 0.88), iconColor: Color(red: 1.0, green: 0.63, blue: 0.0)) {
                        navigateTo("deals_management")
                    }
                    
                    DrawerCardItem(icon: "exclamationmark.triangle.fill", title: "Reclamations", color: Color(red: 1.0, green: 0.97, blue: 0.88), iconColor: Color(red: 1.0, green: 0.63, blue: 0.0)) {
                        navigateTo("reclamations")
                    }
                    
                    DrawerCardItem(icon: "book.fill", title: "Menu Management", color: Color(red: 1.0, green: 0.97, blue: 0.88), iconColor: Color(red: 1.0, green: 0.63, blue: 0.0)) {
                        navigateTo("menu")
                    }
                    
                    DrawerCardItem(icon: "calendar", title: "Event Management", color: Color(red: 1.0, green: 0.97, blue: 0.88), iconColor: Color(red: 1.0, green: 0.63, blue: 0.0)) {
                         navigateTo("events")
                    }
                    
                    DrawerCardItem(icon: "bell.fill", title: "Notifications", color: .white, iconColor: .black) {
                        navigateTo("notifications")
                    }

                    DrawerCardItem(icon: "chart.bar.fill", title: "Analytics", color: .white, iconColor: .black) {
                         navigateTo("analytics")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            
            Spacer()
            
            // Logout Button
            Button(action: { navigateTo("logout") }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18))
                    Text("Logout")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(20)
            .padding(.bottom, 30) // Bottom safe area
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.98, blue: 0.98)) // Light gray background
        .edgesIgnoringSafeArea(.all)
    }
}

struct DrawerCardItem: View {
    let icon: String
    let title: String
    var color: Color
    var iconColor: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}
