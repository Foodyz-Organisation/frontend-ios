import SwiftUI

// MARK: - Professional Drawer Component
struct ProfessionalDrawer: View {
    var onCloseDrawer: () -> Void
    var navigateTo: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Foodyz Pro")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("Professional")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onCloseDrawer) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .padding(8)
                }
            }
            .padding()
            .background(Color.white)
            
            Divider()
            
            // Menu Items
            ScrollView {
                VStack(spacing: 0) {
                    DrawerMenuItem(icon: "house.fill", title: "Home", isSelected: true) {
                        onCloseDrawer()
                    }
                    
                    DrawerMenuItem(icon: "fork.knife", title: "Menu Management") {
                        navigateTo("menu")
                    }
                    
                    DrawerMenuItem(icon: "chart.bar.fill", title: "Analytics") {
                        navigateTo("analytics")
                    }
                    
                    DrawerMenuItem(icon: "bell.fill", title: "Notifications") {
                        navigateTo("notifications")
                    }
                    
                    DrawerMenuItem(icon: "exclamationmark.triangle.fill", title: "Reclamations") {
                        navigateTo("reclamations")
                    }
                    
                    DrawerMenuItem(icon: "gearshape.fill", title: "Settings") {
                        navigateTo("settings")
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    DrawerMenuItem(icon: "rectangle.portrait.and.arrow.right", title: "Logout", color: .red) {
                        navigateTo("logout")
                    }
                }
            }
            
            Spacer()
        }
        .frame(width: 280)
        .background(Color.white)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 2, y: 0)
    }
}

struct DrawerMenuItem: View {
    let icon: String
    let title: String
    var isSelected: Bool = false
    var color: Color = .black
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color(red: 0.99, green: 0.69, blue: 0.16) : color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? Color(red: 0.99, green: 0.69, blue: 0.16) : color)
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color(red: 0.99, green: 0.69, blue: 0.16))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(isSelected ? Color(red: 0.99, green: 0.69, blue: 0.16).opacity(0.1) : Color.clear)
        }
    }
}
