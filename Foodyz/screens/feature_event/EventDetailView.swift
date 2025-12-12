import SwiftUI

struct EventDetailView: View {
    let event: Event
    let onBackClick: () -> Void
    let onEditClick: () -> Void
    let onDeleteClick: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Image d'en-tête
                if let imageUrl = event.image, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .clipped()
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [BrandColors.Yellow, BrandColors.YellowPressed],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        Image(systemName: "calendar")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                }
                
                // Contenu
                VStack(spacing: 20) {
                    // Statut
                    EventStatusBadge(status: event.statut)
                    
                    // Titre
                    Text(event.nom)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(BrandColors.TextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Description
                    Text(event.description)
                        .font(.body)
                        .foregroundColor(BrandColors.TextSecondary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                        .background(BrandColors.Cream200)
                    
                    // Informations détaillées
                    DetailInfoCard(icon: "calendar", title: "Date de début", value: event.dateDebut)
                    DetailInfoCard(icon: "calendar", title: "Date de fin", value: event.dateFin)
                    DetailInfoCard(icon: "mappin.and.ellipse", title: "Lieu", value: event.lieu)
                    DetailInfoCard(icon: "star", title: "Catégorie", value: event.categorie)
                    DetailInfoCard(icon: "info.circle", title: "Statut", value: event.statut.rawValue)
                }
                .padding(24)
            }
        }
        .background(Color.white)
        .navigationTitle("Détails de l'événement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Retour") {
                    onBackClick()
                }
                .foregroundColor(BrandColors.TextPrimary)
            }
        }
    }
}

struct DetailInfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(BrandColors.Yellow)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(BrandColors.TextSecondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(BrandColors.TextPrimary)
            }
            
            Spacer()
        }
        .padding()
        .background(BrandColors.Cream100)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        EventDetailView(
            event: Event.sampleEvents[0],
            onBackClick: {},
            onEditClick: {},
            onDeleteClick: {}
        )
    }
}
