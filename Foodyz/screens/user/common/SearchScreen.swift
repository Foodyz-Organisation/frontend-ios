import SwiftUI

// MARK: - Search Screen
struct SearchScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SearchViewModel()
    
    let onProfessionalSelected: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(hex: 0x64748B))
                    
                    TextField("Search by name...", text: $viewModel.searchText)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: 0x1F2937))
                        .autocorrectionDisabled()
                }
                .padding(14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0xFDE68A), lineWidth: 2)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Content
                ZStack {
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Color(hex: 0x1D4ED8))
                            Text("Searching...")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: 0x64748B))
                                .padding(.top, 8)
                            Spacer()
                        }
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: 0xEF4444))
                            Text(errorMessage)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: 0x64748B))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.top, 16)
                            Spacer()
                        }
                        .padding()
                    } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: 0xD1D5DB))
                            Text("No professionals found")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: 0x64748B))
                                .padding(.top, 16)
                            Spacer()
                        }
                    } else if viewModel.searchResults.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: 0xD1D5DB))
                            Text("Search for professionals")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: 0x64748B))
                                .padding(.top, 16)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.searchResults) { professional in
                                    ProfessionalListItem(professional: professional) {
                                        onProfessionalSelected(professional.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .background(Color(hex: 0xF7F7F7))
            .navigationTitle("Search Professionals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(Color(hex: 0x1F2937))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { /* Filter action */ }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(Color(hex: 0x1F2937))
                    }
                }
            }
        }
    }
}

// MARK: - Professional List Item
struct ProfessionalListItem: View {
    let professional: ProfessionalDto
    let onItemClick: () -> Void
    
    var body: some View {
        Button(action: onItemClick) {
            HStack(spacing: 16) {
                // Professional Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: 0xFFE5E7EB))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                }
                
                // Professional Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(professional.fullName ?? "Unnamed Professional")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                        .lineLimit(1)
                    
                    Text(professional.email)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: 0xFF64748B))
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct SearchScreen_Previews: PreviewProvider {
    static var previews: some View {
        SearchScreen { professionalId in
            print("Selected: \(professionalId)")
        }
    }
}
