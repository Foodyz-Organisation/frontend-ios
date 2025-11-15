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
                        
                        Image(systemName: "key.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.blue)
                    }
                    
                    // Title
                    Text("Nouveau mot de passe")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Créez un mot de passe sécurisé pour votre compte")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // New Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
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
                            
                            Button(action: {
                                showNewPassword.toggle()
                            }) {
                                Image(systemName: showNewPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.isPasswordValid && !viewModel.newPassword.isEmpty ? Color.green : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        
                        // Password strength indicator
                        if !viewModel.newPassword.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Force du mot de passe:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
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
                                .foregroundColor(.gray)
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
                            
                            Button(action: {
                                showConfirmPassword.toggle()
                            }) {
                                Image(systemName: showConfirmPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    viewModel.passwordsMatch ? Color.green : (!viewModel.confirmPassword.isEmpty ? Color.red : Color.clear),
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
                        } else if viewModel.passwordsMatch {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Les mots de passe correspondent")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Password Requirements
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Le mot de passe doit contenir :")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
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
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    
                    // Reset Password Button
                    Button(action: {
                        viewModel.resetPassword(email: email, resetToken: resetToken)
                    }) {
                        HStack {
                            if case .loading = viewModel.uiState {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Réinitialisation...")
                            } else {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text("Réinitialiser le mot de passe")
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            viewModel.canSubmit
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
                        .shadow(color: viewModel.canSubmit ? Color.blue.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
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
                    // Retour à la racine de navigation
                    presentationMode.wrappedValue.dismiss()
                    // Vous devrez peut-être adapter selon votre système de navigation
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
                .foregroundColor(isValid ? .green : .gray)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .green : .secondary)
        }
        .animation(.easeInOut, value: isValid)
    }
}

#Preview {
    NavigationStack {
        ResetPasswordView(email: "test@example.com", resetToken: "sample-token")
    }
}
