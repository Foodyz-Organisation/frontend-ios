import SwiftUI

// MARK: - Main App with Navigation
struct ReclamationApp: View {
    @State private var selectedReclamation: Reclamation?
    @State private var showingDetail = false
    
    // Données d'exemple
    let reclamations = [
        Reclamation(
            orderNumber: "Commande #12345",
            complaintType: "Late delivery",
            description: "Ma commande est arrivée avec 45 minutes de retard et les plats étaient froids.",
            status: .pending,
            date: Date()
        ),
        Reclamation(
            orderNumber: "Commande #12344",
            complaintType: "Missing item",
            description: "Il manquait une boisson dans ma commande.",
            status: .resolved,
            date: Date().addingTimeInterval(-86400),
            response: "Nous vous avons remboursé la boisson manquante."
        ),
        Reclamation(
            orderNumber: "Commande #12343",
            complaintType: "Quality issue",
            description: "Le burger était mal cuit et les frites étaient molles.",
            status: .rejected,
            date: Date().addingTimeInterval(-172800)
        )
    ]
    
    var body: some View {
        NavigationStack {
            ReclamationListView(
                reclamations: reclamations
            ) { reclamation in
                selectedReclamation = reclamation
                showingDetail = true
            }
            .navigationDestination(isPresented: $showingDetail) {
                if let reclamation = selectedReclamation {
                    ReclamationDetailView(
                        reclamation: reclamation
                    ) {
                        showingDetail = false
                    }
                    .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
}

// MARK: - Updated List View (sans NavigationView interne)
struct ReclamationListViewUpdated: View {
    var reclamations: [Reclamation] = []
    var onReclamationClick: (Reclamation) -> Void = { _ in }
    var onBackClick: () -> Void = {}
    
    var body: some View {
        ZStack {
            ReclamationBrandColors.background.ignoresSafeArea()
            
            if reclamations.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(reclamations) { reclamation in
                            ReclamationCard(reclamation: reclamation) {
                                onReclamationClick(reclamation)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Mes Réclamations")
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
        .background(Color.white)
    }
}

// MARK: - Updated Detail View (sans NavigationView interne)
struct ReclamationDetailViewUpdated: View {
    let reclamation: Reclamation
    var onBackClick: () -> Void = {}
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy 'à' HH:mm"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }
    
    var body: some View {
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

// MARK: - Preview
struct ReclamationApp_Previews: PreviewProvider {
    static var previews: some View {
        ReclamationApp()
    }
}
