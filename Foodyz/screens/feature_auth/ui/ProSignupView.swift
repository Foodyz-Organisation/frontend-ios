import SwiftUI
import PhotosUI

struct ProSignupView: View {
    var onFinish: (() -> Void)? = nil
    
    // MARK: - StateObject for API calls
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var confirmPassword: String = ""
    
    // For Image Picker
    @State private var selectedItem: PhotosPickerItem? = nil
    
    // For Navigation to Map Picker
    @State private var showMapPicker = false
    
    var body: some View {
        ZStack {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Progress Indicator
                HStack(spacing: 0) {
                    ProgressDot(active: viewModel.currentStep >= 1)
                    ProgressLine(active: viewModel.currentStep > 1)
                    ProgressDot(active: viewModel.currentStep >= 2)
                    ProgressLine(active: viewModel.currentStep > 2)
                    ProgressDot(active: viewModel.currentStep >= 3)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                .padding(.horizontal, 60)
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - Step 1: Basic Info
                        if viewModel.currentStep == 1 {
                            Step1BasicInfoView(
                                viewModel: viewModel,
                                confirmPassword: $confirmPassword,
                                showPassword: $showPassword,
                                showConfirmPassword: $showConfirmPassword
                            )
                            .transition(.move(edge: .leading))
                        }
                        
                        // MARK: - Step 2: Verification
                        if viewModel.currentStep == 2 {
                            Step2PermitView(viewModel: viewModel, selectedItem: $selectedItem)
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                .onChange(of: selectedItem) { oldValue, newValue in
                                    guard let newValue = newValue else { return }
                                    
                                    Task {
                                        if let data = try? await newValue.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            // Use default filename for permit image
                                            let fileName = "permit_image.jpg"
                                            
                                            await MainActor.run {
                                                viewModel.convertImageToBase64(uiImage, fileName: fileName)
                                            }
                                        }
                                    }
                                }
                        }
                        
                        // MARK: - Step 3: Location
                        if viewModel.currentStep == 3 {
                            Step3LocationView(viewModel: viewModel, showMapPicker: $showMapPicker)
                                .transition(.move(edge: .trailing))
                        }
                    }
                    .padding(.horizontal, 24)
                    .animation(.spring(), value: viewModel.currentStep)
                }
                
                // MARK: - Bottom Navigation
                HStack(spacing: 16) {
                    if viewModel.currentStep > 1 {
                        Button(action: {
                            withAnimation { viewModel.currentStep -= 1 }
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Back")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: 0xB87300))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: 0xB87300), lineWidth: 1)
                            )
                        }
                    }
                    
                    Button(action: nextStepAction) {
                        ZStack {
                            if viewModel.isLoading {
                                ProgressView().tint(.black)
                            } else {
                                HStack {
                                    Text(viewModel.currentStep == 3 ? "Complete Registration" : "Continue")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: 0xFFD700)) // Foodyz Yellow
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(24)
            }
            
            // Error overlay
            if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(12)
                        .padding(.bottom, 100)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                viewModel.errorMessage = nil
                            }
                        }
                }
                .padding()
                .transition(.move(edge: .bottom))
            }
        }
        .sheet(isPresented: $showMapPicker) {
            ProMapPickerView(selectedLocation: $viewModel.selectedLocation)
        }
        .alert("Registration Successful!", isPresented: $viewModel.showSuccessDialog) {
            Button("OK") {
                viewModel.showSuccessDialog = false
                // Navigate to login after a brief delay to allow dialog to dismiss smoothly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onFinish?()
                }
            }
        } message: {
            if let permitNumber = viewModel.permitNumberExtracted {
                Text("Your restaurant permit number \(permitNumber) has been successfully verified!")
            } else {
                Text("Your professional account has been created successfully!")
            }
        }
    }
    
    // MARK: - Actions
    private func nextStepAction() {
        if viewModel.currentStep == 1 {
            // Validate Step 1
            if viewModel.fullName.isEmpty || viewModel.email.isEmpty || viewModel.password.isEmpty {
                viewModel.errorMessage = "Please fill in all required fields."
                return
            }
            if viewModel.password.count < 6 {
                viewModel.errorMessage = "Password must be at least 6 characters."
                return
            }
            if viewModel.password != confirmPassword {
                viewModel.errorMessage = "Passwords do not match."
                return
            }
            withAnimation { viewModel.currentStep = 2 }
        } else if viewModel.currentStep == 2 {
            // Validate Step 2
            // Allowing skip based on screenshot text "You can skip this step..." if that is the intent, 
            // otherwise force it. The text says "You can skip this step and add it later".
             withAnimation { viewModel.currentStep = 3 }
        } else if viewModel.currentStep == 3 {
             // Validate Step 3 (Optional as per text "Adding your location is optional")
            submitRegistration()
        }
    }
    
    private func submitRegistration() {
        let proData = ProfessionalSignupRequest(
            email: viewModel.email,
            password: viewModel.password,
            fullName: viewModel.fullName,
            licenseNumber: nil, // Will be from OCR later
            licenseImage: viewModel.permitImageBase64,
            licenseImageUrl: nil,
            linkedUserId: nil,
            locations: viewModel.selectedLocation != nil ? [viewModel.selectedLocation!] : nil
        )
        
        Task {
            await viewModel.signupProfessional(proData: proData)
            
            if viewModel.errorMessage == nil && !viewModel.showSuccessDialog {
                // Only call onFinish if not showing success dialog (will be called after dialog)
            }
        }
    }
}

