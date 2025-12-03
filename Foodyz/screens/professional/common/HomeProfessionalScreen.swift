//
//  HomeProfessionalView.swift
//  Foodyz
//
//  Created by Apple on 15/11/2025.
//

import SwiftUI

struct HomeProfessionalView: View {
    var onNavigateToDealsList: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // MARK: - Top Metrics Cards
                HStack(spacing: 16) {
                    MetricCard(
                        title: "Total Orders",
                        value: "127",
                        change: "+12% from last week",
                        icon: "bag.fill",
                        backgroundColor: Color(hex: "FFFBEA"),
                        valueColor: Color(hex: "333333")
                    )
                    
                    MetricCard(
                        title: "Revenue",
                        value: "$3,847",
                        change: "+8% from last week",
                        icon: "chart.line.uptrend.xyaxis",
                        backgroundColor: Color(hex: "E8FFE8"),
                        valueColor: Color(hex: "333333")
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer().frame(height: 32)
                
                // MARK: - Quick Actions Header
                Text("Quick Actions")
                    .font(.system(size: 24, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // MARK: - Navigation Cards
                VStack(spacing: 12) {
                    // Manage Orders Card
                    ProActionCard(
                        icon: "bag.fill",
                        title: "Manage Orders",
                        subtitle: "View and process customer orders",
                        badge: "3",
                        iconBackground: Color(hex: "E8EAF6"),
                        iconColor: Color(hex: "3F51B5"),
                        isEnabled: true
                    ) {
                        print("Navigate to menu_management")
                    }
                    
                    // Menu Management Card
                    ProActionCard(
                        icon: "book.fill",
                        title: "Menu Management",
                        subtitle: "Edit your menu and items",
                        indicator: true,
                        iconBackground: Color(hex: "F3E5F5"),
                        iconColor: Color(hex: "9C27B0"),
                        isEnabled: true
                    ) {
                        print("Navigate to add_meal")
                    }
                    
                    // 🎯 DEALS MANAGEMENT CARD
                    ProActionCard(
                        icon: "tag.fill",
                        title: "Deals Management",
                        subtitle: "Manage your offers and promotions",
                        indicator: true,
                        iconBackground: Color(hex: "FFF3E0"),
                        iconColor: Color(hex: "FF9800"),
                        isEnabled: true
                    ) {
                        onNavigateToDealsList()
                    }
                    
                    // Réclamations Card
                    ProActionCard(
                        icon: "exclamationmark.bubble.fill",
                        title: "Réclamations",
                        subtitle: "Voir les réclamations reçues",
                        indicator: true,
                        iconBackground: Color(hex: "E1F5FE"),
                        iconColor: Color(hex: "0288D1"),
                        isEnabled: true
                    ) {
                        print("Navigate to restaurant_reclamations")
                    }
                    
                    // Analytics Card
                    ProActionCard(
                        icon: "chart.bar.fill",
                        title: "Analytics",
                        subtitle: "Coming soon...",
                        iconBackground: Color(hex: "E0F7FA"),
                        iconColor: Color(hex: "00BCD4"),
                        isEnabled: false
                    ) {
                        // Not yet implemented
                    }
                    
                    // Settings Card
                    ProActionCard(
                        icon: "gearshape.fill",
                        title: "Settings",
                        subtitle: "Coming soon...",
                        iconBackground: Color(hex: "FBE9E7"),
                        iconColor: Color(hex: "FF5722"),
                        isEnabled: false
                    ) {
                        // Not yet implemented
                    }
                }
                
                Spacer().frame(height: 32)
                
                // MARK: - Recent Activity Section
                Text("Recent Activity")
                    .font(.system(size: 24, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                Text("No recent activity.")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                
                Spacer().frame(height: 32)
            }
        }
        .background(Color(hex: "F5F5F5"))
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    let change: String
    let icon: String
    let backgroundColor: Color
    let valueColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Spacer()
            }
            .padding(.bottom, 8)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(valueColor)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 4)
            
            Text(change)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Action Card Component
struct ProActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var badge: String? = nil
    var indicator: Bool = false
    let iconBackground: Color
    let iconColor: Color
    let isEnabled: Bool
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 16) {
                // Icon Container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconBackground)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isEnabled ? Color.black : Color.gray)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray)
                }
                
                Spacer()
                
                // Badge or Indicator
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(12)
                } else if indicator && isEnabled {
                    Image(systemName: "arrow.forward")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isEnabled ? Color.white : Color(hex: "F5F5F5"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 16)
    }
}

// MARK: - Color Extension for Hex
// Note: Color extension removed - already exists elsewhere in the project

// MARK: - Preview
#Preview {
    NavigationStack {
        HomeProfessionalView {
            print("Navigate to deals")
        }
    }
}
