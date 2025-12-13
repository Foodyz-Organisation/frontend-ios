import SwiftUI
import PhotosUI
import Combine
import MapKit
import CoreLocation

// MARK: - EditEventView
struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditEventViewModel
    @State private var showMapPicker = false

    let event: Event
    let onUpdate: (Event) -> Void
    
    init(event: Event, onUpdate: @escaping (Event) -> Void) {
        self.event = event
        self.onUpdate = onUpdate
        _viewModel = StateObject(wrappedValue: EditEventViewModel(event: event))
    }
    
    let categories = ["cuisine française", "cuisine tunisienne", "cuisine japonaise"]
    let statuts = ["à venir", "en cours", "terminé"]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 10)
                    
                    EventFieldLabel(text: "Nom de l'événement")
                    StyledTextField(text: $viewModel.nom, placeholder: "Ex: Festival Street Food Ramadan", systemImage: "plus")
                    
                    EventFieldLabel(text: "Description")
                    DescriptionTextField(text: $viewModel.description, placeholder: "Décrivez l'événement...")
                    
                    EventFieldLabel(text: "Date de début")
                    DatePicker("", selection: $viewModel.dateDebutPicker, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .padding()
                        .background(BrandColors.Cream100)
                        .cornerRadius(16)
                    
                    EventFieldLabel(text: "Date de fin")
                    DatePicker("", selection: $viewModel.dateFinPicker, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .padding()
                        .background(BrandColors.Cream100)
                        .cornerRadius(16)
                    
                    // 🔥 SECTION LIEU MODIFIÉE - Identique à CreateEventView
                    EventFieldLabel(text: "Lieu")
                    Button(action: { showMapPicker = true }) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(BrandColors.TextSecondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.selectedCoordinate != nil && !viewModel.selectedLocationName.isEmpty
                                     ? viewModel.selectedLocationName
                                     : (viewModel.lieu.isEmpty ? "Sélectionnez un lieu" : viewModel.lieu))
                                    .foregroundColor(viewModel.selectedCoordinate != nil || !viewModel.lieu.isEmpty
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
                                    }
                                }
                        }
                    }
                    
                    EventFieldLabel(text: "Catégorie")
                    CustomDropdown(selected: $viewModel.categorie, placeholder: "Sélectionnez une catégorie", options: categories, systemImage: "plus")
                    
                    EventFieldLabel(text: "Statut")
                    CustomDropdown(selected: $viewModel.statut, placeholder: "Sélectionnez un statut", options: statuts, systemImage: "info.circle")
                    
                    EventFieldLabel(text: "Image (Optionnelle)")
                    ImageSection(imageState: $viewModel.imageState, onAddImage: { viewModel.showImagePicker = true }, onRemoveImage: { viewModel.imageState = .empty })
                    
                    CreateButton(isValid: viewModel.isValid && !viewModel.isUpdating) {
                        viewModel.isUpdating = true
                        
                        // ✅ Format ISO correct pour les dates
                        let isoFormatter = ISO8601DateFormatter()
                        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        
                        // ✅ Gestion du lieu avec coordonnées ou texte
                        let lieuString: String
                        if let coord = viewModel.selectedCoordinate {
                            lieuString = !viewModel.selectedLocationName.isEmpty
                                ? viewModel.selectedLocationName
                                : "\(coord.latitude),\(coord.longitude)"
                        } else {
                            lieuString = viewModel.lieu.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        
                        let eventDTO = EventDTO(
                            id: event.id,
                            nom: viewModel.nom,
                            description: viewModel.description,
                            dateDebut: isoFormatter.string(from: viewModel.dateDebutPicker),
                            dateFin: isoFormatter.string(from: viewModel.dateFinPicker),
                            image: event.image,
                            lieu: lieuString,
                            categorie: viewModel.categorie,
                            statut: viewModel.statut
                        )
                        
                        print("📤 Envoi de la mise à jour pour l'événement: \(event.id)")
                        print("📤 Statut envoyé: '\(viewModel.statut)'")
                        print("📤 Lieu envoyé: '\(lieuString)'")
                        
                        // Appel API pour mettre à jour
                        EventAPI.shared.updateEvent(event.id, event: eventDTO) { result in
                            DispatchQueue.main.async {
                                viewModel.isUpdating = false
                                
                                switch result {
                                case .success(let updatedDTO):
                                    print("✅ Mise à jour réussie!")
                                    
                                    guard let updatedEvent = updatedDTO.toEvent() else {
                                        viewModel.errorMessage = "Erreur de conversion du statut"
                                        viewModel.showError = true
                                        return
                                    }
                                    
                                    onUpdate(updatedEvent)
                                    dismiss()
                                    
                                case .failure(let error):
                                    print("❌ Erreur de mise à jour: \(error.localizedDescription)")
                                    viewModel.errorMessage = "Erreur: \(error.localizedDescription)"
                                    viewModel.showError = true
                                }
                            }
                        }
                    }
                    
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Modifier l'Événement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") { dismiss() }
                    .foregroundColor(BrandColors.TextPrimary)
            }
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(imageState: $viewModel.imageState)
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
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
                            selected = option
                            isExpanded = false
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                }
                .background(Color.white)
                .cornerRadius(8)
            }
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
        Button(action: action) {
            Text(isValid ? "Enregistrer les modifications" : "Remplissez tous les champs")
                .foregroundColor(BrandColors.TextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isValid ? BrandColors.Yellow : BrandColors.Yellow.opacity(0.6))
                .cornerRadius(24)
        }
        .disabled(!isValid)
    }
}

// MARK: - ViewModel
class EditEventViewModel: ObservableObject {
    @Published var nom: String
    @Published var description: String
    @Published var dateDebutPicker: Date
    @Published var dateFinPicker: Date
    @Published var lieu: String
    @Published var categorie: String
    @Published var statut: String
    @Published var imageState: ImagePicker.ImageState = .empty
    @Published var showImagePicker = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isUpdating = false
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var selectedLocationName: String = ""

    init(event: Event) {
        self.nom = event.nom
        self.description = event.description
        self.lieu = event.lieu
        self.categorie = event.categorie
        self.statut = event.statut.rawValue

        // Conversion ISO string -> Date
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        self.dateDebutPicker = isoFormatter.date(from: event.dateDebut) ?? Date()
        self.dateFinPicker = isoFormatter.date(from: event.dateFin) ?? Date()
        
        // ✅ Tentative d'extraction des coordonnées du lieu existant
        parseExistingLocation(from: event.lieu)
    }
    
    private func parseExistingLocation(from lieu: String) {
        // Si le lieu contient des coordonnées au format "latitude,longitude"
        let components = lieu.components(separatedBy: ",")
        if components.count == 2,
           let lat = Double(components[0].trimmingCharacters(in: .whitespaces)),
           let lon = Double(components[1].trimmingCharacters(in: .whitespaces)) {
            selectedCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            updateLocationName(for: selectedCoordinate!)
        }
    }

    var isValid: Bool {
        !nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        description.count >= 10 &&
        (selectedCoordinate != nil || !lieu.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) &&
        !categorie.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
