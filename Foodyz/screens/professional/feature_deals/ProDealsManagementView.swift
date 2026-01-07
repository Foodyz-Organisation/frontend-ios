import SwiftUI
import PhotosUI

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
                DealInfoRow(icon: "percent", text: "-\(deal.discountPercentage)%")
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
    @State private var discountPercentage = ""
    @State private var scope: String = "ALL"
    @State private var selectedLocation: LocationDto?
    
    // Selection States
    @State private var selectedCategories: Set<String> = []
    @State private var selectedItems: Set<String> = []
    
    @State private var imageUrl = "" // Gardé pour l'édition (si image existante)
    @State private var selectedUIImage: UIImage? = nil // Image sélectionnée depuis le simulateur
    @State private var imageState: ImagePicker.ImageState = .empty
    @State private var showImagePicker = false
    @State private var showLocationPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var startDate = Date()
    @State private var startTime = Date()
    @State private var endDate = Date()
    @State private var endTime = Date()
    @State private var isActive = true
    @State private var isLoading = false
    
    init(viewModel: DealsViewModel, dealId: String? = nil) {
        self.viewModel = viewModel
        self.dealId = dealId
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                basicInfoSection
                scopeSelectionSection
                detailsSection
                datesSection
                actionSection
            }
            .padding()
        }
        .sheet(isPresented: $showLocationPicker) {
            ProMapPickerView(selectedLocation: $selectedLocation)
        }
        .navigationTitle(dealId == nil ? "Nouveau Deal" : "Modifier Deal")
        .navigationBarTitleDisplayMode(.inline)
        .background(BrandColors.Cream100)
        .onAppear {
            // S'assurer que les champs sont vides lors de la création
            if dealId == nil {
                restaurantName = ""
                description = ""
                category = ""
                discountPercentage = ""
                scope = "ALL"
                selectedLocation = nil
                selectedCategories = []
                selectedItems = []
                imageUrl = ""
                selectedUIImage = nil
                imageState = .empty
                selectedPhotoItem = nil
                startDate = Date()
                startTime = Date()
                endDate = Date().addingTimeInterval(86400) // Demain par défaut
                endTime = Date().addingTimeInterval(86400)
                isActive = true
            } else {
                loadDealForEditing(dealId: dealId!)
            }
        }
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onAppear {
            // Charger le menu si nécessaire
            if viewModel.menuGroups.isEmpty {
                viewModel.loadMenu()
            }
        }
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            guard let newValue = newValue else { return }
            
            Task {
                await MainActor.run {
                    imageState = .loading
                }
                
                do {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        let image = Image(uiImage: uiImage)
                        await MainActor.run {
                            imageState = .success(image)
                            selectedUIImage = uiImage
                            imageUrl = "" // Réinitialiser l'URL car on a une nouvelle image
                        }
                    } else {
                        await MainActor.run {
                            imageState = .failure(NSError(domain: "ImagePicker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de charger l'image"]))
                            selectedUIImage = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        imageState = .failure(error)
                        selectedUIImage = nil
                    }
                }
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
    
    // MARK: - Subviews
    
    private var basicInfoSection: some View {
        Group {
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
        }
    }
    
    private var scopeSelectionSection: some View {
        // Items applicables
        VStack(alignment: .leading, spacing: 12) {
            Text("Items applicables au deal")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(BrandColors.TextPrimary)
            
            VStack(spacing: 16) {
                // Tabs
                HStack(spacing: 8) {
                    ScopeButton(title: "Tous", isSelected: scope == "ALL") { scope = "ALL" }
                    ScopeButton(title: "Catégorie", isSelected: scope == "CATEGORY") { scope = "CATEGORY" }
                    ScopeButton(title: "Items", isSelected: scope == "ITEMS") { scope = "ITEMS" }
                }
                
                if scope == "ALL" {
                    HStack {
                        Image(systemName: "checkmark.square.fill")
                        .foregroundColor(BrandColors.Green)
                        Text("Le deal s'applique à tous les items du menu")
                            .font(.system(size: 14))
                            .foregroundColor(BrandColors.TextSecondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(BrandColors.FieldFill)
                    .cornerRadius(8)
                }
                
                // Category Selection
                if scope == "CATEGORY" {
                    categorySelectionView
                }
                
                // Item Selection
                if scope == "ITEMS" {
                    itemSelectionView
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2)
        }
    }
    
    private var detailsSection: some View {
        Group {
            // Category
            VStack(alignment: .leading, spacing: 8) {
                Text("Catégorie")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(BrandColors.TextPrimary)
                
                TextField("Sélectionnez une catégorie", text: $category) // Simulate dropdown with text for now
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            // Discount Percentage
            VStack(alignment: .leading, spacing: 8) {
                Text("Pourcentage de réduction (%)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BrandColors.TextPrimary)
                
                TextField("Ex: 20", text: $discountPercentage)
                    .keyboardType(.numberPad)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            // Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Lieu du restaurant")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(BrandColors.TextPrimary)
                
                Button(action: { showLocationPicker = true }) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(BrandColors.TextSecondary)
                        Text(selectedLocation?.name ?? selectedLocation?.address ?? "Sélectionnez un lieu")
                            .foregroundColor(selectedLocation == nil ? BrandColors.TextSecondary : BrandColors.TextPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(BrandColors.TextSecondary)
                    }
                    .padding(16)
                    .background(BrandColors.FieldFill)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var datesSection: some View {
        Group {
            // Date Début
            VStack(alignment: .leading, spacing: 8) {
                Text("Date de début")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(BrandColors.TextPrimary)
                
                HStack(spacing: 12) {
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .background(BrandColors.FieldFill)
                        .cornerRadius(8)
                    
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .background(BrandColors.FieldFill)
                        .cornerRadius(8)
                }
            }
            
            // Date Fin
            VStack(alignment: .leading, spacing: 8) {
                Text("Date de fin")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(BrandColors.TextPrimary)
                
                HStack(spacing: 12) {
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .background(BrandColors.FieldFill)
                        .cornerRadius(8)
                    
                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .background(BrandColors.FieldFill)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var actionSection: some View {
        Group {
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
                    Text("Remplissez tous les champs") // As per screenshot, dynamic?
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(BrandColors.TextPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(BrandColors.Yellow)
            .cornerRadius(12)
            .padding(.top, 20)
        }
        }

    
    private var categorySelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sélectionnez les catégories:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(BrandColors.TextPrimary)
            
            ForEach(Array(viewModel.menuGroups.keys.sorted()), id: \.self) { categoryName in
                Toggle(isOn: Binding(
                    get: { selectedCategories.contains(categoryName) },
                    set: { isSelected in
                        if isSelected {
                            selectedCategories.insert(categoryName)
                        } else {
                            selectedCategories.remove(categoryName)
                        }
                    }
                )) {
                    Text(categoryName)
                        .font(.system(size: 14))
                        .foregroundColor(BrandColors.TextPrimary)
                }
                .toggleStyle(CheckboxToggleStyle())
            }
            
            if selectedCategories.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(BrandColors.Yellow)
                    Text("Sélectionnez au moins une catégorie")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(BrandColors.FieldFill.opacity(0.3))
        .cornerRadius(8)
    }

    private var itemSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sélectionnez les items:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(BrandColors.TextPrimary)
            
            ForEach(Array(viewModel.menuGroups.keys.sorted()), id: \.self) { categoryName in
                itemsForCategory(categoryName)
            }
            
            if selectedItems.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(BrandColors.Yellow)
                    Text("Sélectionnez au moins un item")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(BrandColors.FieldFill.opacity(0.3))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func itemsForCategory(_ categoryName: String) -> some View {
        if let items = viewModel.menuGroups[categoryName] {
            ForEach(items) { item in
               itemRow(item)
            }
        }
    }

    private func itemRow(_ item: MenuItemResponse) -> some View {
        HStack {
            Toggle(isOn: Binding(
                get: { selectedItems.contains(item.id) },
                set: { isSelected in
                    if isSelected {
                        selectedItems.insert(item.id)
                    } else {
                        selectedItems.remove(item.id)
                    }
                }
            )) {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BrandColors.TextPrimary)
                    Text("\(String(format: "%.1f", item.price))€")
                        .font(.system(size: 12))
                        .foregroundColor(BrandColors.Yellow)
                }
            }
            .toggleStyle(CheckboxToggleStyle())
        }
        .padding(.vertical, 4)
    }

    private func loadDealForEditing(dealId: String) {
        viewModel.loadDealById(dealId)
    }
    
    private func populateFields(with deal: Deal) {
        restaurantName = deal.restaurantName
        description = deal.description
        category = deal.category
        discountPercentage = String(deal.discountPercentage)
        scope = deal.scope
        selectedLocation = deal.location
        
        // Populate selections based on scope
        if scope == "CATEGORY", let cat = deal.applicableCategory {
            selectedCategories = Set(cat.components(separatedBy: ","))
        } else if scope == "ITEMS", let items = deal.applicableItems {
            selectedItems = Set(items)
        } else {
            selectedCategories = []
            selectedItems = []
        }
        
        imageUrl = deal.image
        isActive = deal.isActive
        
        // Pour l'édition, charger l'image existante si disponible
        if !deal.image.isEmpty, let url = URL(string: deal.image) {
            // Charger l'image depuis l'URL pour l'afficher
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            imageState = .success(Image(uiImage: uiImage))
                            selectedUIImage = nil // Pas de nouvelle image, on garde l'URL
                        }
                    }
                } catch {
                    await MainActor.run {
                        imageState = .empty
                    }
                }
            }
        } else {
            imageState = .empty
            selectedUIImage = nil
        }
        
        // Convertir les dates ISO en Date
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let start = isoFormatter.date(from: deal.startDate) {
            startDate = start
            startTime = start
        }
        if let end = isoFormatter.date(from: deal.endDate) {
            endDate = end
            endTime = end
        }
    }
    
    private func saveDeal() {
        // Validation
        guard !restaurantName.trimmingCharacters(in: .whitespaces).isEmpty,
              !description.trimmingCharacters(in: .whitespaces).isEmpty,
              !category.trimmingCharacters(in: .whitespaces).isEmpty,
              !discountPercentage.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("❌ Veuillez remplir tous les champs obligatoires")
            return
        }
        
        // Combine Date and Time
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        
        let endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        guard let finalStartDate = calendar.date(from: DateComponents(year: startComponents.year, month: startComponents.month, day: startComponents.day, hour: startTimeComponents.hour, minute: startTimeComponents.minute)),
              let finalEndDate = calendar.date(from: DateComponents(year: endComponents.year, month: endComponents.month, day: endComponents.day, hour: endTimeComponents.hour, minute: endTimeComponents.minute)) else {
            print("❌ Erreur de conversion de date")
            return
        }
        
        // Validation: la date de fin doit être après la date de début
        guard finalEndDate > finalStartDate else {
            print("❌ La date de fin doit être après la date de début")
            return
        }
        
        isLoading = true
        
        // Formater les dates avec heures en ISO8601
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startDateString = isoFormatter.string(from: finalStartDate)
        let endDateString = isoFormatter.string(from: finalEndDate)
        
        // Convertir l'image en base64 si une nouvelle image a été sélectionnée
        var finalImageUrl: String? = nil
        if let uiImage = selectedUIImage {
            // Nouvelle image sélectionnée : convertir en base64
            if let imageData = uiImage.jpegData(compressionQuality: 0.8) {
                finalImageUrl = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
                print("📸 Image convertie en base64 - Taille: \(imageData.count) bytes")
            }
        } else if !imageUrl.isEmpty {
            // Image existante (en mode édition) : garder l'URL
            finalImageUrl = imageUrl
        }
        
        // Prepare applicable data
        let applicableItemsList = scope == "ITEMS" ? Array(selectedItems) : nil
        let applicableCategoryString = scope == "CATEGORY" ? selectedCategories.joined(separator: ",") : nil
        
        if let dealId = dealId {
            // Mode édition
            let updateDto = UpdateDealDto(
                restaurantName: restaurantName,
                description: description,
                image: finalImageUrl,
                category: category,
                discountPercentage: Int(discountPercentage),
                scope: scope,
                applicableItems: applicableItemsList,
                applicableCategory: applicableCategoryString,
                location: selectedLocation,
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
                image: finalImageUrl ?? "https://via.placeholder.com/400", // Fallback si aucune image
                category: category,
                discountPercentage: Int(discountPercentage) ?? 0,
                scope: scope,
                applicableItems: applicableItemsList,
                applicableCategory: applicableCategoryString,
                location: selectedLocation,
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
            DetailInfoCard(icon: "percent", title: "Réduction", value: "-\(deal.discountPercentage)%")
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

// MARK: - Deal Image Section
struct DealImageSection: View {
    @Binding var imageState: ImagePicker.ImageState
    let existingImageUrl: String?
    let onAddImage: () -> Void
    let onRemoveImage: () -> Void
    
    var body: some View {
        Group {
            switch imageState {
            case .empty:
                // Afficher l'image existante si disponible (mode édition)
                if let urlString = existingImageUrl, !urlString.isEmpty, let url = URL(string: urlString) {
                    ZStack(alignment: .topTrailing) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(16)
                        .background(BrandColors.FieldFill)
                        
                        Button(action: onRemoveImage) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(8)
                    }
                } else {
                    // Bouton pour ajouter une image
                    Button(action: onAddImage) {
                        VStack {
                            Image(systemName: "plus")
                                .font(.largeTitle)
                                .foregroundColor(BrandColors.TextSecondary)
                            Text("Ajouter une image")
                                .foregroundColor(BrandColors.TextSecondary)
                        }
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(BrandColors.Cream200, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    }
                }
            case .loading:
                ProgressView()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(BrandColors.FieldFill)
                    .cornerRadius(16)
            case .success(let image):
                ZStack(alignment: .topTrailing) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(16)
                        .background(BrandColors.FieldFill)
                    
                    Button(action: onRemoveImage) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
            case .failure:
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Erreur de chargement")
                        .foregroundColor(.red)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(BrandColors.FieldFill)
                .cornerRadius(16)
            }
        }
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

// MARK: - Scope Button
struct ScopeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? BrandColors.TextPrimary : BrandColors.TextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? BrandColors.Yellow : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? BrandColors.Yellow : BrandColors.Cream200, lineWidth: 1)
                )
        }
    }
}
