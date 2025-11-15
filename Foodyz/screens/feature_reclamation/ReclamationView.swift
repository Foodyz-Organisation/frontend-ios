import SwiftUI
import PhotosUI

// MARK: - Main Reclamation View
struct ReclamationView: View {
    let restaurantNames: [String]
    let complaintTypes: [String]
    let commandeConcernees: [String]
    var onSubmit: (String, String, String, [UIImage]) -> Void = { _, _, _, _ in }
    
    @State private var restaurant = ""
    @State private var complaintType = ""
    @State private var commandeConcernee = ""
    @State private var description = ""
    @State private var agree = false
    @State private var selectedPhotos: [UIImage] = []
    @State private var showImagePicker = false
    @State private var showToast = false
    @State private var photoPickerItems: [PhotosPickerItem] = []
    
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Reclamation")
                        .foregroundColor(BrandColors.TextPrimary)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
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
        .overlay(ToastView(message: "Complaint submitted", isShowing: $showToast))
    }
    
    private func submitComplaint() {
        print("🔥🔥🔥 BOUTON SUBMIT CLIQUÉ 🔥🔥🔥")
        print("📋 isValid = \(isValid)")
        print("📋 complaintType = \(complaintType)")
        print("📋 description = \(description)")
        print("📋 commandeConcernee = \(commandeConcernee)")
        print("📋 agree = \(agree)")
        
        if isValid {
            print("✅ Validation OK, création du DTO...")
            
            let nomClient = "Ben Ghorbel"
            let emailClient = "john.doe@example.com"
            let imageURL = selectedPhotos.first != nil ? "https://example.com/photo.jpg" : nil
            
            print("👤 nomClient: \(nomClient)")
            print("📧 emailClient: \(emailClient)")
            
            let dto = ReclamationDTO(
                commandeConcernee: commandeConcernee,
                complaintType: complaintType,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                image: imageURL,
                nomClient: nomClient,
                emailClient: emailClient
            )
            
            print("📦 DTO créé avec succès")
            print("🚀 Appel de l'API...")
            
            ReclamationAPI.shared.createReclamation(dto) { result in
                print("📥 Réponse de l'API reçue")
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        print("✅ SUCCÈS - Réclamation enregistrée")
                        showToast = true
                        clearForm()
                    case .failure(let error):
                        print("❌ ERREUR - \(error.localizedDescription)")
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
