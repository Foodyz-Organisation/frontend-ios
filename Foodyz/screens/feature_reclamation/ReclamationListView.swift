import SwiftUI
import Combine

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
enum ReclamationStatus: Hashable {
    case pending
    case resolved
    case rejected
}

struct Reclamation: Identifiable {
    let id: String
    let orderNumber: String
    let complaintType: String
    let description: String
    let photoUrls: [String]  // Changed from [UIImage] to [String] to store URLs
    let status: ReclamationStatus
    let date: Date
    let response: String?

    init(
        id: String = UUID().uuidString,
        orderNumber: String,
        complaintType: String,
        description: String,
        photoUrls: [String] = [],
        status: ReclamationStatus,
        date: Date = Date(),
        response: String? = nil
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.complaintType = complaintType
        self.description = description
        self.photoUrls = photoUrls
        self.status = status
        self.date = date
        self.response = response
    }
}

// MARK: - Reclamation List View
struct ReclamationListView: View {
    @StateObject private var viewModel = ReclamationListViewModel()
    @Environment(\.dismiss) var dismiss
    
    var onBackClick: (() -> Void)? = nil

    var body: some View {
        ZStack {
            ReclamationBrandColors.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(ReclamationBrandColors.red)
                    Text(error)
                        .foregroundColor(ReclamationBrandColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Réessayer") {
                        Task {
                            await viewModel.loadReclamations()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.reclamations.isEmpty {
                ReclamationEmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.reclamations) { reclamation in
                            NavigationLink(destination: {
                                ReclamationDetailView(
                                    reclamation: reclamation,
                                    onBackClick: {
                                        // Navigation will handle back automatically
                                    }
                                )
                            }) {
                                ReclamationCardContent(reclamation: reclamation)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    await viewModel.loadReclamations()
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
                Button(action: {
                    if let onBackClick = onBackClick {
                        onBackClick()
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(ReclamationBrandColors.textPrimary)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadReclamations()
            }
        }
    }
}

// MARK: - Reclamation List ViewModel
@MainActor
class ReclamationListViewModel: ObservableObject {
    @Published var reclamations: [Reclamation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadReclamations() async {
        isLoading = true
        errorMessage = nil
        
        ReclamationAPI.shared.getMyReclamations { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let reclamationDTOs):
                    print("✅ \(reclamationDTOs.count) réclamation(s) chargée(s)")
                    // Convert ReclamationResponseDTO to Reclamation
                    self.reclamations = reclamationDTOs.map { dto in
                        // Map status from backend string to ReclamationStatus
                        let status: ReclamationStatus = {
                            switch dto.statut.lowercased() {
                            case "resolue", "résolue":
                                return .resolved
                            case "rejetee", "rejetée":
                                return .rejected
                            case "en_attente", "en_cours":
                                return .pending
                            default:
                                return .pending
                            }
                        }()
                        
                        // Parse date from ISO string
                        let dateFormatter = ISO8601DateFormatter()
                        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        let date = dateFormatter.date(from: dto.createdAt) ?? Date()
                        
                        // Build full photo URLs from backend paths
                        let baseURL = AppAPIConstants.baseURL
                        let photoUrls = (dto.photos ?? []).map { photoPath in
                            // If path already starts with http, use it as is, otherwise prepend base URL
                            if photoPath.hasPrefix("http") {
                                return photoPath
                            } else {
                                // Remove leading slash if present and construct full URL
                                let cleanPath = photoPath.hasPrefix("/") ? String(photoPath.dropFirst()) : photoPath
                                return "\(baseURL)/\(cleanPath)"
                            }
                        }
                        
                        return Reclamation(
                            id: dto._id,
                            orderNumber: "Commande #\(dto.commandeConcernee.prefix(8))",
                            complaintType: dto.complaintType,
                            description: dto.description,
                            photoUrls: photoUrls,
                            status: status,
                            date: date,
                            response: dto.responseMessage
                        )
                    }
                    
                case .failure(let error):
                    print("❌ Erreur de chargement: \(error.localizedDescription)")
                    self.errorMessage = "Impossible de charger les réclamations. \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Empty State
struct ReclamationEmptyStateView: View {
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

// MARK: - Reclamation Card Content (for NavigationLink)
struct ReclamationCardContent: View {
    let reclamation: Reclamation

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }

    var body: some View {
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
}

// MARK: - Reclamation Card (with Button for backward compatibility)
struct ReclamationCard: View {
    let reclamation: Reclamation
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            ReclamationCardContent(reclamation: reclamation)
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
        ReclamationListView()
    }
}
