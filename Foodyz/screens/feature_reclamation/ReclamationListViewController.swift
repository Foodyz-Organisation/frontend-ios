import UIKit
import SwiftUI

class ReclamationListViewController: UIViewController {
    
    // MARK: - Properties
    private var reclamations: [ReclamationDTO] = []
    private var isLoading = false
    
    // MARK: - UI Components
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refresh
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        table.backgroundColor = UIColor(ReclamationBrandColors.background)
        table.register(ReclamationTableViewCell.self, forCellReuseIdentifier: "ReclamationCell")
        table.refreshControl = refreshControl
        return table
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = UIColor(ReclamationBrandColors.textSecondary)
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Aucune réclamation"
        label.textColor = UIColor(ReclamationBrandColors.textSecondary)
        label.font = .systemFont(ofSize: 16)
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            imageView.widthAnchor.constraint(equalToConstant: 64),
            imageView.heightAnchor.constraint(equalToConstant: 64),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        return view
    }()
    
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
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: view.widthAnchor),
            emptyStateView.heightAnchor.constraint(equalToConstant: 200),
            
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
    
    // MARK: - Helper Methods
    private func statusColor(for complaintType: String) -> UIColor {
        // Vous pouvez adapter cette logique selon vos besoins
        return UIColor(ReclamationBrandColors.orange)
    }
    
    private func statusIcon(for complaintType: String) -> String {
        return "clock.fill"
    }
    
    private func statusText(for complaintType: String) -> String {
        return "En attente"
    }
}

// MARK: - UITableViewDataSource
extension ReclamationListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reclamations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReclamationCell", for: indexPath) as? ReclamationTableViewCell else {
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
        let reclamation = reclamations[indexPath.row]
        
        // Navigation vers les détails (SwiftUI)
        let detailView = ReclamationDetailView(
            reclamation: Reclamation(
                orderNumber: "Commande \(reclamation.commandeConcernee)",
                complaintType: reclamation.complaintType,
                description: reclamation.description,
                photos: [], // Vous pouvez ajouter la conversion d'images si nécessaire
                status: .pending, // Adapter selon votre logique
                date: Date(),
                response: nil
            )
        ) {
            // Action de retour
        }
        
        let hostingController = UIHostingController(rootView: detailView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
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
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 2
        return view
    }()
    
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
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
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
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with reclamation: ReclamationDTO) {
        orderNumberLabel.text = "Commande \(reclamation.commandeConcernee)"
        complaintTypeLabel.text = reclamation.complaintType
        descriptionLabel.text = reclamation.description
        
        // Configuration du badge de statut (En attente par défaut)
        let statusColor = UIColor(ReclamationBrandColors.orange)
        statusBadgeView.backgroundColor = statusColor.withAlphaComponent(0.1)
        statusIconImageView.image = UIImage(systemName: "clock.fill")
        statusIconImageView.tintColor = statusColor
        statusLabel.textColor = statusColor
        statusLabel.text = "En attente"
    }
}
