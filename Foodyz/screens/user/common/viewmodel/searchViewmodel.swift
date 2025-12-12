import Foundation
import Combine

// MARK: - Search ViewModel
@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchResults: [ProfessionalDto] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchText: String = "" {
        didSet {
            searchTextChanged()
        }
    }
    
    // MARK: - Dependencies
    private let repository: ProfessionalRepository
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(repository: ProfessionalRepository = .shared) {
        self.repository = repository
    }
    
    // MARK: - Private Methods
    private func searchTextChanged() {
        // Cancel previous search task
        searchTask?.cancel()
        
        // Clear results if search text is blank
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            clearSearch()
            return
        }
        
        // Debounce: wait 300ms before searching
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            guard !Task.isCancelled else { return }
            
            await performSearch(name: searchText)
        }
    }
    
    private func performSearch(name: String) async {
        isLoading = true
        errorMessage = nil
        
        repository.searchProfessionals(name: name) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let professionals):
                    self.searchResults = professionals
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.searchResults = []
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func clearSearch() {
        searchResults = []
        errorMessage = nil
        searchTask?.cancel()
    }
    
    func searchByName(_ name: String) {
        searchText = name
    }
}
