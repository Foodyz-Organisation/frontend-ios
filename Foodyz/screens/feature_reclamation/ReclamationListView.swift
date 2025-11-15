import SwiftUI

// MARK: - Brand Colors
struct ReclamationBrandColors {
    static let fieldFill = Color.white
    static let textPrimary = Color(red: 0.173, green: 0.184, blue: 0.212)
    static let textSecondary = Color(red: 0.424, green: 0.451, blue: 0.51)
    static let yellow = Color(red: 1.0, green: 0.835, blue: 0.31)
    static let amber = Color(red: 1.0, green: 0.702, blue: 0.0)
    static let green = Color(red: 0.298, green: 0.686, blue: 0.314)
    static let red = Color(red: 0.957, green: 0.263, blue: 0.212)
    static let orange = Color(red: 1.0, green: 0.596, blue: 0.0)
    static let background = Color(red: 0.98, green: 0.98, blue: 0.98)
}

// MARK: - Data Models
enum ReclamationStatus {
    case pending
    case resolved
    case rejected
}

struct Reclamation: Identifiable {
    let id: String
    let orderNumber: String
    let complaintType: String
    let description: String
    let photos: [UIImage]
    let status: ReclamationStatus
    let date: Date
    let response: String?

    init(
        id: String = UUID().uuidString,
        orderNumber: String,
        complaintType: String,
        description: String,
        photos: [UIImage] = [],
        status: ReclamationStatus,
        date: Date = Date(),
        response: String? = nil
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.complaintType = complaintType
        self.description = description
        self.photos = photos
        self.status = status
        self.date = date
        self.response = response
    }
}

// MARK: - Reclamation List View
struct ReclamationListView: View {
    var reclamations: [Reclamation] = []
    var onReclamationClick: (Reclamation) -> Void = { _ in }
    var onBackClick: () -> Void = {}

    var body: some View {
        NavigationView {
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
                                .frame(maxWidth: .infinity) // <- permet à la carte de prendre toute la largeur
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
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 64))
                .foregroundColor(ReclamationBrandColors.textSecondary)

            Text("Aucune réclamation")
                .foregroundColor(ReclamationBrandColors.textSecondary)
                .font(.system(size: 16))
        }
    }
}

// MARK: - Reclamation Card
struct ReclamationCard: View {
    let reclamation: Reclamation
    let onClick: () -> Void

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }

    var body: some View {
        Button(action: onClick) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                            .foregroundColor(ReclamationBrandColors.yellow)
                            .font(.system(size: 20))

                        Text(reclamation.orderNumber)
                            .fontWeight(.bold)
                            .foregroundColor(ReclamationBrandColors.textPrimary)
                            .font(.system(size: 16))
                    }

                    Spacer()

                    StatusBadge(status: reclamation.status)
                }

                Text(reclamation.complaintType)
                    .fontWeight(.semibold)
                    .foregroundColor(ReclamationBrandColors.textPrimary)
                    .font(.system(size: 14))

                Text(reclamation.description)
                    .foregroundColor(ReclamationBrandColors.textSecondary)
                    .font(.system(size: 13))
                    .lineLimit(2)

                Text(dateFormatter.string(from: reclamation.date))
                    .foregroundColor(ReclamationBrandColors.textSecondary)
                    .font(.system(size: 12))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ReclamationStatus

    private var statusInfo: (color: Color, icon: String, text: String) {
        switch status {
        case .pending:
            return (ReclamationBrandColors.orange, "clock.fill", "En attente")
        case .resolved:
            return (ReclamationBrandColors.green, "checkmark.circle.fill", "Résolue")
        case .rejected:
            return (ReclamationBrandColors.red, "xmark.circle.fill", "Rejetée")
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusInfo.icon)
                .foregroundColor(statusInfo.color)
                .font(.system(size: 14))

            Text(statusInfo.text)
                .foregroundColor(statusInfo.color)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusInfo.color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct ReclamationListView_Previews: PreviewProvider {
    static var previews: some View {
        ReclamationListView(
            reclamations: [
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
        ) { reclamation in
            print("Clicked: \(reclamation.orderNumber)")
        }
    }
}
