import Foundation

/// Bad Words Filter - Moderates text by replacing inappropriate words with asterisks
/// Supports both French and English profanity
class BadWordsFilter {
    // Shared instance (singleton)
    static let shared = BadWordsFilter()
    
    // Private word list
    private let badWords: Set<String> = [
        // French profanity
        "merde", "putain", "connard", "salaud", "salope", "enculé", "enculer",
        "connasse", "con", "conne", "bordel", "chier", "foutre", "bite", "couille",
        "pute", "batard", "bâtard", "niquer", "nique", "pd", "fdp", "ntm",
        // English profanity
        "fuck", "shit", "bitch", "ass", "asshole", "bastard", "dick", "pussy",
        "damn", "hell", "crap", "piss", "cock", "tits", "slut", "whore"
    ]
    
    // Pre-compiled regex pattern (more efficient)
    private lazy var combinedPattern: NSRegularExpression? = {
        // Create pattern: \b(word1|word2|word3)\b
        let escapedWords = badWords.map { NSRegularExpression.escapedPattern(for: $0) }
        let pattern = "\\b(\(escapedWords.joined(separator: "|")))\\b"
        
        do {
            return try NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            )
        } catch {
            print("❌ BadWordsFilter: Failed to create regex: \(error.localizedDescription)")
            return nil
        }
    }()
    
    private init() {} // Private initializer for singleton
    
    /**
     * Moderates text by replacing bad words with asterisks
     * - Parameter text: The text to moderate
     * - Returns: Moderated text with bad words replaced by asterisks
     * 
     * Example:
     * - Input: "Hey, that's fucked up!"
     * - Output: "Hey, that's ****** up!"
     */
    func moderate(_ text: String) -> String {
        guard let regex = combinedPattern else {
            return text // Return original if regex failed
        }
        
        let range = NSRange(text.startIndex..., in: text)
        var moderatedText = text
        
        // Find all matches
        let matches = regex.matches(in: text, range: range)
        
        // Replace in reverse order to maintain correct indices
        for match in matches.reversed() {
            if let range = Range(match.range, in: moderatedText) {
                let matchedWord = String(moderatedText[range])
                let asterisks = String(repeating: "*", count: matchedWord.count)
                moderatedText.replaceSubrange(range, with: asterisks)
            }
        }
        
        return moderatedText
    }
}

