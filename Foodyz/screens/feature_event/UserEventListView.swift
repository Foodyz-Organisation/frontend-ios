import SwiftUI

struct UserEventListView: View {
    @State private var selectedEvent: Event?
    @State private var showingEventDetail = false
    @EnvironmentObject private var eventManager: EventManager
    
    var body: some View {
        ZStack {
            BrandColors.Cream100.ignoresSafeArea()
            
            if eventManager.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let errorMessage = eventManager.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Erreur")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(BrandColors.TextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Réessayer") {
                        eventManager.loadEvents()
                    }
                    .padding()
                    .background(BrandColors.Yellow)
                    .foregroundColor(BrandColors.TextPrimary)
                    .cornerRadius(12)
                }
                .padding(32)
            } else if eventManager.events.isEmpty {
                EmptyUserState()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(eventManager.events) { event in
                            UserEventCard(
                                event: event,
                                onTap: {
                                    selectedEvent = event
                                    showingEventDetail = true
                                }
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .onAppear {
            // Recharger les événements à chaque apparition de la vue
            if eventManager.events.isEmpty {
                eventManager.loadEvents()
            }
        }
        .refreshable {
            // Permettre le pull-to-refresh
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                eventManager.loadEvents {
                    continuation.resume()
                }
            }
        }
        .navigationTitle("Événements")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEvent) { event in
            NavigationView {
                UserEventDetailView(
                    event: event,
                    onBackClick: {
                        showingEventDetail = false
                        selectedEvent = nil
                    }
                )
            }
        }
    }
}

struct UserEventCard: View {
    let event: Event
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            if let imageUrl = event.image, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 180)
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
                .frame(height: 180)
                .frame(maxWidth: .infinity)
            }
            
            // Contenu
            VStack(alignment: .leading, spacing: 12) {
                // Statut
                EventStatusBadge(status: event.statut)
                
                // Titre
                Text(event.nom)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(BrandColors.TextPrimary)
                    .lineLimit(2)
                
                // Description
                Text(event.description)
                    .font(.body)
                    .foregroundColor(BrandColors.TextSecondary)
                    .lineLimit(2)
                
                Divider()
                    .background(BrandColors.Cream200)
                
                // Informations
                EventInfoRow(icon: "calendar", text: event.dateDebut)
                EventInfoRow(icon: "mappin.and.ellipse", text: event.lieu)
                EventInfoRow(icon: "star", text: event.categorie)
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}

struct EmptyUserState: View {
    var body: some View {
        VStack {
            Image(systemName: "calendar")
                .font(.largeTitle)
                .foregroundColor(BrandColors.TextSecondary.opacity(0.3))
                .padding(.bottom, 16)
            
            Text("Aucun événement")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(BrandColors.TextPrimary)
                .padding(.bottom, 4)
            
            Text("Aucun événement disponible pour le moment")
                .font(.body)
                .foregroundColor(BrandColors.TextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

#Preview {
    UserEventListView()
        .environmentObject(EventManager())
}

