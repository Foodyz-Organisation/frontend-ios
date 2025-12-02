//
// FoodyzApp.swift
// Foodyz
//
// Created by Mouscou Mohamed khalil on 4/11/2025.
//

import SwiftUI

@main
@MainActor
struct FoodyzApp: App {
    var body: some Scene {
        WindowGroup {
            AppNavigation()
                .environmentObject(SessionManager.shared)
        }
    }
}
