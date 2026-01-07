import Foundation
import Combine
// No extra import needed if in same module

// MARK: - Professional Profile ViewModel
@MainActor
class ProfessionalProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var professional: ProfessionalDto?
    @Published var videoPosts: [Post] = []
    @Published var imagePosts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Dependencies
    private let repository: ProfessionalRepository
    
    // MARK: - Initialization
    init(repository: ProfessionalRepository = .shared) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    // MARK: - Legacy Support (renamed from loadProfessional to loadData to match duplicated viewmodel usage)
    func loadData(professionalId: String) async {
        isLoading = true
        errorMessage = nil
        
        await fetchProfile(id: professionalId)
        await loadProfessionalPosts(professionalId: professionalId)
        
        isLoading = false
    }

    func loadProfessional(id: String) {
        Task {
            await loadData(professionalId: id)
        }
    }
    
    // Converted to async for compatibility
    private func fetchProfile(id: String) async {
         return await withCheckedContinuation { continuation in
            repository.getProfessionalById(id: id) { [weak self] result in
                 Task { @MainActor in
                     guard let self = self else { return }
                     switch result {
                     case .success(let professional):
                         self.professional = professional
                     case .failure(let error):
                         self.errorMessage = error.localizedDescription
                     }
                     continuation.resume()
                 }
            }
        }
    }
    
    private func loadProfessionalPosts(professionalId: String) async {
        do {
            let fetchedPosts = try await PostsAPI.shared.getAllPosts()
            // Filter posts by ownerId
            let myPosts = fetchedPosts.filter { $0.ownerId == professionalId }
            
            DispatchQueue.main.async {
                self.videoPosts = myPosts.filter { $0.isVideo }
                self.imagePosts = myPosts.filter { !$0.isVideo }
            }
        } catch {
            print("Error loading posts: \(error)")
            // Optionally set error message here if critical
        }
    }
}
