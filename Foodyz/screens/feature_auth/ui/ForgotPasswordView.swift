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
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "envelope.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                    }
                    
                    // Title
                    Text("Mot de passe oublié ?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Subtitle
                    Text("Entrez votre adresse e-mail et nous vous enverrons un code de vérification")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Email TextField
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            
                            TextField("Adresse e-mail", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .disabled(viewModel.uiState == .loading)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.isEmailValid && !viewModel.email.isEmpty ? Color.green : Color.clear, lineWidth: 2)
                        )
                        
                        if !viewModel.email.isEmpty && !viewModel.isEmailValid {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Email invalide")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Send Code Button
                    Button(action: {
                        viewModel.sendOtp()
                    }) {
                        HStack {
                            if case .loading = viewModel.uiState {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Envoi en cours...")
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Envoyer le code")
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            viewModel.canSendOtp
                                ? LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                : LinearGradient(
                                    gradient: Gradient(colors: [Color.gray, Color.gray]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: viewModel.canSendOtp ? Color.blue.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
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
                        .foregroundColor(.blue)
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
