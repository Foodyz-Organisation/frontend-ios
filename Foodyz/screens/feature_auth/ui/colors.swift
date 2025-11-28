import SwiftUI

// MARK: - App Color Palette (Guaranteed Hex Values)

extension Color {
    
    // 💡 FIX: Change the helper from a private initializer to a private static function
    private static func hex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        // Existing logic for parsing Hex string...
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        return Color(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    
    // =========================================================
    // PRIMARY DESIGN COLORS (Matching Screenshot)
    // =========================================================
    
    // MAIN BRAND COLORS (Bright Yellow/Gold)
    // USAGE: Now call the new static function: Color.hex("FFC107")
    static let primaryColor = Color.hex("FFC107")
    static let secondaryColor = Color.hex("FF9800")
    
    // BACKGROUND COLORS
    static let backgroundColor = Color.hex("FFFFF0")
    static let cardBackground = Color.hex("F7F7F7")
    
    // TEXT COLORS
    static let textPrimary = Color.hex("333333")
    static let textSecondary = Color.hex("666666")
    static let textLight = Color.white // This is fine as is

    // STATUS COLORS
    static let success = Color.hex("4CAF50")
    static let warning = Color.hex("FFEB3B")
    static let error = Color.hex("F44336")

    // GRAYS
    static let gray100 = Color.hex("F7F7F7")
    static let gray300 = Color.hex("CCCCCC")
    static let gray500 = Color.hex("999999")
    static let gray700 = Color.hex("666666")
    static let gray900 = Color.hex("333333")
}
