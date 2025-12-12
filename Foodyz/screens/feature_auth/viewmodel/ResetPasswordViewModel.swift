//
//  ResetPasswordViewModel.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import Foundation
import SwiftUI
import Combine

enum ResetPasswordUiState: Equatable {
    case idle
    case loading
    case success(String)
    case error(String)
}

@MainActor
class ResetPasswordViewModel: ObservableObject {
    @Published var uiState: ResetPasswordUiState = .idle
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    
    private let apiService: AuthAPIService
    
    init(apiService: AuthAPIService = .shared) {
        self.apiService = apiService
    }
    
    // MARK: - Password Validation
    var isPasswordLengthValid: Bool {
        newPassword.count >= 8
    }
    
    var hasUppercase: Bool {
        newPassword.contains(where: { $0.isUppercase })
    }
    
    var hasLowercase: Bool {
        newPassword.contains(where: { $0.isLowercase })
    }
    
    var hasNumber: Bool {
        newPassword.contains(where: { $0.isNumber })
    }
    
    var hasSpecialCharacter: Bool {
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        return newPassword.unicodeScalars.contains(where: { specialCharacters.contains($0) })
    }
    
    var passwordsMatch: Bool {
        !confirmPassword.isEmpty && newPassword == confirmPassword
    }
    
    var isPasswordValid: Bool {
        isPasswordLengthValid
    }
    
    var canSubmit: Bool {
        isPasswordValid && passwordsMatch && uiState != .loading
    }
    
    var passwordStrength: (text: String, color: Color, progress: Double) {
        var strength = 0
        
        if isPasswordLengthValid { strength += 1 }
        if hasUppercase { strength += 1 }
        if hasLowercase { strength += 1 }
        if hasNumber { strength += 1 }
        if hasSpecialCharacter { strength += 1 }
        
        switch strength {
        case 0...1:
            return ("Faible", .red, 0.2)
        case 2:
            return ("Moyen", .orange, 0.4)
        case 3:
            return ("Bon", .yellow, 0.6)
        case 4:
            return ("Fort", .green, 0.8)
        case 5:
            return ("Très fort", .blue, 1.0)
        default:
            return ("", .gray, 0.0)
        }
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String, resetToken: String) {
        guard isPasswordValid else {
            uiState = .error("Le mot de passe doit contenir au moins 8 caractères")
            return
        }
        
        guard passwordsMatch else {
            uiState = .error("Les mots de passe ne correspondent pas")
            return
        }
        
        Task {
            uiState = .loading
            
            do {
                let response = try await apiService.resetPasswordWithOtp(
                    email: email,
                    resetToken: resetToken,
                    newPassword: newPassword
                )
                
                if response.success {
                    uiState = .success(response.message)
                } else {
                    uiState = .error("Échec de la réinitialisation du mot de passe")
                }
            } catch let error as AppAPIError {
                uiState = .error(error.localizedDescription)
            } catch {
                uiState = .error("Erreur réseau: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Reset State
    func resetState() {
        uiState = .idle
    }
    
    // MARK: - Clear Passwords
    func clearPasswords() {
        newPassword = ""
        confirmPassword = ""
    }
}
