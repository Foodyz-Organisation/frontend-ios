import Foundation

/// Intensity types for ingredients that support intensity customization
enum IntensityType: String, Codable, CaseIterable, Equatable {
    case coffee = "COFFEE"
    case harissa = "HARISSA"
    case sauce = "SAUCE"
    case spice = "SPICE"
    case sugar = "SUGAR"
    case salt = "SALT"
    case pepper = "PEPPER"
    case chili = "CHILI"
    case garlic = "GARLIC"
    case lemon = "LEMON"
    case custom = "CUSTOM"
}

