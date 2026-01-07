import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MyProfileViewModel()
    
    // Form fields
    @State private var username: String = ""
    @State private var phoneNumber: String = ""
    @State private var address: String = ""
    @State private var isActive: Bool = true
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    
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
                
                Text("Edit Profile")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.leading, 12)
                
                Spacer()
                
                Button(action: {
                    saveProfile()
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
                    
                    Text("Update Account Details")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3)) // Dark blue-gray
                        .padding(.top, 8)
                    
                    // MARK: - Profile Photo Section
                    VStack(spacing: 16) {
                        Text("Profile Photo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        
                        PhotosPicker(selection: $avatarItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                ZStack {
                                    Circle()
                                        .stroke(Color(red: 1.0, green: 0.85, blue: 0.0), lineWidth: 3) // Yellow ring
                                        .frame(width: 120, height: 120)
                                    
                                    if let avatarImage {
                                        Image(uiImage: avatarImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 108, height: 108)
                                            .clipShape(Circle())
                                    } else {
                                        // Dynamic Logic: Check Check avatarUrl -> profilePictureUrl -> session
                                        let rawUrl = viewModel.profile?.avatarUrl ?? viewModel.profile?.profilePictureUrl
                                        let finalUrl = SessionManager.sanitizeURL(rawUrl)
                                        
                                        if let finalUrl, let url = URL(string: finalUrl) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 108, height: 108)
                                                    .clipShape(Circle())
                                            } placeholder: {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.gray)
                                            }
                                        } else {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.gray)
                                                .frame(width: 108, height: 108)
                                                .background(Color.gray.opacity(0.1))
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                                
                                // Edit icon badge
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color(red: 1.0, green: 0.75, blue: 0.0))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .offset(x: -4, y: -4)
                            }
                        }
                        
                        Text("Tap to change profile photo")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // MARK: - Form Fields
                    VStack(spacing: 20) {
                        EditProfileField(
                            icon: "person.fill",
                            label: "Username",
                            text: $username
                        )
                        
                        EditProfileField(
                            icon: "phone.fill",
                            label: "Phone Number",
                            text: $phoneNumber,
                            keyboardType: .phonePad
                        )
                        
                        EditProfileField(
                            icon: "mappin.and.ellipse",
                            label: "Address",
                            text: $address
                        )
                    }
                    
                    // MARK: - Active Status
                    HStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.0))
                        
                        Text("Account Active Status")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        
                        Spacer()
                        
                        Toggle("", isOn: $isActive)
                            .labelsHidden()
                            .tint(Color(red: 1.0, green: 0.75, blue: 0.0))
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    Spacer(minLength: 20)
                    
                    // MARK: - Bottom Save Button
                    Button(action: {
                        saveProfile()
                    }) {
                        Text("Save Changes")
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
                
                // MARK: - Debug Info (Temporary)
                VStack(alignment: .leading, spacing: 10) {
                    Text("🛠️ Debug Info")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Group {
                        Text("Session Avatar: \(SessionManager.shared.avatarURL?.prefix(50) ?? "nil")...")
                        Text("VM Avatar: \(viewModel.profile?.avatarUrl?.prefix(50) ?? "nil")...")
                        Text("VM Google: \(viewModel.profile?.profilePictureUrl?.prefix(50) ?? "nil")...")
                        if let profile = viewModel.profile {
                             Text("Fallback Used: \((profile.avatarUrl ?? profile.profilePictureUrl)?.prefix(50) ?? "nil")...")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding(.bottom, 20)
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.99)) // Very light background
        .navigationBarHidden(true)
        .task {
            await viewModel.loadProfile(force: false)
            populateFields()
        }
        .onChange(of: viewModel.profile) { _ in
            populateFields()
        }
        .onChange(of: avatarItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    avatarImage = image
                }
            }
        }
    }
    
    private func populateFields() {
        if let profile = viewModel.profile {
            username = profile.username
            phoneNumber = profile.phone ?? ""
            address = profile.address ?? ""
        }
    }
    
    private func saveProfile() {
        Task {
             // Upload avatar if changed
            if let avatarImage {
                // Resize image to max 512x512
                let resizedImage = resizeImage(image: avatarImage, targetSize: CGSize(width: 512, height: 512))
                
                if let data = resizedImage.jpegData(compressionQuality: 0.7) {
                    await viewModel.updateAvatar(with: data)
                }
            }
            
            // Note: Currently only avatar is updated via ViewModel
            // Future: Add update text fields logic here
            
             dismiss()
        }
    }
    
    // Helper to resize image (copied from MyProfileView for consistency)
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}

// MARK: - Subcomponents

struct EditProfileField: View {
    let icon: String
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label cutout effect logic is complex in SwiftUI without ZStack hacks.
            // Using standard styled field matching design:
            // Bordered box with label on top border? Or inside?
            // Screenshot shows Label floating on top border (Android Material Input Layout style)
            
            // Simplified version close to design:
            ZStack(alignment: .topLeading) {
                // Background container
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        .frame(width: 24)
                    
                    TextField("", text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        .keyboardType(keyboardType)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .background(Color.white.cornerRadius(16))
                )
                .padding(.top, 10) // Space for label
                
                // Floating Label
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .background(Color.white)
                    .offset(x: 16, y: 0) // Overlap top border
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
    }
}
