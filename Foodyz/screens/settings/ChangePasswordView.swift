import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Form fields
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    // Visibility toggles
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                }
                
                Text("Change Password")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.leading, 12)
                
                Spacer()
                
                Button(action: {
                    updatePassword()
                }) {
                    Text("Save")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.0)) // Yellow/Gold
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .background(Color.white)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    Text("Update Password")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3)) // Dark blue-gray
                        .padding(.top, 8)
                    
                    // MARK: - Form Fields
                    VStack(spacing: 20) {
                        ChangePasswordField(
                            placeholder: "Current Password",
                            text: $currentPassword,
                            isVisible: $showCurrentPassword
                        )
                        
                        ChangePasswordField(
                            placeholder: "New Password",
                            text: $newPassword,
                            isVisible: $showNewPassword
                        )
                        
                        ChangePasswordField(
                            placeholder: "Confirm New Password",
                            text: $confirmPassword,
                            isVisible: $showConfirmPassword
                        )
                    }
                    
                    Spacer(minLength: 40)
                    
                    // MARK: - Bottom Button
                    Button(action: {
                        updatePassword()
                    }) {
                        Text("Update Password")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 1.0, green: 0.75, blue: 0.0))
                            .cornerRadius(16)
                    }
                    .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.4), radius: 10, x: 0, y: 4)
                    
                }
                .padding(20)
            }
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.99)) // Very light background
        .navigationBarHidden(true)
    }
    
    private func updatePassword() {
        // TODO: Implement password update logic with API
        dismiss()
    }
}

// MARK: - Subcomponents

struct ChangePasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                .frame(width: 24)
            
            if isVisible {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
            } else {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
            }
            
            Button(action: {
                isVisible.toggle()
            }) {
                Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
}

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ChangePasswordView()
    }
}
