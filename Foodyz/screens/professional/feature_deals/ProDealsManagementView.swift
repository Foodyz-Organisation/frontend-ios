import SwiftUI

struct ProDealsManagementView: View {
    @ObservedObject var viewModel: DealsViewModel
    @State private var showAlert = false
    @State private var alertMessage = ""
    var onAddDealClick: () -> Void
    var onEditDealClick: (String) -> Void
    
    var body: some View {
        ZStack {
            BrandColors.Cream100.ignoresSafeArea()
            
            content
        }
        .navigationTitle("Mes Deals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.loadDeals() }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(BrandColors.TextPrimary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: onAddDealClick) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(BrandColors.Yellow)
                        .font(.title2)
                }
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                viewModel.clearOperationResult()
            }
        }
        .onReceive(viewModel.$operationResult) { result in
            if let result = result {
                switch result {
                case .success(let message):
                    alertMessage = message
                    showAlert = true
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.dealsState {
        case .loading:
            LoadingStateView()
        case .success(let deals):
            if deals.isEmpty {
                EmptyDealsStateView()
            } else {
                dealsListView(deals: deals)
            }
        case .error(let message):
            ErrorStateView(message: message) {
                viewModel.loadDeals()
            }
        }
    }
    
    private func dealsListView(deals: [Deal]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(deals) { deal in
                    DealCardView(
                        deal: deal,
                        onEdit: {
                            onEditDealClick(deal._id)
                        },
                        onDelete: {
                            viewModel.deleteDeal(deal._id)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Deal Card View
struct DealCardView: View {
    let deal: Deal
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image avec overlay
            ZStack(alignment: .topTrailing) {
                if let url = URL(string: deal.image) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        placeholderImage
                    }
                    .frame(height: 180)
                    .clipped()
                } else {
                    placeholderImage
                }
                
                // Boutons d'action
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(BrandColors.Yellow)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(BrandColors.Red)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                .padding(12)
            }
            
            // Contenu
            VStack(alignment: .leading, spacing: 8) {
                DealStatusBadge(isActive: deal.isActive)
                
                Text(deal.restaurantName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(BrandColors.TextPrimary)
                    .lineLimit(2)
                
                Text(deal.description)
                    .font(.system(size: 14))
                    .foregroundColor(BrandColors.TextSecondary)
                    .lineLimit(2)
                
                Divider()
                    .background(BrandColors.Cream200)
                
                DealInfoRow(icon: "tag", text: deal.category)
                DealInfoRow(icon: "calendar", text: "Expire: \(formatDate(deal.endDate))")
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .alert("Supprimer le deal", isPresented: $showDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive, action: onDelete)
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer \"\(deal.restaurantName)\" ?")
        }
    }
    
    private var placeholderImage: some View {
        LinearGradient(
            colors: [BrandColors.Yellow, BrandColors.YellowPressed],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 180)
        .overlay(
            Image(systemName: "tag.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd MMM yyyy"
        displayFormatter.locale = Locale(identifier: "fr_FR")
        
        return displayFormatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct DealStatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        Text(isActive ? "Actif" : "Inactif")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(isActive ? BrandColors.Green : BrandColors.Red)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background((isActive ? BrandColors.Green : BrandColors.Red).opacity(0.15))
            .cornerRadius(8)
    }
}

struct DealInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(BrandColors.TextSecondary)
                .frame(width: 18, height: 18)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(BrandColors.TextSecondary)
        }
    }
}

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(BrandColors.Yellow)
            Text("Chargement des deals...")
                .foregroundColor(BrandColors.TextSecondary)
        }
    }
}

struct EmptyDealsStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag")
                .font(.system(size: 80))
                .foregroundColor(BrandColors.TextSecondary.opacity(0.3))
            
            Text("Aucun deal créé")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(BrandColors.TextPrimary)
            
            Text("Créez votre premier deal")
                .font(.system(size: 14))
                .foregroundColor(BrandColors.TextSecondary)
        }
        .padding(32)
    }
}

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(BrandColors.Red.opacity(0.7))
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(BrandColors.TextPrimary)
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Réessayer")
                }
                .foregroundColor(BrandColors.TextPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(BrandColors.Yellow)
                .cornerRadius(24)
            }
        }
        .padding()
    }
}

// MARK: - Add/Edit Deal View
struct AddEditDealView: View {
    @ObservedObject var viewModel: DealsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var restaurantName = ""
    @State private var description = ""
    @State private var category = ""
    @State private var imageUrl = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isActive = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Restaurant Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nom du Restaurant")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BrandColors.TextPrimary)
                    
                    TextField("Entrez le nom", text: $restaurantName)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BrandColors.TextPrimary)
                    
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .padding(8)
                        .background(BrandColors.FieldFill)
                        .cornerRadius(8)
                }
                
                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Catégorie")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BrandColors.TextPrimary)
                    
                    TextField("Ex: Pizza, Burger...", text: $category)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // Image URL
                VStack(alignment: .leading, spacing: 8) {
                    Text("URL de l'image")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BrandColors.TextPrimary)
                    
                    TextField("https://...", text: $imageUrl)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                // Date Range
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date de début")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BrandColors.TextPrimary)
                        
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date de fin")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(BrandColors.TextPrimary)
                        
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                
                // Active Toggle
                Toggle(isOn: $isActive) {
                    Text("Deal actif")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BrandColors.TextPrimary)
                }
                .tint(BrandColors.Yellow)
                
                // Save Button
                Button(action: saveDeal) {
                    Text("Enregistrer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(BrandColors.TextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(BrandColors.Yellow)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Nouveau Deal")
        .navigationBarTitleDisplayMode(.inline)
        .background(BrandColors.Cream100)
    }
    
    private func saveDeal() {
        // TODO: Implement save logic with viewModel
        print("💾 Saving deal: \(restaurantName)")
        dismiss()
    }
}

// MARK: - Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(BrandColors.FieldFill)
            .cornerRadius(8)
    }
}
