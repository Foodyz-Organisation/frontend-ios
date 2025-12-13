import SwiftUI

struct AppColors {
    static let background = Color(red: 0.99, green: 0.97, blue: 0.94) // Creamy white - warm, soft cream tone
    static let lightGray = Color(red: 0.94, green: 0.94, blue: 0.94)
    static let darkGray = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let primary = Color(red: 1.0, green: 0.42, blue: 0.0)
    static let white = Color.white
}

struct ChatColors {
    static let bubbleIncoming = Color.white
    static let bubbleOutgoing = Color(red: 1.0, green: 0.7, blue: 0.4)
    static let bubbleShadow = Color.black.opacity(0.08)
    static let inputBackground = Color.white
}
