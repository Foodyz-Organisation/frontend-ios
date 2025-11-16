//
//  VerifyOtpView.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import SwiftUI

struct VerifyOtpView: View {
    let email: String
    
    @StateObject private var viewModel = VerifyOtpViewModel()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToResetPassword = false
    @State private var resetToken = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        let gradient = LinearGradient(
            colors: [Color(hex: 0xFFFBEA), Color(hex: 0xFFF8D6), Color(hex: 0xFFF6C1)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        ZStack {
            gradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Icon avec animation
                    ZStack {
                        Circle()
                            .fill(RadialGradient(
                                gradient: Gradient(colors: [Color(hex: 0xFFECB3), Color(hex: 0xFFC107)]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            ))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "lock.shield.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(Color(hex: 0x5F370E))
                    }
                    .shadow(color: Color(hex: 0xFFC107).opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Title
                    Text("Vérification")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: 0xB87300))
                    
                    // Subtitle
                    VStack(spacing: 8) {
                        Text("Nous avons envoyé un code à 6 chiffres à")
                            .font(.body)
                            .foregroundColor(Color(hex: 0x6B7280))
                        Text(email)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: 0xF59E0B))
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // OTP Input Field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "number.circle.fill")
                                .foregroundColor(Color(hex: 0xF59E0B))
                                .frame(width: 24)
                            
                            TextField("Code à 6 chiffres", text: $viewModel.otp)
                                .keyboardType(.numberPad)
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .disabled(viewModel.uiState == .loading)
                                .foregroundColor(Color(hex: 0x5F370E))
                                .onChange(of: viewModel.otp) { newValue in
                                    viewModel.otp = viewModel.formatOtpInput(newValue)
                                }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    viewModel.isOtpValid ? Color(hex: 0x4CAF50) : (viewModel.otp.isEmpty ? Color.clear : Color(hex: 0xF59E0B)),
                                    lineWidth: 2
                                )
                        )
                        
                        // Validation messages
                        if !viewModel.otp.isEmpty {
                            HStack {
                                Image(systemName: viewModel.isOtpValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(viewModel.isOtpValid ? Color(hex: 0x4CAF50) : Color(hex: 0xF59E0B))
                                
                                if viewModel.otp.count != 6 {
                                    Text("Le code doit contenir 6 chiffres (\(viewModel.otp.count)/6)")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: 0xF59E0B))
                                } else if viewModel.isOtpValid {
                                    Text("Code valide")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: 0x4CAF50))
                                }
                            }
                            .padding(.leading, 4)
                            .animation(.easeInOut, value: viewModel.otp)
                        }
                        
                        // Progress indicator
                        if !viewModel.otp.isEmpty && viewModel.otp.count < 6 {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                    
                                    Rectangle()
                                        .fill(Color(hex: 0xF59E0B))
                                        .frame(width: geometry.size.width * (Double(viewModel.otp.count) / 6.0), height: 4)
                                        .cornerRadius(2)
                                        .animation(.easeInOut, value: viewModel.otp.count)
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Verify Button
                    Button(action: {
                        print("Vérification OTP: \(viewModel.otp) pour email: \(email)")
                        viewModel.verifyOtp(email: email)
                    }) {
                        HStack(spacing: 12) {
                            if case .loading = viewModel.uiState {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: 0x5F370E)))
                                    .scaleEffect(0.8)
                                Text("Vérification...")
                                    .foregroundColor(Color(hex: 0x5F370E))
                            } else {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(Color(hex: 0x5F370E))
                                Text("Vérifier le code")
                                    .foregroundColor(Color(hex: 0x5F370E))
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            viewModel.canVerify
                                ? LinearGradient(
                                    colors: [Color(hex: 0xFFE15A), Color(hex: 0xF59E0B)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                : LinearGradient(
                                    colors: [Color(hex: 0xE0E0E0), Color(hex: 0xBDBDBD)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                        )
                        .cornerRadius(18)
                        .shadow(color: viewModel.canVerify ? Color(hex: 0xF59E0B).opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!viewModel.canVerify)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Resend code button
                    Button(action: {
                        // TODO: Implement resend OTP
                        print("Renvoyer le code")
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Renvoyer le code")
                        }
                        .foregroundColor(Color(hex: 0xF59E0B))
                        .fontWeight(.medium)
                    }
                    .disabled(viewModel.uiState == .loading)
                    .padding(.top, 8)
                    
                    // Back Button
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Retour")
                        }
                        .foregroundColor(Color(hex: 0x6B7280))
                    }
                    .disabled(viewModel.uiState == .loading)
                    
                    Spacer()
                }
            }
            
            // Navigation Link (hidden)
            NavigationLink(
                destination: ResetPasswordView(email: email, resetToken: resetToken),
                isActive: $navigateToResetPassword
            ) {
                EmptyView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.uiState == .loading)
        .alert("Message", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if case .verified(_, let token) = viewModel.uiState {
                    resetToken = token
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToResetPassword = true
                        viewModel.resetState()
                    }
                } else {
                    viewModel.resetState()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: viewModel.uiState) { newState in
            handleStateChange(newState)
        }
    }
    
    private func handleStateChange(_ state: VerifyOtpUiState) {
        switch state {
        case .idle:
            break
            
        case .loading:
            print("⏳ Chargement...")
            
        case .verified(let email, let token):
            print("✅ OTP vérifié! Email: \(email), Token: \(token.prefix(20))...")
            alertMessage = "Code vérifié avec succès!\n\nVous pouvez maintenant réinitialiser votre mot de passe"
            showAlert = true
            
        case .error(let message):
            print("❌ Erreur: \(message)")
            alertMessage = message
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        VerifyOtpView(email: "test@example.com")
    }
}
