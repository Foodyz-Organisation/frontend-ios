//
//  AuthAPIService.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import Foundation

class AuthAPIService {
    static let shared = AuthAPIService()
    
    private init() {}
    
    // MARK: - Generic POST Request
    private func post<T: Codable, U: Codable>(
        url: String,
        body: T,
        responseType: U.Type
    ) async throws -> U {
        guard let requestURL = URL(string: url) else {
            throw AppAPIError.invalidURL
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw AppAPIError.decodingError(error)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppAPIError.invalidResponse
            }
            
            print("📡 Response Status Code: \(httpResponse.statusCode)")
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decodedResponse = try JSONDecoder().decode(U.self, from: data)
                    return decodedResponse
                } catch {
                    print("❌ Decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📄 Response data: \(jsonString)")
                    }
                    throw AppAPIError.decodingError(error)
                }
                
            case 400:
                let message = String(data: data, encoding: .utf8) ?? "Bad Request"
                throw AppAPIError.badRequest(message)
                
            case 401:
                throw AppAPIError.unauthorized
                
            case 404:
                throw AppAPIError.notFound
                
            case 500...599:
                let message = String(data: data, encoding: .utf8) ?? "Server Error"
                throw AppAPIError.serverError(message)
                
            default:
                throw AppAPIError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
        } catch let error as AppAPIError {
            throw error
        } catch {
            throw AppAPIError.networkError(error)
        }
    }
    
    // MARK: - Send OTP
    func sendOtp(email: String) async throws -> OtpResponse {
        print("📤 Sending OTP to: \(email)")
        
        let request = SendOtpRequest(email: email)
        let response = try await post(
            url: AppAPIConstants.Auth.forgotPassword,
            body: request,
            responseType: OtpResponse.self
        )
        
        print("✅ OTP Response: \(response.message)")
        return response
    }
    
    // MARK: - Verify OTP
    func verifyOtp(email: String, otp: String) async throws -> VerifyOtpResponse {
        print("📤 Verifying OTP for: \(email) with code: \(otp)")
        
        let request = VerifyOtpRequest(email: email, otp: otp)
        let response = try await post(
            url: AppAPIConstants.Auth.verifyOtp,
            body: request,
            responseType: VerifyOtpResponse.self
        )
        
        print("✅ Verify Response: \(response.message)")
        if let token = response.resetToken {
            print("🔑 Reset Token: \(token.prefix(20))...")
        }
        return response
    }
    
    // MARK: - Reset Password
    func resetPasswordWithOtp(
        email: String,
        resetToken: String,
        newPassword: String
    ) async throws -> ResetPasswordResponse {
        print("📤 Resetting password for: \(email)")
        
        let request = ResetPasswordWithOtpRequest(
            email: email,
            resetToken: resetToken,
            newPassword: newPassword
        )
        let response = try await post(
            url: AppAPIConstants.Auth.resetPassword,
            body: request,
            responseType: ResetPasswordResponse.self
        )
        
        print("✅ Reset Password Response: \(response.message)")
        return response
    }
    
    // MARK: - Logout
    func logout() async throws {
        guard let url = URL(string: AppAPIConstants.Auth.logout) else {
            throw AppAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppAPIError.serverError("Logout failed")
        }
    }
}
