import SwiftUI
import PhotosUI
import Combine
import MapKit
import CoreLocation

// MARK: - CreateEventView
struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateEventViewModel()
    @State private var showMapPicker = false

    let categories = ["cuisine française", "cuisine tunisienne", "cuisine japonaise"]
    let statuts = ["à venir", "en cours", "terminé"]
    let onSubmit: (Event) -> Void
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 10)
                    
                    EventFieldLabel(text: "Nom de l'événement")
                    StyledTextField(
                        text: $viewModel.nom,
                        placeholder: "Ex: Festival Street Food Ramadan",
                        systemImage: "plus"
                    )
                    .onChange(of: viewModel.nom) { _, _ in
                        viewModel.objectWillChange.send()
                    }
                    
                    EventFieldLabel(text: "Description")
                    DescriptionTextField(
                        text: $viewModel.description,
                        placeholder: "Décrivez l'événement..."
                    )
                    .onChange(of: viewModel.description) { _, _ in
                        viewModel.objectWillChange.send()
                    }
                    
                    EventFieldLabel(text: "Date de début")
                    DatePicker(
                        "",
                        selection: $viewModel.dateDebutPicker,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .background(BrandColors.Cream100)
                    .cornerRadius(16)
                    
                    EventFieldLabel(text: "Date de fin")
                    DatePicker(
                        "",
                        selection: $viewModel.dateFinPicker,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .background(BrandColors.Cream100)
                    .cornerRadius(16)
                    
                    // 🔥 SECTION LIEU MODIFIÉE
                    EventFieldLabel(text: "Lieu")
                    Button(action: { showMapPicker = true }) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(BrandColors.TextSecondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.selectedCoordinate != nil && !viewModel.selectedLocationName.isEmpty
                                     ? viewModel.selectedLocationName
                                     : "Sélectionnez un lieu")
                                    .foregroundColor(viewModel.selectedCoordinate != nil
                                                   ? BrandColors.TextPrimary
                                                   : BrandColors.TextSecondary)
                                
                                if let coord = viewModel.selectedCoordinate {
                                    Text(String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                                        .font(.caption)
                                        .foregroundColor(BrandColors.TextSecondary)
                                }
                            }
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(BrandColors.TextSecondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(BrandColors.Cream100)
                        .cornerRadius(16)
                    }
                    .sheet(isPresented: $showMapPicker) {
                        NavigationView {
                            MapPickerView(selectedCoordinate: $viewModel.selectedCoordinate)
                                .navigationTitle("Sélectionner un lieu")
                                .navigationBarTitleDisplayMode(.inline)
                                .onDisappear {
                                    if let coordinate = viewModel.selectedCoordinate {
                                        viewModel.updateLocationName(for: coordinate)
                                        viewModel.objectWillChange.send()
                                    }
                                }
                        }
                    }
                    
                    EventFieldLabel(text: "Catégorie")
                    CustomDropdown(
                        selected: $viewModel.categorie,
                        placeholder: "Sélectionnez une catégorie",
                        options: categories,
                        systemImage: "plus"
                    )
                    .onChange(of: viewModel.categorie) { _, _ in
                        viewModel.objectWillChange.send()
                    }
                    
                    EventFieldLabel(text: "Statut")
                    CustomDropdown(
                        selected: $viewModel.statut,
                        placeholder: "Sélectionnez un statut",
                        options: statuts,
                        systemImage: "info.circle"
                    )
                    
                    EventFieldLabel(text: "Image (Optionnelle)")
                    ImageSection(
                        imageState: $viewModel.imageState,
                        onAddImage: { viewModel.showImagePicker = true },
                        onRemoveImage: { 
                            viewModel.imageState = ImagePicker.ImageState.empty
                        }
                    )
                    .photosPicker(
                        isPresented: $viewModel.showImagePicker,
                        selection: $viewModel.selectedPhotoItem,
                        matching: .images
                    )
                    
                    CreateButton(
                        isValid: viewModel.isValid && !viewModel.isCreating,
                        action: {
                            print("🔘 Bouton CreateButton cliqué!")
                            viewModel.isCreating = true
                            if let event = viewModel.createEvent() {
                                onSubmit(event)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewModel.isCreating = false
                                    dismiss()
                                }
                            } else {
                                viewModel.isCreating = false
                            }
                        }
                    )
                    .id("createButton_\(viewModel.isValid)_\(viewModel.nom.prefix(5))_\(viewModel.description.count)_\(viewModel.categorie.prefix(5))_\(viewModel.selectedCoordinate != nil)")
                    .onChange(of: viewModel.nom) { _, _ in
                        print("📝 Nom changé: '\(viewModel.nom)' - isValid: \(viewModel.isValid)")
                    }
                    .onChange(of: viewModel.description) { _, _ in
                        print("📝 Description changée: count=\(viewModel.description.count) - isValid: \(viewModel.isValid)")
                    }
                    .onChange(of: viewModel.categorie) { _, _ in
                        print("📝 Catégorie changée: '\(viewModel.categorie)' - isValid: \(viewModel.isValid)")
                    }
                    .onChange(of: viewModel.selectedLocationName) { _, _ in
                        print("📝 LocationName changée: '\(viewModel.selectedLocationName)' - isValid: \(viewModel.isValid)")
                        viewModel.objectWillChange.send()
                    }
                    
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Créer un Événement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") { dismiss() }
                    .foregroundColor(BrandColors.TextPrimary)
            }
        }
        .onChange(of: viewModel.selectedPhotoItem) { oldValue, newValue in
            guard let newValue = newValue else { return }
            
            Task {
                viewModel.imageState = .loading
                
                do {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        let image = Image(uiImage: uiImage)
                        await MainActor.run {
                            viewModel.imageState = .success(image)
                        }
                    } else {
                        await MainActor.run {
                            viewModel.imageState = .failure(NSError(domain: "ImagePicker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de charger l'image"]))
                        }
                    }
                } catch {
                    await MainActor.run {
                        viewModel.imageState = .failure(error)
                    }
                }
            }
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Composants réutilisables
private struct EventFieldLabel: View {
    let text: String
    var body: some View {
        HStack {
            Text(text).font(.headline).foregroundColor(BrandColors.TextPrimary)
            Spacer()
        }
    }
}

