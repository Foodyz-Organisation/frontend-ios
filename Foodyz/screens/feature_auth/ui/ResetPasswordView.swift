//
//  ResetPasswordView.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import SwiftUI

struct ResetPasswordView: View {
    let email: String
    let resetToken: String
    
    @StateObject private var viewModel = ResetPasswordViewModel()
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
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
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(RadialGradient(
                                gradient: Gradient(colors: [Color(hex: 0xFFECB3), Color(hex: 0xFFC107)]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            ))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "key.fill")
                            .resizable()
                            .frame(width: 65, height: 65)
                            .foregroundColor(Color(hex: 0x5F370E))
                    }
                    .shadow(color: Color(hex: 0xFFC107).opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Title
                    Text("Nouveau mot de passe")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: 0xB87300))
                    
                    Text("Créez un mot de passe sécurisé pour votre compte")
                        .font(.body)
                        .foregroundColor(Color(hex: 0x6B7280))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // New Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(Color(hex: 0xF59E0B))
                                .frame(width: 24)
                            
                            Group {
                                if showNewPassword {
                                    TextField("Nouveau mot de passe", text: $viewModel.newPassword)
                                } else {
                                    SecureField("Nouveau mot de passe", text: $viewModel.newPassword)
                                }
                            }
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .disabled(viewModel.uiState == .loading)
                            .foregroundColor(Color(hex: 0x5F370E))
                            
                            Button(action: {
                                showNewPassword.toggle()
                            }) {
                                Image(systemName: showNewPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(Color(hex: 0xF59E0B))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    viewModel.isPasswordValid && !viewModel.newPassword.isEmpty ? Color(hex: 0x4CAF50) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        
                        // Password strength indicator
                        if !viewModel.newPassword.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Force du mot de passe:")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: 0x6B7280))
                                    
                                    Spacer()
                                    
                                    Text(viewModel.passwordStrength.text)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(viewModel.passwordStrength.color)
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 4)
                                            .cornerRadius(2)
                                        
                                        Rectangle()
                                            .fill(viewModel.passwordStrength.color)
                                            .frame(width: geometry.size.width * viewModel.passwordStrength.progress, height: 4)
                                            .cornerRadius(2)
                                            .animation(.easeInOut, value: viewModel.passwordStrength.progress)
                                    }
                                }
                                .frame(height: 4)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(Color(hex: 0xF59E0B))
                                .frame(width: 24)
                            
                            Group {
                                if showConfirmPassword {
                                    TextField("Confirmer le mot de passe", text: $viewModel.confirmPassword)
                                } else {
                                    SecureField("Confirmer le mot de passe", text: $viewModel.confirmPassword)
                                }
                            }
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .disabled(viewModel.uiState == .loading)
                            .foregroundColor(Color(hex: 0x5F370E))
                            
                            Button(action: {
                                showConfirmPassword.toggle()
                            }) {
                                Image(systemName: showConfirmPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(Color(hex: 0xF59E0B))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    viewModel.passwordsMatch ? Color(hex: 0x4CAF50) : (!viewModel.confirmPassword.isEmpty ? Color.red : Color.clear),
                                    lineWidth: 2
                                )
                        )
                        
                        if !viewModel.confirmPassword.isEmpty && !viewModel.passwordsMatch {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Les mots de passe ne correspondent pas")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.leading, 4)
                        } else if viewModel.passwordsMatch {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: 0x4CAF50))
                                Text("Les mots de passe correspondent")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: 0x4CAF50))
                            }
                            .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Password Requirements
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Le mot de passe doit contenir :")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: 0x6B7280))
                        
                        PasswordRequirementRow(
                            isValid: viewModel.isPasswordLengthValid,
                            text: "Au moins 8 caractères"
                        )
                        
                        PasswordRequirementRow(
                            isValid: viewModel.hasUppercase,
                            text: "Une lettre majuscule"
                        )
                        
                        PasswordRequirementRow(
                            isValid: viewModel.hasLowercase,
                            text: "Une lettre minuscule"
                        )
                        
                        PasswordRequirementRow(
                            isValid: viewModel.hasNumber,
                            text: "Un chiffre"
                        )
                        
                        PasswordRequirementRow(
                            isValid: viewModel.hasSpecialCharacter,
                            text: "Un caractère spécial (!@#$%^&*...)"
                        )
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    
                    // Reset Password Button
                    Button(action: {
                        viewModel.resetPassword(email: email, resetToken: resetToken)
                    }) {
                        HStack(spacing: 12) {
                            if case .loading = viewModel.uiState {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: 0x5F370E)))
                                    .scaleEffect(0.8)
                                Text("Réinitialisation...")
                                    .foregroundColor(Color(hex: 0x5F370E))
                            } else {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .foregroundColor(Color(hex: 0x5F370E))
                                Text("Réinitialiser le mot de passe")
                                    .foregroundColor(Color(hex: 0x5F370E))
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            viewModel.canSubmit
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
                        .shadow(color: viewModel.canSubmit ? Color(hex: 0xF59E0B).opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!viewModel.canSubmit)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.uiState == .loading)
        .alert("Message", isPresented: $showAlert) {
            if case .success = viewModel.uiState {
                Button("Aller à la connexion") {
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                Button("OK", role: .cancel) {
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
    
    private func handleStateChange(_ state: ResetPasswordUiState) {
        switch state {
        case .idle:
            break
            
        case .loading:
            break
            
        case .success(let message):
            alertMessage = "✅ \(message)\n\nVous pouvez maintenant vous connecter avec votre nouveau mot de passe"
            showAlert = true
            
        case .error(let message):
            alertMessage = message
            showAlert = true
        }
    }
}

// MARK: - Password Requirement Row
struct PasswordRequirementRow: View {
    let isValid: Bool
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? Color(hex: 0x4CAF50) : Color(hex: 0x9E9E9E))
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? Color(hex: 0x4CAF50) : Color(hex: 0x6B7280))
        }
        .animation(.easeInOut, value: isValid)
    }
}

#Preview {
    NavigationStack {
        ResetPasswordView(email: "test@example.com", resetToken: "sample-token")
    }
}
