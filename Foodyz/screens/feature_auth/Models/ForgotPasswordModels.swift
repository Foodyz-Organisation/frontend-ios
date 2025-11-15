//
//  ForgotPasswordModels.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import Foundation

// MARK: - Request Models

struct SendOtpRequest: Codable {
    let email: String
}

struct VerifyOtpRequest: Codable {
    let email: String
    let otp: String
}

struct ResetPasswordWithOtpRequest: Codable {
    let email: String
    let resetToken: String
    let newPassword: String
}

// MARK: - Response Models

struct OtpResponse: Codable {
    let success: Bool
    let message: String
}

struct VerifyOtpResponse: Codable {
    let success: Bool
    let message: String
    let resetToken: String?
}

struct ResetPasswordResponse: Codable {
    let success: Bool
    let message: String
}