private struct StyledTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage).foregroundColor(BrandColors.TextSecondary)
            TextField(placeholder, text: $text).foregroundColor(BrandColors.TextPrimary)
        }
        .padding()
        .background(BrandColors.Cream100)
        .cornerRadius(16)
    }
}

private struct DescriptionTextField: View {
    @Binding var text: String
    let placeholder: String
    private let maxLength = 500
    
    var body: some View {
        VStack(alignment: .trailing) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(BrandColors.TextSecondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                TextEditor(text: $text)
                    .frame(minHeight: 140)
                    .foregroundColor(BrandColors.TextPrimary)
                    .onChange(of: text) { oldValue, newValue in
                        if newValue.count > maxLength { text = String(newValue.prefix(maxLength)) }
                    }
            }
            .padding()
            .background(BrandColors.Cream100)
            .cornerRadius(16)
        }
    }
}

private struct CustomDropdown: View {
    @Binding var selected: String
    let placeholder: String
    let options: [String]
    let systemImage: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            Button {
                isExpanded.toggle()
            } label: {
                HStack {
                    Image(systemName: systemImage).foregroundColor(BrandColors.TextSecondary)
                    Text(selected.isEmpty ? placeholder : selected)
                        .foregroundColor(selected.isEmpty ? BrandColors.TextSecondary : BrandColors.TextPrimary)
                    Spacer()
                    Image(systemName: "chevron.down").rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .background(BrandColors.Cream100)
                .cornerRadius(16)
            }
            if isExpanded {
                VStack {
                    ForEach(options, id: \.self) { option in
                        Button(option) {
                            print("📋 Dropdown - Option sélectionnée: '\(option)'")
                            selected = option
                            isExpanded = false
                            // Force update
                            DispatchQueue.main.async {
                                // This will trigger onChange in parent view
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                }
                .background(Color.white)
                .cornerRadius(8)
            }
        }
        .onChange(of: selected) { oldValue, newValue in
            print("📋 Dropdown - selected changé de '\(oldValue)' à '\(newValue)'")
        }
    }
}

private struct ImageSection: View {
    @Binding var imageState: ImagePicker.ImageState
    let onAddImage: () -> Void
    let onRemoveImage: () -> Void
    
    var body: some View {
        switch imageState {
        case .empty:
            Button(action: onAddImage) {
                VStack {
                    Image(systemName: "plus").font(.largeTitle).foregroundColor(BrandColors.TextSecondary)
                    Text("Ajouter une image").foregroundColor(BrandColors.TextSecondary)
                }
                .frame(height: 160).frame(maxWidth: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(BrandColors.Cream200, style: StrokeStyle(lineWidth: 2, dash: [5])))
            }
        case .loading:
            ProgressView().frame(height: 200).frame(maxWidth: .infinity).background(Color.gray.opacity(0.1)).cornerRadius(16)
        case .success(let image):
            ZStack(alignment: .topTrailing) {
                image.resizable().scaledToFill().frame(height: 200).clipped().cornerRadius(16)
                Button(action: onRemoveImage) {
                    Image(systemName: "xmark").foregroundColor(.white).padding(8).background(Color.black.opacity(0.6)).clipShape(RoundedRectangle(cornerRadius: 8))
                }.padding(8)
            }
        case .failure:
            VStack {
                Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundColor(.red)
                Text("Erreur de chargement").foregroundColor(.red)
            }.frame(height: 200).frame(maxWidth: .infinity).background(Color.gray.opacity(0.1)).cornerRadius(16)
        }
    }
}

private struct CreateButton: View {
    let isValid: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            print("🔘 CreateButton - action appelée, isValid: \(isValid)")
            if isValid {
                action()
            }
        }) {
            Text(isValid ? "Créer l'événement" : "Remplissez tous les champs")
                .foregroundColor(BrandColors.TextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isValid ? BrandColors.Yellow : BrandColors.Yellow.opacity(0.6))
                .cornerRadius(24)
        }
        .disabled(!isValid)
        .onAppear {
            print("🔘 CreateButton rendu - isValid: \(isValid)")
        }
    }
}

