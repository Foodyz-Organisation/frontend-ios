import Foundation

// MARK: - Menu Suggestions DTO
struct MenuSuggestionsDto: Codable {
    let bestCombination: SuggestionCombination
    let popularChoice: SuggestionCombination
    let reasoning: String
}

// MARK: - Suggestion Combination
struct SuggestionCombination: Codable {
    let ingredients: [String]
    let options: [String]
    let description: String
}

