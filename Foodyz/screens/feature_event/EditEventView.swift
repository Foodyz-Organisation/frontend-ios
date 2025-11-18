import SwiftUI
import PhotosUI
import Combine

// MARK: - EditEventView
struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditEventViewModel
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
                    
                    EventFieldLabel(text: "Lieu")
                    StyledTextField(text: $viewModel.lieu, placeholder: "Ex: Parc de la ville", systemImage: "mappin.and.ellipse")
                    
                    EventFieldLabel(text: "Catégorie")
                    CustomDropdown(selected: $viewModel.categorie, placeholder: "Sélectionnez une catégorie", options: categories, systemImage: "plus")
                    
                    EventFieldLabel(text: "Statut")
                    CustomDropdown(selected: $viewModel.statut, placeholder: "Sélectionnez un statut", options: statuts, systemImage: "info.circle")
                    
                    EventFieldLabel(text: "Image (Optionnelle)")
                    ImageSection(imageState: $viewModel.imageState, onAddImage: { viewModel.showImagePicker = true }, onRemoveImage: { viewModel.imageState = .empty })
                    
                    CreateButton(isValid: viewModel.isValid && !viewModel.isUpdating) {
                        viewModel.isUpdating = true
                        
                        // ✅ FIX: Utiliser le format ISO correct pour les dates
                        let isoFormatter = ISO8601DateFormatter()
                        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        
                        // ✅ FIX: Ne PAS convertir le statut - utiliser le format UI directement
                        let eventDTO = EventDTO(
                            id: event.id,
                            nom: viewModel.nom,
                            description: viewModel.description,
                            dateDebut: isoFormatter.string(from: viewModel.dateDebutPicker),
                            dateFin: isoFormatter.string(from: viewModel.dateFinPicker),
                            image: event.image,
                            lieu: viewModel.lieu,
                            categorie: viewModel.categorie,
                            statut: viewModel.statut  // ✅ Envoyer directement "à venir", "en cours", "terminé"
                        )
                        
                        print("📤 Envoi de la mise à jour pour l'événement: \(event.id)")
                        print("📤 Statut envoyé: '\(viewModel.statut)'")
                        
                        // Appel API pour mettre à jour
                        EventAPI.shared.updateEvent(event.id, event: eventDTO) { result in
                            DispatchQueue.main.async {
                                viewModel.isUpdating = false
                                
                                switch result {
                                case .success(let updatedDTO):
                                    print("✅ Mise à jour réussie!")
                                    
                                    // Convertir le statut reçu en EventStatus
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

    init(event: Event) {
        self.nom = event.nom
        self.description = event.description
        self.lieu = event.lieu
        self.categorie = event.categorie
        
        // ✅ FIX: Conversion du statut enum vers format backend (avec accents)
        self.statut = event.statut.rawValue  // Donne directement "à venir", "en cours", "terminé"

        // Conversion ISO string -> Date
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        self.dateDebutPicker = isoFormatter.date(from: event.dateDebut) ?? Date()
        self.dateFinPicker = isoFormatter.date(from: event.dateFin) ?? Date()
    }

    var isValid: Bool {
        !nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        description.count >= 10 &&
        !lieu.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !categorie.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
