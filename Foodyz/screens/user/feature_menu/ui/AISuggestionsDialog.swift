import SwiftUI

// MARK: - AI Suggestions Dialog
struct AISuggestionsDialog: View {
    @Binding var isPresented: Bool
    let itemId: String
    @State private var suggestions: MenuSuggestionsDto?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Dialog content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(hexColor("FF6B35"))
                    
                    Text("AI Suggestions")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(hexColor("2D3142"))
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Content
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color(hex: "#FF6B35"))
                        Text("AI is analyzing ingredients...")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        // Error icon - different for quota errors
                        if error.lowercased().contains("quota") || error.lowercased().contains("exceeded") {
                            Image(systemName: "hourglass")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                        }
                        
                        Text(error.lowercased().contains("quota") || error.lowercased().contains("exceeded") ? "Service Temporarily Unavailable" : "Error")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(hexColor("2D3142"))
                        
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .lineSpacing(4)
                        
                        // Only show retry button if not a quota error
                        if !error.lowercased().contains("quota") && !error.lowercased().contains("exceeded") {
                            Button("Retry") {
                                loadSuggestions()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(hexColor("FF6B35"))
                            .cornerRadius(8)
                        } else {
                            // Show helpful message for quota errors
                            VStack(spacing: 8) {
                                Text("💡 Tip")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray)
                                Text("The AI service has reached its daily limit. Please try again tomorrow.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else if let suggestions = suggestions {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Best Combination Card
                            SuggestionCard(
                                title: "Best Combination",
                                icon: "star.fill",
                                combination: suggestions.bestCombination,
                                gradientColors: [hexColor("FF6B35"), hexColor("FF8C42")]
                            )
                            
                            // Popular Choice Card
                            SuggestionCard(
                                title: "Popular Choice",
                                icon: "chart.line.uptrend.xyaxis",
                                combination: suggestions.popularChoice,
                                gradientColors: [hexColor("4ECDC4"), hexColor("44A08D")]
                            )
                            
                            // Reasoning Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Why these suggestions?")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(hexColor("2D3142"))
                                
                                Text(suggestions.reasoning)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .lineSpacing(4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.85)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 16)
        }
        .onAppear {
            loadSuggestions()
        }
    }
    
    private func loadSuggestions() {
        isLoading = true
        errorMessage = nil
        
        guard let token = TokenManager.shared.getAccessToken() else {
            errorMessage = "Authentication required"
            isLoading = false
            return
        }
        
        Task {
            do {
                let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MenuSuggestionsDto, Error>) in
                    MenuItemApi.shared.getMenuItemSuggestions(itemId: itemId, token: token) { result in
                        switch result {
                        case .success(let suggestions):
                            continuation.resume(returning: suggestions)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                await MainActor.run {
                    // Check if the response contains error messages (backend returns 200 with error in body)
                    // Backend returns error structure when Gemini API quota is exceeded
                    if isErrorResponse(result) {
                        // Extract error message from response
                        let errorMsg = extractErrorFromResponse(result)
                        print("⚠️ [AISuggestionsDialog] Detected error in response: \(errorMsg)")
                        self.errorMessage = errorMsg
                        self.suggestions = nil
                    } else {
                        print("✅ [AISuggestionsDialog] Valid suggestions received")
                        self.suggestions = result
                        self.errorMessage = nil
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Parse error to show user-friendly message
                    self.errorMessage = parseErrorMessage(error)
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Check if Response Contains Error
    private func isErrorResponse(_ suggestions: MenuSuggestionsDto) -> Bool {
        // Backend returns error messages in the response body when quota is exceeded
        let bestDesc = suggestions.bestCombination.description.lowercased()
        let popularDesc = suggestions.popularChoice.description.lowercased()
        let reasoning = suggestions.reasoning.lowercased()
        
        // Check for error indicators (backend returns these when Gemini API fails)
        let errorIndicators = [
            "could not generate",
            "unavailable",
            "error occurred",
            "ai service unavailable",
            "please check api",
            "configuration"
        ]
        
        for indicator in errorIndicators {
            if bestDesc.contains(indicator) ||
               popularDesc.contains(indicator) ||
               reasoning.contains(indicator) {
                return true
            }
        }
        
        // Check if both combinations are empty AND descriptions are error messages (indicates error)
        let bothEmpty = suggestions.bestCombination.ingredients.isEmpty &&
                        suggestions.bestCombination.options.isEmpty &&
                        suggestions.popularChoice.ingredients.isEmpty &&
                        suggestions.popularChoice.options.isEmpty
        
        if bothEmpty && (bestDesc.contains("could not") || popularDesc.contains("could not")) {
            return true
        }
        
        return false
    }
    
    // MARK: - Extract Error from Response
    private func extractErrorFromResponse(_ suggestions: MenuSuggestionsDto) -> String {
        let reasoning = suggestions.reasoning.lowercased()
        let bestDesc = suggestions.bestCombination.description.lowercased()
        let popularDesc = suggestions.popularChoice.description.lowercased()
        
        // Combine all text to check for quota-related messages
        let allText = "\(reasoning) \(bestDesc) \(popularDesc)"
        
        // Check for quota-related messages (backend logs show "quota exceeded" in error)
        if allText.contains("quota") ||
           allText.contains("exceeded") ||
           allText.contains("limit") ||
           allText.contains("429") ||
           allText.contains("too many requests") {
            return "AI service quota exceeded. The daily free tier limit (20 requests) has been reached. Please try again tomorrow or upgrade your plan."
        }
        
        // Backend returns "Could not generate suggestion" + "An error occurred while contacting AI service"
        // when Gemini API quota is exceeded (based on backend error logs)
        // Since backend doesn't include quota info in response body, we infer it from the error pattern
        if (bestDesc.contains("could not generate") || popularDesc.contains("could not generate")) &&
           reasoning.contains("error occurred while contacting ai service") {
            // This pattern indicates quota exceeded (backend catches Gemini 429 and returns generic error)
            return "AI service quota exceeded. The daily free tier limit (20 requests) has been reached. Please try again tomorrow or upgrade your plan."
        }
        
        // Check for API configuration errors
        if reasoning.contains("api") && (reasoning.contains("configuration") || reasoning.contains("key")) {
            return "AI service configuration error. Please contact support."
        }
        
        // Check for service unavailable
        if bestDesc.contains("unavailable") || popularDesc.contains("unavailable") {
            return "AI service is temporarily unavailable. Please try again later."
        }
        
        // Default error message from backend
        if !suggestions.reasoning.isEmpty && 
           suggestions.reasoning != "An error occurred while contacting AI service." &&
           !suggestions.reasoning.contains("Could not parse") {
            return suggestions.reasoning
        }
        
        return "An error occurred while contacting AI service. Please try again later."
    }
    
    // MARK: - Parse Error Message
    private func parseErrorMessage(_ error: Error) -> String {
        // First check for APIError cases
        if let apiError = error as? APIError {
            switch apiError {
            case .badServerResponse(let statusCode):
                if statusCode == 429 {
                    return "AI service quota exceeded. The daily free tier limit (20 requests) has been reached. Please try again tomorrow or upgrade your plan."
                } else if statusCode == 500 {
                    // Check if it's actually a quota error in the error description
                    let errorDesc = apiError.localizedDescription.lowercased()
                    if errorDesc.contains("quota") || errorDesc.contains("exceeded") {
                        return "AI service quota exceeded. The daily free tier limit has been reached. Please try again tomorrow."
                    }
                    return "AI service is temporarily unavailable. Please try again later."
                } else {
                    return "Server error (Status: \(statusCode)). Please try again later."
                }
            case .networkError:
                return "Network error. Please check your internet connection and try again."
            case .unauthorized:
                return "Authentication required. Please log in again."
            case .badRequest:
                return "Invalid request. Please try again."
            default:
                // Check error description for quota-related messages
                let errorDesc = apiError.localizedDescription.lowercased()
                if errorDesc.contains("quota") || 
                   errorDesc.contains("429") || 
                   errorDesc.contains("exceeded") ||
                   errorDesc.contains("too many requests") {
                    return "AI service quota exceeded. The daily free tier limit has been reached. Please try again tomorrow."
                }
                return apiError.localizedDescription
            }
        }
        
        // Check error description for quota-related messages
        let errorString = error.localizedDescription.lowercased()
        let fullErrorDescription = String(describing: error).lowercased()
        
        if errorString.contains("quota") || 
           errorString.contains("429") || 
           errorString.contains("too many requests") ||
           errorString.contains("exceeded") ||
           fullErrorDescription.contains("quota") ||
           fullErrorDescription.contains("429") ||
           fullErrorDescription.contains("exceeded") {
            return "AI service quota exceeded. The daily free tier limit (20 requests) has been reached. Please try again tomorrow or upgrade your plan."
        }
        
        // Default error message
        return "An error occurred while contacting AI service. Please try again later."
    }
}

// MARK: - Suggestion Card
struct SuggestionCard: View {
    let title: String
    let icon: String
    let combination: SuggestionCombination
    let gradientColors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title with icon
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            
            // Description
            Text(combination.description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.95))
                .lineSpacing(4)
            
            // Ingredients
            if !combination.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ingredients")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack {
                        ForEach(combination.ingredients, id: \.self) { ingredient in
                            Text(ingredient)
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Options
            if !combination.options.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Options")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack {
                        ForEach(combination.options, id: \.self) { option in
                            Text(option)
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Color Helper
private func hexColor(_ hex: String) -> Color {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
        (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
        (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
        (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
        (a, r, g, b) = (255, 0, 0, 0)
    }
    return Color(
        .sRGB,
        red: Double(r) / 255,
        green: Double(g) / 255,
        blue: Double(b) / 255,
        opacity: Double(a) / 255
    )
}

