import SwiftUI
import PhotosUI

// MARK: - Main Reclamation View
struct ReclamationView: View {
    let restaurantNames: [String]
    let complaintTypes: [String]
    let commandeConcernees: [String]
    var onSubmit: (String, String, String, [UIImage]) -> Void = { _, _, _, _ in }
    @Environment(\.dismiss) private var dismiss
    
    @State private var restaurant = ""
    @State private var complaintType = ""
    @State private var commandeConcernee = ""
    @State private var description = ""
    @State private var agree = false
    @State private var selectedPhotos: [UIImage] = []
    @State private var showImagePicker = false
    @State private var showToast = false
    @State private var toastMessage = "Complaint submitted"
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showLoginAlert = false
    
    private var isValid: Bool {
        !complaintType.isEmpty &&
        !description.isEmpty &&
        !commandeConcernee.isEmpty &&
        agree
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    FieldLabel(text: "Commande Concernee")
                    DropdownField(selected: $commandeConcernee, placeholder: "Select order concerned", options: commandeConcernees, icon: "cart.fill")
                    
                    FieldLabel(text: "Complaint Type")
                    DropdownField(selected: $complaintType, placeholder: "Select complaint type", options: complaintTypes, icon: "xmark.circle.fill")
                    
                    FieldLabel(text: "Description")
                    DescriptionField(text: $description)
                    
                    PhotosSection(photos: $selectedPhotos, showImagePicker: $showImagePicker)
                    
                    // Terms Checkbox
                    HStack(spacing: 8) {
                        Button(action: { agree.toggle() }) {
                            Image(systemName: agree ? "checkmark.square.fill" : "square")
                                .foregroundColor(agree ? .blue : BrandColors.TextSecondary)
                        }
                        Text("I agree to the Terms & Conditions and Privacy Policy")
                            .foregroundColor(BrandColors.TextSecondary)
                            .font(.system(size: 14))
                        Spacer()
                    }
                    
                    // Submit Button
                    Button(action: submitComplaint) {
                        Text("Submit Complaint")
                            .fontWeight(.semibold)
                            .foregroundColor(BrandColors.TextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(LinearGradient(colors: [BrandColors.Yellow, BrandColors.YellowPressed], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(24)
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1.0 : 0.5)
                    
                    Text("You will receive a response within 24 hours")
                        .foregroundColor(BrandColors.TextSecondary)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Reclamation")
                        .foregroundColor(BrandColors.TextPrimary)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(BrandColors.TextPrimary)
                    }
                }
            }
        }
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $photoPickerItems,
            maxSelectionCount: 4,
            matching: .images
        )
        .onChange(of: photoPickerItems) { newItems in
            Task {
                selectedPhotos.removeAll()
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedPhotos.append(image)
                    }
                }
            }
        }
        .overlay(ToastView(message: toastMessage, isShowing: $showToast))
        .alert("Non authentifié", isPresented: $showLoginAlert) {
            Button("OK") {}
        } message: {
            Text("Vous devez être connecté pour créer une réclamation. Veuillez vous reconnecter.")
        }
    }
    
    private func submitComplaint() {
        print("🔥🔥🔥 BOUTON SUBMIT CLIQUÉ 🔥🔥🔥")
        print("📋 isValid = \(isValid)")
        print("📋 complaintType = \(complaintType)")
        print("📋 description = \(description)")
        print("📋 commandeConcernee = \(commandeConcernee)")
        print("📋 agree = \(agree)")
        
        // ✅ Vérifier que l'utilisateur est authentifié
        guard TokenManager.shared.isLoggedIn() else {
            print("❌ Utilisateur non authentifié")
            showLoginAlert = true
            return
        }
        
        // ✅ Afficher les informations de l'utilisateur connecté
        if let userName = TokenManager.shared.getUserName() {
            print("👤 Utilisateur connecté: \(userName)")
        }
        if let userEmail = TokenManager.shared.getUserEmail() {
            print("📧 Email: \(userEmail)")
        }
        
        if isValid {
            print("✅ Validation OK, création du DTO...")
            print("🔍 DEBUG - Données du formulaire:")
            print("   commandeConcernee: \(commandeConcernee)")
            print("   complaintType: \(complaintType)")
            print("   description: \(description)")
            print("   selectedPhotos count: \(selectedPhotos.count)")
            
            // ✅ Le backend récupère automatiquement nomClient et emailClient du token JWT
            // Backend expects 'photos' as array of base64 strings
            // Convert UIImage to base64 strings
            let photos: [String]? = selectedPhotos.isEmpty ? nil : selectedPhotos.compactMap { image in
                // Convert UIImage to JPEG data with compression
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    print("❌ Erreur: Impossible de convertir l'image en JPEG")
                    return nil
                }
                // Convert to base64 string
                let base64String = imageData.base64EncodedString()
                print("📸 Photo convertie en base64 - Taille: \(base64String.count) caractères")
                return base64String
            }
            
            print("📸 Nombre de photos converties: \(photos?.count ?? 0)")
            
            let dto = ReclamationDTO(
                commandeConcernee: commandeConcernee,
                complaintType: complaintType,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                photos: photos
            )
            
            print("🔍 DEBUG - DTO créé:")
            print("   commandeConcernee: \(dto.commandeConcernee)")
            print("   complaintType: \(dto.complaintType)")
            print("   description: \(dto.description)")
            print("   photos: \(dto.photos?.description ?? "nil")")
            
            print("📦 DTO créé avec succès (sans nomClient/emailClient - récupérés du token)")
            print("🚀 Appel de l'API avec authentification...")
            
            ReclamationAPI.shared.createReclamation(dto) { result in
                print("📥 Réponse de l'API reçue")
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        print("✅ SUCCÈS - Réclamation enregistrée")
                        toastMessage = "Réclamation créée avec succès!"
                        showToast = true
                        clearForm()
                    case .failure(let error):
                        print("❌ ERREUR - \(error.localizedDescription)")
                        
                        // Gérer les erreurs d'authentification
                        if (error as NSError).code == 401 {
                            showLoginAlert = true
                        } else {
                            toastMessage = "Erreur: \(error.localizedDescription)"
                            showToast = true
                        }
                    }
                }
            }
        } else {
            print("❌ Validation échouée - Formulaire incomplet")
        }
    }
    
    private func clearForm() {
        print("🧹 Nettoyage du formulaire...")
        commandeConcernee = ""
        complaintType = ""
        description = ""
        selectedPhotos = []
        photoPickerItems = []
        agree = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
            print("🔔 Toast masqué")
        }
    }
}

// Note: BrandColors, FieldLabel, DropdownField, DescriptionField,
// PhotosSection et ToastView sont définis dans ReclamationComponents.swift