// MARK: - Step 1: Basic Info
struct Step1BasicInfoView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var confirmPassword: String
    @Binding var showPassword: Bool
    @Binding var showConfirmPassword: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image("foodyz_logo_orange") // Ensure this asset exists
                .resizable()
                .scaledToFit()
                .frame(height: 100)
            
            VStack(spacing: 8) {
                Text("Welcome to foodyz!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: 0xB87300))
                
                Text("Create your professional account")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 16) {
                ProTextField(icon: "person.fill", placeholder: "Full Name / Business Contact", text: $viewModel.fullName)
                ProTextField(icon: "envelope.fill", placeholder: "Email Address", text: $viewModel.email, keyboardType: .emailAddress)
                ProSecureField(icon: "lock.fill", placeholder: "Password", text: $viewModel.password, showPassword: $showPassword, footer: "Minimum 6 characters")
                ProSecureField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword, showPassword: $showConfirmPassword)
            }
        }
    }
}

// MARK: - Step 2: Permit Upload
struct Step2PermitView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 28) {
            // Icon
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 42))
                .foregroundColor(.white)
                .frame(width: 90, height: 90)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.86, green: 0.99, blue: 0.91), Color(red: 0.06, green: 0.73, blue: 0.51)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
            
            Text("Business Verification")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(Color(hex: 0xB87300))
            
            Text("Build trust with your customers")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
            
            // Upload Section
            if viewModel.isCompressingImage {
                // Compression Progress
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: 0xFFD700)))
                        .scaleEffect(1.5)
                    
                    Text("Compressing image...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: 0xB87300))
                    
                    Text("This will take a few seconds")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: 0xFFD700), lineWidth: 2)
                )
                
            } else if viewModel.permitImage == nil {
                // Upload Button
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                        
                        Text("📷 Upload Restaurant Permit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Tap to upload permit photo\nor take a photo")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.90, green: 0.91, blue: 0.93), lineWidth: 2)
                    )
                }
                
            } else {
                // Image Preview
                VStack(spacing: 16) {
                    if let image = viewModel.permitImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                    }
                    
                    if let fileName = viewModel.permitFileName {
                        Text(fileName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    if let fileSize = viewModel.permitFileSize {
                        Text(fileSize)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                    }
                    
                    HStack(spacing: 16) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("Change Photo")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button("Remove") {
                            viewModel.clearPermitImage()
                            selectedItem = nil
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.06, green: 0.73, blue: 0.51), lineWidth: 2)
                )
            }
            
            // Info Box
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color(hex: 0xB87300))
                    .font(.system(size: 20))
                
                Text("Upload \"Autorisation d'exploitation d'un restaurant\" document. Your permit helps customers trust your business. You can skip this step and add it later from your profile.")
                    .font(.caption)
                    .foregroundColor(Color(hex: 0x5D4037))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(hex: 0xFFF8E1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Step 3: Location
struct Step3LocationView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var showMapPicker: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0x4CD964))
                    .frame(width: 80, height: 80)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Almost there!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: 0xB87300))
                 
                Text("Help customers find your restaurant")
                    .foregroundColor(.gray)
            }
            
            // Location Card
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Restaurant Location")
                            .font(.headline)
                            .foregroundColor(.black)
                        Text(viewModel.selectedLocation?.address ?? "Tap to add your location")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    Button(action: { showMapPicker = true }) {
                        Text(viewModel.selectedLocation == nil ? "+ Add" : "Edit")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: 0xFFD700))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(hex: 0xF5F6F8))
            .cornerRadius(12)
            
            // Info Box
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color(hex: 0xB87300))
                    .font(.system(size: 20))
                
                Text("Adding your location is optional but recommended. It helps customers discover your restaurant and improves your visibility.")
                    .font(.caption)
                    .foregroundColor(Color(hex: 0x5D4037))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(hex: 0xFFF8E1))
            .cornerRadius(12)
        }
    }
}


// MARK: - Components

struct ProgressDot: View {
    let active: Bool
    var body: some View {
        Circle()
            .fill(active ? Color(hex: 0xFFC107) : Color.gray.opacity(0.3)) // Amber/Yellow
            .frame(width: 12, height: 12)
    }
}

struct ProgressLine: View {
    let active: Bool
    var body: some View {
        Rectangle()
            .fill(active ? Color(hex: 0xFFC107) : Color.gray.opacity(0.3))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }
}

// Custom styled fields for Pro Signup
struct ProTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: 0xB87300))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color(hex: 0xF5F6F8))
        .cornerRadius(12)
    }
}

struct ProSecureField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    var footer: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: 0xB87300))
                    .frame(width: 20)
                
                if showPassword {
                    TextField(placeholder, text: $text)
                        .autocapitalization(.none)
                } else {
                    SecureField(placeholder, text: $text)
                }
                
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(hex: 0xF5F6F8))
            .cornerRadius(12)
            
            if let footer = footer {
                Text(footer)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 4)
            }
        }
    }
}

#Preview {
    ProSignupView()
}

