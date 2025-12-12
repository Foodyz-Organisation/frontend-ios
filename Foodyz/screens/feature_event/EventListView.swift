import SwiftUI

struct EventListView: View {
    @State private var showingCreateEvent = false
    @State private var selectedEvent: Event?
    @State private var showingEventDetail = false
    @State private var eventToEdit: Event?
    @State private var showingEditEvent = false
    @State private var eventToDelete: Event?
    @State private var showingDeleteConfirmation = false
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
                EmptyState(onAddClick: { showingCreateEvent = true })
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(eventManager.events) { event in
                            EventCard(
                                event: event,
                                onTap: {
                                    selectedEvent = event
                                    showingEventDetail = true
                                },
                                onEdit: {
                                    eventToEdit = event
                                    showingEditEvent = true
                                },
                                onDelete: {
                                    eventToDelete = event
                                    showingDeleteConfirmation = true
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateEvent = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(BrandColors.TextPrimary)
                }
            }
        }
        .sheet(isPresented: $showingCreateEvent) {
            NavigationView {
                CreateEventView { newEvent in
                    eventManager.addEvent(newEvent)
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            NavigationView {
                EventDetailView(
                    event: event,
                    onBackClick: {
                        showingEventDetail = false
                        selectedEvent = nil
                    },
                    onEditClick: {
                        eventToEdit = event
                        showingEditEvent = true
                        selectedEvent = nil
                    },
                    onDeleteClick: {
                        eventToDelete = event
                        showingDeleteConfirmation = true
                        selectedEvent = nil
                    }
                )
            }
        }
        .sheet(item: $eventToEdit) { event in
            NavigationView {
                EditEventView(event: event) { updatedEvent in
                    eventManager.updateEvent(updatedEvent)
                    eventToEdit = nil
                }
            }
        }
        .alert("Supprimer l'événement", isPresented: $showingDeleteConfirmation) {
            Button("Annuler", role: .cancel) {
                eventToDelete = nil
            }
            Button("Supprimer", role: .destructive) {
                if let event = eventToDelete {
                    eventManager.deleteEvent(event)
                }
                eventToDelete = nil
            }
        } message: {
            if let event = eventToDelete {
                Text("Êtes-vous sûr de vouloir supprimer \"\(event.nom)\" ? Cette action est irréversible.")
            }
        }
    }
}

struct EventCard: View {
    let event: Event
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image avec boutons d'action
            ZStack(alignment: .topTrailing) {
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
                
                // Boutons d'action
                HStack(spacing: 8) {
                    // Bouton modifier
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    // Bouton supprimer
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(12)
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

struct EventInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(BrandColors.TextSecondary)
                .frame(width: 18)
            
            Text(text)
                .font(.caption)
                .foregroundColor(BrandColors.TextSecondary)
            
            Spacer()
        }
    }
}

struct EventStatusBadge: View {
    let status: EventStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(status.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(status.color.opacity(0.15))
            .cornerRadius(8)
    }
}

struct EmptyState: View {
    let onAddClick: () -> Void
    
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
            
            Text("Créez votre premier événement")
                .font(.body)
                .foregroundColor(BrandColors.TextSecondary)
                .padding(.bottom, 24)
            
            Button(action: onAddClick) {
                HStack {
                    Image(systemName: "plus")
                    Text("Créer un événement")
                }
                .foregroundColor(BrandColors.TextPrimary)
                .padding()
                .background(BrandColors.Yellow)
                .cornerRadius(24)
            }
        }
        .padding(32)
    }
}

#Preview {
    EventListView()
        .environmentObject(EventManager())
}
