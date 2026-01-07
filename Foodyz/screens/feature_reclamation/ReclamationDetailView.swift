import SwiftUI
import UIKit

// MARK: - Reclamation Detail View
struct ReclamationDetailView: View {
    let reclamation: Reclamation
    var onBackClick: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy 'à' HH:mm"
        formatter.locale = Locale(identifier: "fr_FR")
        // Échapper le caractère 'à' correctement
        return formatter
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        let dateStr = formatter.string(from: date)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeStr = timeFormatter.string(from: date)
        return "\(dateStr) à \(timeStr)"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Card
                StatusCard(
                    status: reclamation.status,
                    date: formatDate(reclamation.date),
                    orderNumber: reclamation.orderNumber
                )
                
                // Complaint Type
                SectionLabel(text: "Type de réclamation")
                InfoCard(content: reclamation.complaintType)
                
                // Description
                SectionLabel(text: "Description")
                InfoCard(content: reclamation.description)
                
                // Photos
                if !reclamation.photoUrls.isEmpty {
                    SectionLabel(text: "Photos (\(reclamation.photoUrls.count))")
                    PhotosGrid(photoUrls: reclamation.photoUrls)
                } else {
                    // Debug: Afficher si aucune photo n'est disponible
                    SectionLabel(text: "Photos")
                    Text("Aucune photo disponible")
                        .foregroundColor(ReclamationBrandColors.textSecondary)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .onAppear {
                            print("⚠️ Aucune photo dans la réclamation")
                            print("⚠️ photoUrls vide: \(reclamation.photoUrls)")
                        }
                }
                
                // Response
                if let response = reclamation.response {
                    SectionLabel(text: "Réponse")
                    ResponseCard(response: response)
                }
                
                Spacer(minLength: 20)
            }
            .padding(24)
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Détails Réclamation")
                    .foregroundColor(ReclamationBrandColors.textPrimary)
                    .fontWeight(.semibold)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(ReclamationBrandColors.textPrimary)
                }
            }
        }
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let status: ReclamationStatus
    let date: String
    let orderNumber: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Statut")
                    .fontWeight(.semibold)
                    .foregroundColor(ReclamationBrandColors.textPrimary)
                
                Spacer()
                
                StatusBadge(status: status)
            }
            
            Divider()
                .background(ReclamationBrandColors.textSecondary.opacity(0.1))
            
            DetailRow(label: "Date", value: date)
            DetailRow(label: "Commande", value: orderNumber)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

// MARK: - Section Label
struct SectionLabel: View {
    let text: String
    
    var body: some View {
        HStack {
            Text(text)
                .fontWeight(.semibold)
                .foregroundColor(ReclamationBrandColors.textPrimary)
                .font(.system(size: 16))
            Spacer()
        }
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let content: String
    
    var body: some View {
        Text(content)
            .foregroundColor(ReclamationBrandColors.textPrimary)
            .font(.system(size: 14))
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(ReclamationBrandColors.textSecondary)
                .font(.system(size: 14))
            
            Spacer()
            
            Text(value)
                .foregroundColor(ReclamationBrandColors.textPrimary)
                .font(.system(size: 14, weight: .medium))
        }
    }
}

// MARK: - Photos Grid
struct PhotosGrid: View {
    let photoUrls: [String]
    
