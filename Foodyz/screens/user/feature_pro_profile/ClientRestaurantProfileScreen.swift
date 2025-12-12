import SwiftUI

// MARK: - Dynamic Client Restaurant Profile Screen
struct ClientRestaurantProfileScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ProfessionalProfileViewModel()
    
    let professionalId: String
    let onViewMenuClick: (String) -> Void
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 16)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Retry") {
                        viewModel.loadProfessional(id: professionalId)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.primaryYellow)
                    .cornerRadius(8)
                }
            } else if let professional = viewModel.professional {
                ProfileContentView(
                    professional: professional,
                    professionalId: professionalId,
                    onViewMenuClick: onViewMenuClick,
                    onBackClick: { dismiss() }
                )
            }
        }
        .background(Color.backgroundLight)
        .onAppear {
            viewModel.loadProfessional(id: professionalId)
        }
    }
}

// MARK: - Profile Content View
struct ProfileContentView: View {
    let professional: ProfessionalDto
    let professionalId: String
    let onViewMenuClick: (String) -> Void
    let onBackClick: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Scrollable Content
            ScrollView {
                VStack(spacing: 24) {
                    HeaderSectionView(professional: professional)
                    InfoSectionView(professional: professional)
                    
                    ManagementCardView(title: "Core Business Details") {
                        if let fullName = professional.fullName {
                            ReadOnlyInfoRow(iconName: "person.fill", label: "Name", value: fullName)
                        }
                        if let role = professional.role {
                            ReadOnlyInfoRow(iconName: "briefcase.fill", label: "Role", value: role)
                        }
                        if let licenseNumber = professional.licenseNumber {
                            ReadOnlyInfoRow(iconName: "doc.text.fill", label: "License", value: licenseNumber)
                        }
                        ReadOnlyInfoRow(iconName: "checkmark.circle.fill", label: "Status", value: professional.isActive ? "Active" : "Inactive")
                    }
                    
                    ManagementCardView(title: "Contact Information") {
                        ReadOnlyInfoRow(iconName: "envelope.fill", label: "Email", value: professional.email)
                    }
                    
                    if !professional.documents.isEmpty {
                        ManagementCardView(title: "Documents") {
                            ForEach(professional.documents, id: \.self) { doc in
                                DocumentRow(documentPath: doc)
                            }
                        }
                    }
                    
                    ManagementCardView(title: "Service Times") {
                        ReadOnlyInfoRow(iconName: "car.fill", label: "Delivery", value: "30-45 min")
                        ReadOnlyInfoRow(iconName: "bag.fill", label: "Takeaway", value: "Ready in 15 min")
                    }
                    
                    Spacer(minLength: 80)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // Bottom Bar
            BottomBarView(professionalId: professionalId, onViewMenuClick: onViewMenuClick)
        }
        .navigationTitle(professional.fullName ?? "Professional")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBackClick) {
                    Image(systemName: "arrow.backward")
                        .foregroundColor(.darkText)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { print("Share clicked") }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.darkText)
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.white, for: .navigationBar)
    }
}

// MARK: - Header Section
struct HeaderSectionView: View {
    let professional: ProfessionalDto
    
    var body: some View {
        VStack(spacing: 12) {
            // Professional Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: 0xFFE5E7EB))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
            }
            
            Text(professional.fullName ?? "Professional")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.darkText)
        }
        .padding(.top, 8)
    }
}

// MARK: - Info Section
struct InfoSectionView: View {
    let professional: ProfessionalDto
    
    var body: some View {
        HStack(spacing: 16) {
            // Active Status
            HStack(spacing: 4) {
                Image(systemName: professional.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(professional.isActive ? Color(hex: 0xFF10B981) : Color(hex: 0xFFEF4444))
                Text(professional.isActive ? "Active" : "Inactive")
                    .fontWeight(.bold)
                    .foregroundColor(.darkText)
            }
            
            // Role badge
            if let role = professional.role {
                HStack(spacing: 4) {
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(.primaryYellow)
                    Text(role)
                        .foregroundColor(.inactiveGray)
                        .font(.system(size: 14))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Document Row
struct DocumentRow: View {
    let documentPath: String
    
    // Extract filename from path
    private var filename: String {
        (documentPath as NSString).lastPathComponent
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .foregroundColor(Color(hex: 0xFF3B82F6))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(filename)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.darkText)
                
                Text(documentPath)
                    .font(.system(size: 12))
                    .foregroundColor(.inactiveGray)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
}

// MARK: - Reusable Card Container
struct ManagementCardView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.darkText)
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Read-Only Row
struct ReadOnlyInfoRow: View {
    let iconName: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(.primaryYellow)
                .frame(width: 20)
            
            Text(label)
                .foregroundColor(.darkText)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.darkText)
        }
    }
}

// MARK: - Bottom Bar
struct BottomBarView: View {
    let professionalId: String
    let onViewMenuClick: (String) -> Void
    
    var body: some View {
        VStack {
            Button {
                onViewMenuClick(professionalId)
            } label: {
                Text("View Menu & Order")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.darkTextForYellow)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.primaryYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
    }
}

// MARK: - Color Helpers for Profile Screen
private extension Color {
    static let primaryYellow = Color(hex: 0xFFFFC107)
    static let backgroundLight = Color(hex: 0xFFF9FAFB)
    static let darkTextForYellow = Color(hex: 0xFF1F2A37)
    static let darkText = Color(hex: 0xFF1F2937)
    static let inactiveGray = Color(hex: 0xFF64748B)
}

// MARK: - Preview
struct ClientRestaurantProfileScreen_Previews: PreviewProvider {
    static var previews: some View {
        ClientRestaurantProfileScreen(
            professionalId: "mock_id_123",
            onViewMenuClick: { id in
                print("Navigate to menu: \(id)")
            }
        )
    }
}
