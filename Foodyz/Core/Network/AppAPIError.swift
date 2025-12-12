//
//  AppAPIError.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import Foundation

enum AppAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String)
    case unauthorized
    case notFound
    case badRequest(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "L'adresse du serveur est invalide. Vérifiez la configuration."
            
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
            
        case .invalidResponse:
            return "Réponse invalide du serveur."
            
        case .decodingError(let error):
            return "Erreur de décodage: \(error.localizedDescription)"
            
        case .serverError(let message):
            return "Erreur serveur: \(message)"
            
        case .unauthorized:
            return "Non autorisé. Veuillez vous reconnecter."
            
        case .notFound:
            return "Ressource introuvable."
            
        case .badRequest(let message):
            return "Requête invalide: \(message)"
            
        case .unknownError:
            return "Une erreur inconnue s'est produite."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Vérifiez votre connexion internet et réessayez."
        case .unauthorized:
            return "Reconnectez-vous pour continuer."
        case .serverError:
            return "Le serveur rencontre un problème. Réessayez plus tard."
        default:
            return "Veuillez réessayer."
        }
    }
}
