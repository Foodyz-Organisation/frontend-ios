import Foundation
import Combine

// MARK: - Professional Profile ViewModel
@MainActor
class ProfessionalProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var professional: ProfessionalDto?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Dependencies
    private let repository: ProfessionalRepository
    
    // MARK: - Initialization
    init(repository: ProfessionalRepository = .shared) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    func loadProfessional(id: String) {
        isLoading = true
        errorMessage = nil
        
        repository.getProfessionalById(id: id) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let professional):
                    self.professional = professional
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
