import SwiftUI

struct ProDealsManagementView: View {
    @ObservedObject var viewModel: DealsViewModel
    @State private var showAlert = false
    @State private var alertMessage = ""
    var onAddDealClick: () -> Void
    var onEditDealClick: (String) -> Void
    var onDealClick: ((String) -> Void)? = nil
    
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
                        onTap: {
                            onDealClick?(deal._id)
                        },
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
    let onTap: () -> Void
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
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
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
        displayFormatter.dateFormat = "dd MMM yyyy 'à' HH:mm"
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
    
    let dealId: String? // nil pour création, non-nil pour édition
    
    @State private var restaurantName = ""
    @State private var description = ""
    @State private var category = ""
    @State private var imageUrl = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isActive = true
    @State private var isLoading = false
    
    init(viewModel: DealsViewModel, dealId: String? = nil) {
        self.viewModel = viewModel
        self.dealId = dealId
    }
    
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
                
                // Date et Heure de début
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date et heure de début")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BrandColors.TextPrimary)
                    
                    DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                
                // Date et Heure de fin
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date et heure de fin")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BrandColors.TextPrimary)
                    
                    DatePicker("", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
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
                    if isLoading {
                        ProgressView()
                            .tint(BrandColors.TextPrimary)
                    } else {
                        Text("Enregistrer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(BrandColors.TextPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(BrandColors.Yellow)
                .cornerRadius(12)
                .disabled(isLoading || restaurantName.trimmingCharacters(in: .whitespaces).isEmpty || description.trimmingCharacters(in: .whitespaces).isEmpty || category.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle(dealId == nil ? "Nouveau Deal" : "Modifier Deal")
        .navigationBarTitleDisplayMode(.inline)
        .background(BrandColors.Cream100)
        .onAppear {
            if let dealId = dealId {
                loadDealForEditing(dealId: dealId)
            }
        }
        .onReceive(viewModel.$dealDetailState) { state in
            if case .success(let deal) = state {
                populateFields(with: deal)
            }
        }
        .onReceive(viewModel.$operationResult) { result in
            if case .success = result {
                // Fermer la vue seulement en cas de succès
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
            if result != nil {
                isLoading = false
            }
        }
    }
    
    private func loadDealForEditing(dealId: String) {
        viewModel.loadDealById(dealId)
    }
    
    private func populateFields(with deal: Deal) {
        restaurantName = deal.restaurantName
        description = deal.description
        category = deal.category
        imageUrl = deal.image
        isActive = deal.isActive
        
        // Convertir les dates ISO en Date
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let start = isoFormatter.date(from: deal.startDate) {
            startDate = start
        }
        if let end = isoFormatter.date(from: deal.endDate) {
            endDate = end
        }
    }
    
    private func saveDeal() {
        // Validation
        guard !restaurantName.trimmingCharacters(in: .whitespaces).isEmpty,
              !description.trimmingCharacters(in: .whitespaces).isEmpty,
              !category.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("❌ Veuillez remplir tous les champs obligatoires")
            return
        }
        
        // Validation: la date de fin doit être après la date de début
        guard endDate > startDate else {
            print("❌ La date de fin doit être après la date de début")
            return
        }
        
        isLoading = true
        
        // Formater les dates avec heures en ISO8601
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startDateString = isoFormatter.string(from: startDate)
        let endDateString = isoFormatter.string(from: endDate)
        
        if let dealId = dealId {
            // Mode édition
            let updateDto = UpdateDealDto(
                restaurantName: restaurantName,
                description: description,
                image: imageUrl.isEmpty ? nil : imageUrl,
                category: category,
                startDate: startDateString,
                endDate: endDateString,
                isActive: isActive
            )
            viewModel.updateDeal(dealId, dto: updateDto)
        } else {
            // Mode création
            let createDto = CreateDealDto(
                restaurantName: restaurantName,
                description: description,
                image: imageUrl.isEmpty ? "https://via.placeholder.com/400" : imageUrl,
                category: category,
                startDate: startDateString,
                endDate: endDateString
            )
            viewModel.createDeal(createDto)
        }
        
        // La fermeture sera gérée par onReceive(viewModel.$operationResult)
    }
}

// MARK: - Pro Deal Detail View
struct ProDealDetailView: View {
    let dealId: String
    @ObservedObject var viewModel: DealsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            BrandColors.Cream100.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch viewModel.dealDetailState {
                    case .loading:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(50)
                        
                    case .success(let deal):
                        dealDetailContent(deal: deal)
                        
                    case .error(let message):
                        ErrorStateView(message: message) {
                            viewModel.loadDealById(dealId)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Détails du Deal")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadDealById(dealId)
        }
    }
    
    @ViewBuilder
    private func dealDetailContent(deal: Deal) -> some View {
        // Image
        if let url = URL(string: deal.image) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholderImage
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(16)
        } else {
            placeholderImage
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .cornerRadius(16)
        }
        
        // Contenu
        VStack(alignment: .leading, spacing: 16) {
            // Statut
            DealStatusBadge(isActive: deal.isActive)
            
            // Nom du restaurant
            Text(deal.restaurantName)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(BrandColors.TextPrimary)
            
            // Description
            Text(deal.description)
                .font(.system(size: 16))
                .foregroundColor(BrandColors.TextSecondary)
                .lineSpacing(4)
            
            Divider()
                .background(BrandColors.Cream200)
            
            // Informations détaillées
            DetailInfoCard(icon: "tag.fill", title: "Catégorie", value: deal.category)
            DetailInfoCard(icon: "calendar", title: "Date de début", value: formatDate(deal.startDate))
            DetailInfoCard(icon: "calendar", title: "Date de fin", value: formatDate(deal.endDate))
            DetailInfoCard(icon: "info.circle", title: "Statut", value: deal.isActive ? "Actif" : "Inactif")
            
            if let createdAt = deal.createdAt {
                DetailInfoCard(icon: "clock", title: "Créé le", value: formatDate(createdAt))
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var placeholderImage: some View {
        LinearGradient(
            colors: [BrandColors.Yellow, BrandColors.YellowPressed],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            Image(systemName: "tag.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd MMM yyyy 'à' HH:mm"
        displayFormatter.locale = Locale(identifier: "fr_FR")
        
        return displayFormatter.string(from: date)
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
