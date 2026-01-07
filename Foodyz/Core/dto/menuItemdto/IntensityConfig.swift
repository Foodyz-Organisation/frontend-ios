import Foundation
import SwiftUI

/// Configuration for intensity types (icon, color, label)
struct IntensityConfig {
    let icon: String // Icon name/identifier for frontend
    let defaultColor: Color // Hex color code converted to SwiftUI Color
    let label: String // Display name
}

/// Maps intensity types to their default configuration (icon, color, label)
/// Frontend can use this to display appropriate icons and colors
let INTENSITY_CONFIG_MAP: [IntensityType: IntensityConfig] = [
    .coffee: IntensityConfig(
        icon: "coffee",
        defaultColor: Color(hex: 0x3E2723), // Dark brown/black
        label: "Coffee"
    ),
    .harissa: IntensityConfig(
        icon: "piment",
        defaultColor: Color(hex: 0xD32F2F), // Red
        label: "Harissa"
    ),
    .sauce: IntensityConfig(
        icon: "sauce",
        defaultColor: Color(hex: 0xFF6F00), // Orange
        label: "Sauce"
    ),
    .spice: IntensityConfig(
        icon: "spice",
        defaultColor: Color(hex: 0xE65100), // Deep orange
        label: "Spice"
    ),
    .sugar: IntensityConfig(
        icon: "sugar",
        defaultColor: Color(hex: 0xFFF9C4), // Light yellow
        label: "Sugar"
    ),
    .salt: IntensityConfig(
        icon: "salt",
        defaultColor: Color(hex: 0xE0E0E0), // Light gray
        label: "Salt"
    ),
    .pepper: IntensityConfig(
        icon: "pepper",
        defaultColor: Color(hex: 0x212121), // Black
        label: "Pepper"
    ),
    .chili: IntensityConfig(
        icon: "chili",
        defaultColor: Color(hex: 0xC62828), // Dark red
        label: "Chili"
    ),
    .garlic: IntensityConfig(
        icon: "garlic",
        defaultColor: Color(hex: 0xFFF9C4), // Light yellow/white
        label: "Garlic"
    ),
    .lemon: IntensityConfig(
        icon: "lemon",
        defaultColor: Color(hex: 0xFDD835), // Yellow
        label: "Lemon"
    ),
    .custom: IntensityConfig(
        icon: "custom",
        defaultColor: Color(hex: 0x9E9E9E), // Gray
        label: "Custom"
    )
]

/// Get intensity configuration for a given type
func getIntensityConfig(type: IntensityType) -> IntensityConfig {
    return INTENSITY_CONFIG_MAP[type] ?? INTENSITY_CONFIG_MAP[.custom]!
}

/// Get default color for an intensity type
func getDefaultIntensityColor(type: IntensityType) -> Color {
    return getIntensityConfig(type: type).defaultColor
}

