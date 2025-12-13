//
//  AppAPIConstants.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import Foundation

struct AppAPIConstants {
    // ============================================
    // 🔧 CHOISISSEZ LA BONNE CONFIGURATION
    // ============================================
    
    // ✅ POUR iOS SIMULATOR (Xcode Simulator)
    static let baseURL = "http://localhost:3000"
    
    // ✅ POUR IPHONE PHYSIQUE (même WiFi que votre Mac)
    // Trouvez l'IP de votre Mac avec: ifconfig | grep "inet "
    // static let baseURL = "http://192.168.1.10:3000"  // ⚠️ Décommentez et remplacez par VOTRE IP pour iPhone physique
    
    // ❌ NE PAS UTILISER (Android uniquement)
    // static let baseURL = "http://10.0.2.2:3000"
    
    // ============================================
    
    // Auth endpoints
    struct Auth {
        static let base = "\(baseURL)/auth"
        static let login = "\(base)/login"
        static let userSignup = "\(base)/user/signup"
        static let professionalSignup = "\(base)/professional/signup"
        static let forgotPassword = "\(base)/forgot-password"
        static let verifyOtp = "\(base)/verify-otp"
        static let resetPassword = "\(base)/reset-password"
        static let logout = "\(base)/logout"
    }
    
    // Event endpoints
    struct Events {
        static let base = "\(baseURL)/events"
        static let list = "\(base)"
        static let create = "\(base)"
        static func update(id: String) -> String { "\(base)/\(id)" }
        static func delete(id: String) -> String { "\(base)/\(id)" }
    }
    
    // Reclamation endpoints
    struct Reclamations {
        static let base = "\(baseURL)/reclamations"
        static let list = "\(base)"
        static let create = "\(base)"
        static func update(id: String) -> String { "\(base)/\(id)" }
        static func delete(id: String) -> String { "\(base)/\(id)" }
    }
    
    // Helper pour debug
    static func printConfiguration() {
        print("🌐 ============================================")
        print("🌐 Configuration API")
        print("🌐 ============================================")
        print("🌐 Base URL: \(baseURL)")
        print("🌐 Login: \(Auth.login)")
        print("🌐 Forgot Password: \(Auth.forgotPassword)")
        print("🌐 ============================================")
        print("💡 Si vous avez un timeout:")
        print("   1. Vérifiez que le backend tourne: node server.js")
        print("   2. Testez dans le navigateur: \(baseURL)")
        print("   3. Pour iPhone physique, utilisez l'IP de votre Mac")
        print("🌐 ============================================")
    }
}
