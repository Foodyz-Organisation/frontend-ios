import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sessionManager: SessionManager
    
    // State for notification toggle
    @State private var notificationsEnabled = true
    
    // Callback for logout
    var onLogout: () -> Void = {}
    // Callback for edit profile
    var onEditProfile: () -> Void = {}
    // Callback for change password
    var onChangePassword: () -> Void = {}
    
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
                
                Spacer()
                
                Text("PROFILE SETTING")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .textCase(.uppercase)
                
                Spacer()
                
                // Invisible placeholder to balance the header
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .background(Color.white)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - General Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("General")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                        
                        VStack(spacing: 0) {
                            SettingsRow(icon: "person", title: "Edit Profile", subtitle: "Change profile picture, number, E-mail") {
                                onEditProfile()
                            }
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingsRow(icon: "lock", title: "Change Password", subtitle: "Update and strengthen account security") {
                                onChangePassword()
                            }
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingsRow(icon: "shield", title: "Terms of Use", subtitle: "Protect your account now") {
                                // Open Terms
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    // MARK: - Preferences Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                        
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                Image(systemName: "bell")
                                    .font(.system(size: 20))
                                    .foregroundColor(.orange)
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notification")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Text("Customize your notification preferences")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $notificationsEnabled)
                                    .labelsHidden()
                                    .tint(.orange)
                            }
                            .padding()
                            .background(Color.white)
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            Button(action: {
                                SessionManager.shared.clear()
                                onLogout()
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red)
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Log Out")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.red)
                                        
                                        Text("Securely log out of Account")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .contentShape(Rectangle())
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(20)
            }
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.99)) // Very light gray background
        .navigationBarHidden(true)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(icon == "lock" || icon == "shield" ? .orange : .orange) // All orange based on design
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
            .contentShape(Rectangle())
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