// MARK: - ViewModel
class CreateEventViewModel: ObservableObject {
    @Published var nom = ""
    @Published var description = ""
    @Published var dateDebutPicker = Date()
    @Published var dateFinPicker = Date()
    @Published var lieu = ""
    @Published var categorie = ""
    @Published var statut = "à venir"
    @Published var imageState: ImagePicker.ImageState = .empty
    @Published var showImagePicker = false
    @Published var selectedPhotoItem: PhotosPickerItem? = nil
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isCreating = false
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var selectedLocationName: String = ""
    
    // Computed property that triggers updates
    var isValid: Bool {
        let trimmedNom = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategorie = categorie.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLieu = lieu.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let nomValid = !trimmedNom.isEmpty
        let descriptionValid = !trimmedDescription.isEmpty && trimmedDescription.count >= 10
        // Lieu is valid if either coordinate is set OR location name is set OR lieu string is set
        let lieuValid = selectedCoordinate != nil || !selectedLocationName.isEmpty || !trimmedLieu.isEmpty
        let categorieValid = !trimmedCategorie.isEmpty
        
        let result = nomValid && descriptionValid && lieuValid && categorieValid
        
        // Always log validation state for debugging
        print("🔍 Validation - isValid: \(result)")
        print("   Nom: '\(trimmedNom)' (\(trimmedNom.count) chars) - Valid: \(nomValid)")
        print("   Description: '\(trimmedDescription.prefix(50))...' (\(trimmedDescription.count) chars) - Valid: \(descriptionValid)")
        print("   Lieu - coordinate: \(selectedCoordinate != nil), locationName: '\(selectedLocationName)', lieu: '\(trimmedLieu)' - Valid: \(lieuValid)")
        print("   Catégorie: '\(trimmedCategorie)' - Valid: \(categorieValid)")
        
        return result
    }
    
    func createEvent() -> Event? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        let formattedDateDebut = isoFormatter.string(from: dateDebutPicker)
        let formattedDateFin = isoFormatter.string(from: dateFinPicker)
        
        let statutLowercased = statut.lowercased()
        let eventStatus: EventStatus
        switch statutLowercased {
        case "à venir": eventStatus = .aVenir
        case "en cours": eventStatus = .enCours
        case "terminé": eventStatus = .termine
        default:
            errorMessage = "Statut invalide"
            showError = true
            return nil
        }

        let lieuString: String
        if let coord = selectedCoordinate {
            lieuString = !selectedLocationName.isEmpty
                ? selectedLocationName
                : "\(coord.latitude),\(coord.longitude)"
        } else {
            lieuString = lieu.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return Event(
            nom: nom,
            description: description,
            dateDebut: formattedDateDebut,
            dateFin: formattedDateFin,
            image: nil,
            lieu: lieuString,
            categorie: categorie,
            statut: eventStatus
        )
    }
    
    func updateLocationName(for coordinate: CLLocationCoordinate2D) {
        // Note: CLGeocoder is deprecated in iOS 26.0, but MapKit alternative requires iOS 18+
        // Using CLGeocoder for compatibility with current iOS versions
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks: [CLPlacemark]?, error: Error?) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    
                    if let name = placemark.name {
                        addressComponents.append(name)
                    }
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    
                    self.selectedLocationName = addressComponents.isEmpty
                        ? "Lieu sélectionné"
                        : addressComponents.joined(separator: ", ")
                } else {
                    self.selectedLocationName = "Lieu sélectionné"
                }
            }
        }
    }
}
