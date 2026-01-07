import SwiftUI

struct AddAddressView: View {
    @ObservedObject var viewModel: AuthViewModel
    var onFinish: () -> Void
    var onBack: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: 0xFFFBEA)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Top Animation Section
                VStack {
                    Spacer()
                    LottieView(filename: "locationfinding")
                        .frame(width: 250, height: 250)
                    Spacer()
                }
                .frame(height: UIScreen.main.bounds.height * 0.32)
                .frame(maxWidth: .infinity)
                
                // MARK: - Bottom Content Section
                ZStack {
                    Color.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .ignoresSafeArea(edges: .bottom)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
                    
                    VStack(spacing: 25) {
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 4)
                            .padding(.top, 15)
                        
                        VStack(spacing: 8) {
                            Text("Add Address")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: 0x1E293B))
                            
                            Text("Where should we deliver?")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        
                        CustomTextField(
                            icon: "house.fill",
                            placeholder: "Address",
                            text: $viewModel.address,
                            iconColor: Color(hex: 0xFAB005)
                        )
                        .padding(.horizontal, 24)
                        
                        // Error Message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        HStack(spacing: 16) {
                            Button(action: onBack) {
                                Text("Back")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: 0x1E293B))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                            }
                            
                            Button(action: signupAction) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign Up")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(colors: [Color(hex: 0xFFD43B), Color(hex: 0xFAB005)],
                                               startPoint: .top,
                                               endPoint: .bottom)
                            )
                            .cornerRadius(16)
                            .disabled(viewModel.isLoading)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func signupAction() {
        let signupData = SignupRequest(
            username: viewModel.fullName,
            email: viewModel.email,
            password: viewModel.password,
            phone: viewModel.phone,
            address: viewModel.address,
            avatarUrl: nil // We simplified this for now
        )
        
        Task {
            await viewModel.signup(userData: signupData)
            if viewModel.errorMessage == nil {
                onFinish()
            }
        }
    }
}
