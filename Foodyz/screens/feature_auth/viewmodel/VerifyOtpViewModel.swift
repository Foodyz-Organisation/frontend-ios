//
//  VerifyOtpViewModel.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import Foundation
import SwiftUI
import Combine

enum VerifyOtpUiState: Equatable {
    case idle
    case loading
    case verified(email: String, resetToken: String)
    case error(String)
}

@MainActor
class VerifyOtpViewModel: ObservableObject {
    @Published var uiState: VerifyOtpUiState = .idle
    @Published var otp = ""
    
    private let apiService: AuthAPIService
    
    init(apiService: AuthAPIService = .shared) {
        self.apiService = apiService
    }
    
    // MARK: - OTP Validation
    var isOtpValid: Bool {
        otp.count == 6 && otp.allSatisfy { $0.isNumber }
    }
    
    var canVerify: Bool {
        isOtpValid && uiState != .loading
    }
    
    // MARK: - Format OTP Input
    func formatOtpInput(_ newValue: String) -> String {
        // Only allow numbers
        let filtered = newValue.filter { $0.isNumber }
        // Limit to 6 digits
        return String(filtered.prefix(6))
    }
    
    // MARK: - Verify OTP
    func verifyOtp(email: String) {
        guard otp.count == 6 else {
            uiState = .error("Le code OTP doit contenir 6 chiffres")
            return
        }
        
        guard otp.allSatisfy({ $0.isNumber }) else {
            uiState = .error("Le code OTP ne doit contenir que des chiffres")
            return
        }
        
        Task {
            uiState = .loading
            
            do {
                let response = try await apiService.verifyOtp(email: email, otp: otp)
                
                if response.success, let resetToken = response.resetToken, !resetToken.isEmpty {
                    print("✅ OTP vérifié! Email: \(email), Token: \(resetToken.prefix(20))...")
                    uiState = .verified(email: email, resetToken: resetToken)
                } else {
                    uiState = .error("Code OTP invalide")
                }
            } catch let error as AppAPIError {
                print("❌ Erreur: \(error.localizedDescription)")
                uiState = .error(error.localizedDescription)
            } catch {
                print("❌ Erreur réseau: \(error.localizedDescription)")
                uiState = .error("Erreur réseau: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Reset State
    func resetState() {
        uiState = .idle
    }
    
    // MARK: - Clear OTP
    func clearOtp() {
        otp = ""
    }
}
