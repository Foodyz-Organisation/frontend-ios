import SwiftUI

// MARK: - Search Screen
struct SearchScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var isSearchFocused: Bool
    
    let onProfessionalSelected: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("Search Professionals")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        // Filter action placeholder
                    }) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                // MARK: - Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.0)) // Yellow/Gold
                    
                    TextField("Search by name...", text: $viewModel.searchText)
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3)) // Dark text
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 1.0, green: 0.85, blue: 0.0), lineWidth: 1.5) // Yellow border
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(Color.white)
                
                // MARK: - Content
                ZStack {
                    Color(red: 0.98, green: 0.98, blue: 0.99).ignoresSafeArea() // Light bg
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(Color(red: 1.0, green: 0.75, blue: 0.0))
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                        VStack(spacing: 12) {
                             Text("No professionals found")
                                 .foregroundColor(.gray)
                         }
                    } else if viewModel.searchResults.isEmpty {
                        VStack(spacing: 12) {
                            Text("Type a name to search for professionals")
                                .foregroundColor(.gray)
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
                            .padding(16)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                isSearchFocused = true
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
                // Avatar
                if let avatarUrl = professional.avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray.opacity(0.3))
                            .frame(width: 56, height: 56)
                    }
                } else {
                    // Fallback Avatar if no URL
                    Image(professional.fullName?.lowercased().contains("burger") ?? false ? "burger_placeholder" : "person.circle.fill") // Logic to match screenshot example "charlot" -> burger image? No, generic fallback.
                    // Actually, screenshot shows "charlot" with a burger image. Professional likely set that as avatar.
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                        .foregroundColor(.gray.opacity(0.3))
                         // If no image asset, system image
                        .overlay(
                            Group {
                                if professional.avatarUrl == nil {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 24))
                                }
                            }
                        )
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Info
                Text(professional.fullName ?? "Unknown Professional")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15)) // Almost black
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
}

struct SearchScreen_Previews: PreviewProvider {
    static var previews: some View {
        SearchScreen { _ in }
    }
}
