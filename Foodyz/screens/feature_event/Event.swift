//
//  Event.swift
//  Foodyz
//
//  Created by Apple on 9/11/2025.
//

import Foundation
import SwiftUI

enum EventStatus: String, Codable, CaseIterable {
    case aVenir = "à venir"
    case enCours = "en cours"
    case termine = "terminé"
    
    var color: Color {
        switch self {
        case .aVenir: return Color.orange
        case .enCours: return Color.green
        case .termine: return Color.red
        }
    }
}

struct Event: Identifiable, Codable, Equatable {
    let id: String
    let nom: String
    let description: String
    let dateDebut: String
    let dateFin: String
    let image: String?
    let lieu: String
    let categorie: String
    let statut: EventStatus
    
    // ⚠️ CRITICAL: Map Swift camelCase to backend snake_case
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nom
        case description
        case dateDebut = "date_debut"  // Maps to backend's date_debut
        case dateFin = "date_fin"      // Maps to backend's date_fin
        case image
        case lieu
        case categorie
        case statut
    }
    
    init(
        id: String = UUID().uuidString,
        nom: String,
        description: String,
        dateDebut: String,
        dateFin: String,
        image: String? = nil,
        lieu: String,
        categorie: String,
        statut: EventStatus
    ) {
        self.id = id
        self.nom = nom
        self.description = description
        self.dateDebut = dateDebut
        self.dateFin = dateFin
        self.image = image
        self.lieu = lieu
        self.categorie = categorie
        self.statut = statut
    }
}

// Sample data
extension Event {
    static let sampleEvents = [
        Event(
            nom: "Festival de Street Food Ramadan",
            description: "Un festival incroyable avec les meilleurs restaurants de la région",
            dateDebut: "2025-11-07T10:00:00Z",
            dateFin: "2025-11-07T18:00:00Z",
            lieu: "Parc Central de Tunis",
            categorie: "cuisine tunisienne",
            statut: .aVenir
        ),
        Event(
            nom: "Conférence Gastronomie 2025",
            description: "Une conférence sur les dernières tendances culinaires",
            dateDebut: "2025-11-15T09:00:00Z",
            dateFin: "2025-11-16T17:00:00Z",
            lieu: "Centre de Convention",
            categorie: "cuisine française",
            statut: .enCours
        )
    ]
}

// MARK: - Debug Helper
extension Event {
    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
}
