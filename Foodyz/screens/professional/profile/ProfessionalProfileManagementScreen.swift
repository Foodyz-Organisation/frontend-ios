import SwiftUI

struct ProfessionalProfileManagementScreen: View {
    @Binding var path: NavigationPath
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            ZStack(alignment: .leading) {
                Color.orange // Match the exact orange from the design if possible, usually Color.foodyzOrange
                    .ignoresSafeArea(edges: .top)
                
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 16)
                    
                    Text("Profile Management")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading, 16)
                    
                    Spacer()
                }
                .padding(.bottom, 16)
            }
            .frame(height: 60) // Adjust height as needed
            
            // MARK: - List Content
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Professional Data
                    ManagementCard(
                        icon: "building.2.fill", // Similar to the building icon
                        color: .orange,
                        title: "Professional Data",
                        subtitle: "Update images, phone, hours, description, and locations",
                        action: {
                            path.append(Screen.professionalDataEdit)
                        }
                    )
                    
                    // 2. Email & Name
                    ManagementCard(
                        icon: "person.fill",
                        color: .orange,
                        title: "Email & Name",
                        subtitle: "Update your email address and business name",
                        action: {
                            path.append(Screen.professionalEmailNameEdit)
                        }
                    )
                    
                    // 3. Change Password
                    ManagementCard(
                        icon: "lock.fill",
                        color: .orange,
                        title: "Change Password",
                        subtitle: "Update your account password",
                        action: {
                            path.append(Screen.professionalChangePassword)
                        }
                    )
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground)) // Light gray background
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Components

struct ManagementCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                // Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white) // Or transparent if the icon itself is colored
                        // The design shows the icon as orange, maybe no background box, 
                        // or valid white background. Let's assume icon itself is colored.
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                .frame(width: 40, height: 40)
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .padding(.top, 4)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfessionalProfileManagementScreen(path: .constant(NavigationPath()))
}
