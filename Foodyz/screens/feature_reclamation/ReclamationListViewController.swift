import UIKit
import SwiftUI

// Assuming you have these models/constants defined elsewhere
// struct ReclamationResponseDTO: Codable { ... }
// enum ReclamationStatus { case resolved, rejected, pending }
// struct Reclamation { ... }
// struct ReclamationBrandColors { ... }
// class ReclamationAPI { static let shared = ReclamationAPI() ... }
// struct AppAPIConstants { static let baseURL = "..." }

class ReclamationListViewController: UIViewController {
    
    // MARK: - Properties
    private var reclamations: [ReclamationResponseDTO] = []
    private var isLoading = false
    
    // MARK: - UI Components
    
    // 🔄 Refresh Control
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refresh
    }()
    
    // 📋 Table View
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        // Use custom background color
        table.backgroundColor = UIColor(ReclamationBrandColors.background)
        table.register(ReclamationTableViewCell.self, forCellReuseIdentifier: "ReclamationCell")
        table.refreshControl = refreshControl
        return table
    }()
    
    // ❌ Empty State View
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        
        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle"))
        imageView.tintColor = UIColor(ReclamationBrandColors.textSecondary)
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 64).isActive = true
        
        let label = UILabel()
        label.text = "Aucune réclamation"
        label.textColor = UIColor(ReclamationBrandColors.textSecondary)
        label.font = .systemFont(ofSize: 16)
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        view.addSubview(stackView)
        
        // Center the stack view within the empty state container
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        return view
    }()
    
    // ⏳ Loading Indicator
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadReclamations()
        
        // Observer pour détecter la déconnexion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogout),
            name: NSNotification.Name("UserLoggedOut"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(ReclamationBrandColors.background)
        
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingIndicator)
        
        // --- CONSTRAINTS FIXES APPLIED HERE ---
        NSLayoutConstraint.activate([
            // 1. TableView: Pinning to ALL edges, respecting both top/bottom Safe Areas
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // FIX: Using safeAreaLayoutGuide.bottomAnchor for modern devices
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // 2. Empty State View: Should cover the entire Safe Area to appear centered correctly
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // 3. Loading Indicator: Centered in the middle of the whole view
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = "Mes Réclamations"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // Bouton retour personnalisé
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBack)
        )
        backButton.tintColor = UIColor(ReclamationBrandColors.textPrimary)
        navigationItem.leftBarButtonItem = backButton
    }
    
    // MARK: - Actions
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleRefresh() {
        loadReclamations()
    }
    
    @objc private func handleLogout() {
        // Retour à l'écran de connexion
        navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: - Data Loading
    private func loadReclamations() {
        guard !isLoading else { return }
        
        isLoading = true
        if !refreshControl.isRefreshing {
            loadingIndicator.startAnimating()
            tableView.isHidden = true
            emptyStateView.isHidden = true
        }
        
        print("🔄 Chargement des réclamations de l'utilisateur...")
        
        // ✅ Appel de la nouvelle méthode getMyReclamations
        ReclamationAPI.shared.getMyReclamations { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                self.loadingIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                
                switch result {
                case .success(let reclamations):
                    print("✅ \(reclamations.count) réclamation(s) chargée(s)")
                    self.reclamations = reclamations
                    self.updateUI()
                    
                case .failure(let error):
                    print("❌ Erreur de chargement: \(error.localizedDescription)")
                    self.showError(error)
                }
            }
        }
    }
    
    private func updateUI() {
        if reclamations.isEmpty {
            tableView.isHidden = true
            emptyStateView.isHidden = false
        } else {
            tableView.isHidden = false
            emptyStateView.isHidden = true
            tableView.reloadData()
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Erreur",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Réessayer", style: .default) { [weak self] _ in
            self?.loadReclamations()
        })
        
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ReclamationListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reclamations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReclamationCell", for: indexPath) as? ReclamationTableViewCell else {
            // Log a warning or assert if the cast fails in development
            return UITableViewCell()
        }
        
        let reclamation = reclamations[indexPath.row]
        cell.configure(with: reclamation)
        cell.selectionStyle = .none
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ReclamationListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let reclamationDTO = reclamations[indexPath.row]
        
        // Mapping Logic (Kept as is - it's fine)
        let status: ReclamationStatus = {
            switch reclamationDTO.statut.lowercased() {
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
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = dateFormatter.date(from: reclamationDTO.createdAt) ?? Date()
        
        let baseURL = AppAPIConstants.baseURL
        let photoUrls = (reclamationDTO.photos ?? []).compactMap { photoPath in
            // Logic for converting relative photo paths to full URLs (kept as is)
            if photoPath.hasPrefix("http://") || photoPath.hasPrefix("https://") {
                return photoPath
            }
            if photoPath.hasPrefix("data:image") || (photoPath.count > 100 && !photoPath.contains("/")) {
                return photoPath
            }
            
            var cleanPath = photoPath.hasPrefix("/") ? String(photoPath.dropFirst()) : photoPath
            
            if !cleanPath.contains("uploads") && !cleanPath.contains("reclamations") && !cleanPath.contains("photos") {
                let fullURL1 = "\(baseURL)/uploads/reclamations/\(cleanPath)"
                return fullURL1
            }
            
            let fullURL = "\(baseURL)/\(cleanPath)"
            return fullURL
        }
        
        // Navigation vers les détails (SwiftUI)
        let detailView = ReclamationDetailView(
            reclamation: Reclamation(
                id: reclamationDTO._id,
                orderNumber: "Commande #\(reclamationDTO.commandeConcernee.prefix(8))",
                complaintType: reclamationDTO.complaintType,
                description: reclamationDTO.description,
                photoUrls: photoUrls,
                status: status,
                date: date,
                response: reclamationDTO.responseMessage
            )
        ) {
            // Action de retour closure placeholder
        }
        
        let hostingController = UIHostingController(rootView: detailView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
    // Using automaticDimension is correct for dynamic cell heights
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
}

// MARK: - Custom Cell
class ReclamationTableViewCell: UITableViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        // Keep the shadow light for a subtle effect
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 2
        return view
    }()
    
    // ... (Other UI components setup is kept as is) ...
    private let orderIconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "cart.fill"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = UIColor(ReclamationBrandColors.yellow)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let orderNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor(ReclamationBrandColors.textPrimary)
        return label
    }()
    
    private let statusBadgeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let statusIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        return label
    }()
    
    private let complaintTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(ReclamationBrandColors.textPrimary)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(ReclamationBrandColors.textSecondary)
        label.numberOfLines = 2
        return label
    }()
    
    // MARK: - Initialization and Setup (Kept as is)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.addSubview(orderIconImageView)
        containerView.addSubview(orderNumberLabel)
        containerView.addSubview(statusBadgeView)
        statusBadgeView.addSubview(statusIconImageView)
        statusBadgeView.addSubview(statusLabel)
        containerView.addSubview(complaintTypeLabel)
        containerView.addSubview(descriptionLabel)
        
        // Constraints are robust and kept as is, using auto layout for dynamic sizing
        NSLayoutConstraint.activate([
            // Container View pins to contentView with 6pt padding top/bottom and 16pt left/right
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Layout of components inside the container (Kept as is)
            orderIconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            orderIconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            orderIconImageView.widthAnchor.constraint(equalToConstant: 20),
            orderIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            orderNumberLabel.centerYAnchor.constraint(equalTo: orderIconImageView.centerYAnchor),
            orderNumberLabel.leadingAnchor.constraint(equalTo: orderIconImageView.trailingAnchor, constant: 8),
            
            statusBadgeView.centerYAnchor.constraint(equalTo: orderIconImageView.centerYAnchor),
            statusBadgeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusBadgeView.heightAnchor.constraint(equalToConstant: 24),
            
            statusIconImageView.leadingAnchor.constraint(equalTo: statusBadgeView.leadingAnchor, constant: 10),
            statusIconImageView.centerYAnchor.constraint(equalTo: statusBadgeView.centerYAnchor),
            statusIconImageView.widthAnchor.constraint(equalToConstant: 14),
            statusIconImageView.heightAnchor.constraint(equalToConstant: 14),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusIconImageView.trailingAnchor, constant: 4),
            statusLabel.trailingAnchor.constraint(equalTo: statusBadgeView.trailingAnchor, constant: -10),
            statusLabel.centerYAnchor.constraint(equalTo: statusBadgeView.centerYAnchor),
            
            complaintTypeLabel.topAnchor.constraint(equalTo: orderIconImageView.bottomAnchor, constant: 12),
            complaintTypeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            complaintTypeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: complaintTypeLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            // Crucial for automaticDimension: pinning the description label's bottom to the container's bottom
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration (Kept as is)
    func configure(with reclamation: ReclamationResponseDTO) {
        orderNumberLabel.text = "Commande #\(reclamation.commandeConcernee.prefix(8))"
        complaintTypeLabel.text = reclamation.complaintType
        descriptionLabel.text = reclamation.description
        
        // Map status from backend string to UI
        let (statusColor, statusIcon, statusText): (UIColor, String, String) = {
            switch reclamation.statut.lowercased() {
            case "resolue", "résolue":
                return (UIColor(ReclamationBrandColors.green), "checkmark.circle.fill", "Résolue")
            case "rejetee", "rejetée":
                return (UIColor(ReclamationBrandColors.red), "xmark.circle.fill", "Rejetée")
            case "en_attente", "en_cours":
                return (UIColor(ReclamationBrandColors.orange), "clock.fill", "En attente")
            default:
                return (UIColor(ReclamationBrandColors.orange), "clock.fill", "En attente")
            }
        }()
        
        statusBadgeView.backgroundColor = statusColor.withAlphaComponent(0.1)
        statusIconImageView.image = UIImage(systemName: statusIcon)
        statusIconImageView.tintColor = statusColor
        statusLabel.textColor = statusColor
        statusLabel.text = statusText
    }
}
