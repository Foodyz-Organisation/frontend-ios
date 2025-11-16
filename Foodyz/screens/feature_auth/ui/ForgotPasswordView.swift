//
//  ForgotPasswordView.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToVerifyOtp = false
    @State private var emailToPass = ""
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
                        
                        Image(systemName: "envelope.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(Color(hex: 0x5F370E))
                    }
                    .shadow(color: Color(hex: 0xFFC107).opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Title
                    Text("Mot de passe oublié ?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: 0xB87300))
                    
                    // Subtitle
                    Text("Entrez votre adresse e-mail et nous vous enverrons un code de vérification")
                        .font(.body)
                        .foregroundColor(Color(hex: 0x6B7280))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Email TextField
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(Color(hex: 0xF59E0B))
                                .frame(width: 24)
                            
                            TextField("Adresse e-mail", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .disabled(viewModel.uiState == .loading)
                                .foregroundColor(Color(hex: 0x5F370E))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(viewModel.isEmailValid && !viewModel.email.isEmpty ? Color(hex: 0x4CAF50) : Color.clear, lineWidth: 2)
                        )
                        
                        if !viewModel.email.isEmpty && !viewModel.isEmailValid {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Email invalide")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Send Code Button
                    Button(action: {
                        viewModel.sendOtp()
                    }) {
                        HStack(spacing: 12) {
                            if case .loading = viewModel.uiState {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: 0x5F370E)))
                                    .scaleEffect(0.8)
                                Text("Envoi en cours...")
                                    .foregroundColor(Color(hex: 0x5F370E))
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(Color(hex: 0x5F370E))
                                Text("Envoyer le code")
                                    .foregroundColor(Color(hex: 0x5F370E))
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            viewModel.canSendOtp
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
                        .shadow(color: viewModel.canSendOtp ? Color(hex: 0xF59E0B).opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!viewModel.canSendOtp)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Back to Login Button
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Retour à la connexion")
                        }
                        .foregroundColor(Color(hex: 0xF59E0B))
                        .fontWeight(.medium)
                    }
                    .disabled(viewModel.uiState == .loading)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
            
            // Navigation Link (hidden)
            NavigationLink(
                destination: VerifyOtpView(email: emailToPass),
                isActive: $navigateToVerifyOtp
            ) {
                EmptyView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.uiState == .loading)
        .alert("Message", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if case .otpSent(let email) = viewModel.uiState {
                    emailToPass = email
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToVerifyOtp = true
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
    
    private func handleStateChange(_ state: ForgotPasswordUiState) {
        switch state {
        case .idle:
            break
            
        case .loading:
            break
            
        case .otpSent(let email):
            alertMessage = "Code envoyé à \(email)\n\nVérifiez votre boîte e-mail"
            showAlert = true
            
        case .error(let message):
            alertMessage = message
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
