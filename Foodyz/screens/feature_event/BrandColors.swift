//
//  BrandColors.swift
//  Foodyz
//
//  Created by Apple on 9/11/2025.
//

import SwiftUI

struct BrandColors {
    // Anciennes propriétés (gardez-les pour la compatibilité)
    static let Yellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let YellowPressed = Color(red: 0.9, green: 0.7, blue: 0.0)
    static let TextPrimary = Color.black
    static let TextSecondary = Color.gray
    static let FieldFill = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let Cream100 = Color(red: 1.0, green: 0.98, blue: 0.94)
    static let Cream200 = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let Orange = Color.orange
    static let Green = Color.green
    static let Red = Color.red
    static let Dashed = Color.gray.opacity(0.5)
    
    // Nouvelles propriétés (convention lowercase - recommandé par Swift)
    static let yellow = Yellow
    static let yellowPressed = YellowPressed
    static let textPrimary = TextPrimary
    static let textSecondary = TextSecondary
    static let fieldFill = FieldFill
    static let cream100 = Cream100
    static let cream200 = Cream200
    static let orange = Orange
    static let green = Green
    static let red = Red
    static let dashed = Dashed
}