    var body: some View {
        VStack(spacing: 16) {
            if photoUrls.count == 1 {
                // Une seule image : affichage centré et large
                PhotoItemView(photoUrl: photoUrls[0], isSingle: true)
            } else {
                // Plusieurs images : grille adaptative
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
            ForEach(photoUrls, id: \.self) { photoUrl in
                        PhotoItemView(photoUrl: photoUrl, isSingle: false)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            print("📸 PhotosGrid affiché avec \(photoUrls.count) URL(s)")
            for (index, url) in photoUrls.enumerated() {
                print("📸 Photo \(index + 1): \(url)")
            }
        }
    }
}

// MARK: - Photo Item View
struct PhotoItemView: View {
    let photoUrl: String
    let isSingle: Bool
    @State private var imageData: Data?
    @State private var isLoading = true
    @State private var loadError: Error?
    
    init(photoUrl: String, isSingle: Bool = false) {
        self.photoUrl = photoUrl
        self.isSingle = isSingle
    }
    
    private var imageHeight: CGFloat {
        isSingle ? 300 : 200
    }
    
    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .onAppear {
                        print("✅ Photo affichée avec succès: \(photoUrl)")
                    }
            } else if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Chargement...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(height: imageHeight)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("Erreur de chargement")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(photoUrl)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .frame(height: imageHeight)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // Vérifier si c'est une URL valide
        guard let url = URL(string: photoUrl) else {
            // Si ce n'est pas une URL valide, vérifier si c'est du base64
            if photoUrl.hasPrefix("data:image") || photoUrl.count > 100 {
                // Probablement du base64
                loadBase64Image(photoUrl)
            } else {
                print("❌ URL invalide: \(photoUrl)")
                isLoading = false
                loadError = NSError(domain: "Invalid URL", code: -1, userInfo: nil)
            }
            return
        }
        
        // Charger l'image depuis l'URL
        print("📸 Chargement de l'image depuis: \(photoUrl)")
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Ajouter le token d'authentification si disponible
        if let accessToken = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("❌ Erreur de chargement de la photo: \(photoUrl)")
                    print("❌ Erreur: \(error.localizedDescription)")
                    loadError = error
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 Status Code pour \(photoUrl): \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode != 200 {
                        print("❌ Status code non-200: \(httpResponse.statusCode)")
                        loadError = NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)
                        return
                    }
                }
                
                guard let data = data else {
                    print("❌ Aucune donnée reçue pour: \(photoUrl)")
                    loadError = NSError(domain: "No data", code: -1, userInfo: nil)
                    return
                }
                
                print("✅ Données reçues: \(data.count) bytes pour \(photoUrl)")
                imageData = data
            }
        }.resume()
    }
    
    private func loadBase64Image(_ base64String: String) {
        print("📸 Tentative de chargement d'image base64")
        
        var base64Data = base64String
        
        // Retirer le préfixe data:image/...;base64, si présent
        if let range = base64Data.range(of: "base64,") {
            base64Data = String(base64Data[range.upperBound...])
        }
        
        guard let data = Data(base64Encoded: base64Data) else {
            print("❌ Impossible de décoder le base64")
            isLoading = false
            loadError = NSError(domain: "Base64 decode error", code: -1, userInfo: nil)
            return
        }
        
        DispatchQueue.main.async {
            isLoading = false
            imageData = data
            print("✅ Image base64 décodée avec succès: \(data.count) bytes")
        }
    }
}

// MARK: - Response Card
struct ResponseCard: View {
    let response: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(ReclamationBrandColors.yellow)
                    .font(.system(size: 20))
                
                Text("Réponse de l'équipe")
                    .fontWeight(.semibold)
                    .foregroundColor(ReclamationBrandColors.textPrimary)
                    .font(.system(size: 14))
            }
            
            Text(response)
                .foregroundColor(ReclamationBrandColors.textPrimary)
                .font(.system(size: 14))
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ReclamationBrandColors.yellow.opacity(0.1))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

// MARK: - Preview
struct ReclamationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview avec réponse
        ReclamationDetailView(
            reclamation: Reclamation(
                orderNumber: "Commande #12345",
                complaintType: "Late delivery",
                description: "Ma commande est arrivée avec 45 minutes de retard et les plats étaient complètement froids. J'ai essayé de contacter le livreur mais il ne répondait pas.",
                photoUrls: [],
                status: .resolved,
                date: Date(),
                response: "Nous sommes sincèrement désolés pour ce désagrément. Votre commande a été remboursée intégralement et nous avons pris des mesures avec notre partenaire de livraison."
            )
        )
        .previewDisplayName("Avec réponse")
        
        // Preview sans réponse
        ReclamationDetailView(
            reclamation: Reclamation(
                orderNumber: "Commande #12346",
                complaintType: "Missing item",
                description: "Il manquait une boisson dans ma commande.",
                photoUrls: [],
                status: .pending,
                date: Date()
            )
        )
        .previewDisplayName("Sans réponse")
    }
}

