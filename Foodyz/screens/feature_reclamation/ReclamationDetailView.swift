import SwiftUI

// MARK: - Reclamation Detail View
struct ReclamationDetailView: View {
    let reclamation: Reclamation
    var onBackClick: () -> Void = {}
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy 'à' HH:mm"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Card
                    StatusCard(
                        status: reclamation.status,
                        date: dateFormatter.string(from: reclamation.date),
                        orderNumber: reclamation.orderNumber
                    )
                    
                    // Complaint Type
                    SectionLabel(text: "Type de réclamation")
                    InfoCard(content: reclamation.complaintType)
                    
                    // Description
                    SectionLabel(text: "Description")
                    InfoCard(content: reclamation.description)
                    
                    // Photos
                    if !reclamation.photos.isEmpty {
                        SectionLabel(text: "Photos (\(reclamation.photos.count))")
                        PhotosGrid(photos: reclamation.photos)
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Détails Réclamation")
                        .foregroundColor(ReclamationBrandColors.textPrimary)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onBackClick) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(ReclamationBrandColors.textPrimary)
                    }
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
    let photos: [UIImage]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(photos.indices, id: \.self) { index in
                Image(uiImage: photos[index])
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
            }
        }
        .frame(maxHeight: 400)
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
                photos: [],
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
                photos: [],
                status: .pending,
                date: Date()
            )
        )
        .previewDisplayName("Sans réponse")
    }
}
