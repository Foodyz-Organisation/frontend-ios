import SwiftUI
import PhotosUI
import Combine
import MapKit

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
                    
                    EventFieldLabel(text: "Description")
                    DescriptionTextField(
                        text: $viewModel.description,
                        placeholder: "Décrivez l'événement..."
                    )
                    
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
                        onRemoveImage: { viewModel.imageState = .empty }
                    )
                    
                    CreateButton(isValid: viewModel.isValid && !viewModel.isCreating) {
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
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(imageState: $viewModel.imageState)
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
                    .onChange(of: text) { newValue in
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
            Text(isValid ? "Créer l'événement" : "Remplissez tous les champs")
                .foregroundColor(BrandColors.TextPrimary)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(isValid ? BrandColors.Yellow : BrandColors.Yellow.opacity(0.6))
                .cornerRadius(24)
        }.disabled(!isValid)
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
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isCreating = false
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var selectedLocationName: String = ""
    
    var isValid: Bool {
        !nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        description.count >= 10 &&
        (selectedCoordinate != nil || !lieu.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) &&
        !categorie.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
