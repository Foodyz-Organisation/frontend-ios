//
//  ForgotPasswordViewModel.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import Foundation
import SwiftUI
import Combine

enum ForgotPasswordUiState: Equatable {
    case idle
    case loading
    case otpSent(email: String)
    case error(String)
}

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    @Published var uiState: ForgotPasswordUiState = .idle
    @Published var email = ""
    
    private let apiService: AuthAPIService
    
    init(apiService: AuthAPIService = .shared) {
        self.apiService = apiService
    }
    
    // MARK: - Email Validation
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespaces))
    }
    
    var canSendOtp: Bool {
        !email.isEmpty && isEmailValid && uiState != .loading
    }
    
    // MARK: - Send OTP
    func sendOtp() {
        guard !email.isEmpty else {
            uiState = .error("L'email ne peut pas être vide")
            return
        }
        
        guard isEmailValid else {
            uiState = .error("Veuillez entrer un email valide")
            return
        }
        
        Task {
            uiState = .loading
            
            do {
                let normalizedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
                let response = try await apiService.sendOtp(email: normalizedEmail)
                
                if response.success {
                    uiState = .otpSent(email: normalizedEmail)
                } else {
                    uiState = .error("Échec de l'envoi du code OTP")
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
    
    // MARK: - Clear Email
    func clearEmail() {
        email = ""
    }
}
