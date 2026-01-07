import SwiftUI

struct ProfessionalChangePasswordScreen: View {
    @Environment(\.dismiss) var dismiss
    
    // State variables for fields
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    
    // Visibility states
    @State private var showCurrentPassword: Bool = false
    @State private var showNewPassword: Bool = false
    @State private var showConfirmNewPassword: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            ZStack(alignment: .leading) {
                Color.orange // Match Color.foodyzOrange
                    .ignoresSafeArea(edges: .top)
                
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 16)
                    
                    Text("Change Password")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading, 16)
                    
                    Spacer()
                    
                    // Checkmark/Save Button
                    Button(action: {
                        // TODO: Save Action
                        dismiss()
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 16)
            }
            .frame(height: 60)
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 1. Current Password
                    PasswordField(
                        title: "Current Password",
                        placeholder: "Enter current password",
                        text: $currentPassword,
                        isVisible: $showCurrentPassword
                    )
                    
                    // 2. New Password
                    PasswordField(
                        title: "New Password",
                        placeholder: "Enter new password",
                        text: $newPassword,
                        isVisible: $showNewPassword
                    )
                    
                    // 3. Confirm New Password
                    PasswordField(
                        title: "Confirm New Password",
                        placeholder: "Confirm new password",
                        text: $confirmNewPassword,
                        isVisible: $showConfirmNewPassword
                    )
                    
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Components

struct PasswordField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
            
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
                
                Button(action: {
                    isVisible.toggle()
                }) {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill") // Using standard eye icons
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    ProfessionalChangePasswordScreen()
}
