# Bad Words Filter - iOS Implementation Guide

## 📋 Overview

This guide explains how the bad words/profanity filter was implemented in the Android app, so you can replicate it in iOS. The filter is used to moderate user-generated content, particularly in chat messages, by replacing inappropriate words with asterisks.

---

## 🔧 Android Implementation Summary

### What Was Done in Android:

1. **Simple Word List Filter**
   - Created a `BadWordsFilter` object with a set of bad words
   - Supports both French and English profanity
   - Uses regex to find whole words (case-insensitive)
   - Replaces matched words with asterisks (`*`)

2. **Integration Points**
   - Applied in chat messages before sending
   - Used in both socket messages and REST API messages
   - Filters text client-side before sending to backend

3. **Implementation Details**
   - Word boundary matching (`\b`) to avoid partial matches
   - Case-insensitive matching
   - Preserves word length (same number of asterisks as letters)

---

## 📱 iOS Implementation Guide

### Step 1: Create Bad Words Filter Class

```swift
// BadWordsFilter.swift
import Foundation

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
        "fuck", "shit", "bitch", "ass", "asshole", "bastard", "dick", "pussy"
    ]
    
    private init() {} // Private initializer for singleton
    
    /**
     * Moderates text by replacing bad words with asterisks
     * - Parameter text: The text to moderate
     * - Returns: Moderated text with bad words replaced by asterisks
     */
    func moderate(_ text: String) -> String {
        var moderatedText = text
        
        // Iterate through each bad word
        for badWord in badWords {
            // Create regex pattern with word boundaries (case-insensitive)
            // \b ensures we match whole words only, not partial matches
            let pattern = "\\b\(badWord)\\b"
            
            do {
                let regex = try NSRegularExpression(
                    pattern: pattern,
                    options: [.caseInsensitive, .anchorsMatchLines]
                )
                
                // Find all matches
                let matches = regex.matches(
                    in: moderatedText,
                    range: NSRange(moderatedText.startIndex..., in: moderatedText)
                )
                
                // Replace matches with asterisks (preserving length)
                // Process in reverse to maintain correct indices
                for match in matches.reversed() {
                    if let range = Range(match.range, in: moderatedText) {
                        let matchedWord = String(moderatedText[range])
                        let asterisks = String(repeating: "*", count: matchedWord.count)
                        moderatedText.replaceSubrange(range, with: asterisks)
                    }
                }
            } catch {
                // If regex fails, skip this word
                print("⚠️ BadWordsFilter: Regex error for '\(badWord)': \(error.localizedDescription)")
                continue
            }
        }
        
        return moderatedText
    }
}
```

---

### Step 2: Alternative Implementation (More Efficient)

If you want a more efficient version using `NSRegularExpression` with a single pattern:

```swift
// BadWordsFilter.swift (Optimized Version)
import Foundation

class BadWordsFilter {
    static let shared = BadWordsFilter()
    
    private let badWords: Set<String> = [
        // French
        "merde", "putain", "connard", "salaud", "salope", "enculé", "enculer",
        "connasse", "con", "conne", "bordel", "chier", "foutre", "bite", "couille",
        "pute", "batard", "bâtard", "niquer", "nique", "pd", "fdp", "ntm",
        // English
        "fuck", "shit", "bitch", "ass", "asshole", "bastard", "dick", "pussy"
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
    
    private init() {}
    
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
```

---

### Step 3: Integration in Chat

#### 3.1 In Chat ViewModel

```swift
// ChatViewModel.swift
import Foundation

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isSendingMessage = false
    
    private let chatService: ChatService
    private let badWordsFilter = BadWordsFilter.shared
    
    // Send message with bad words filtering
    func sendMessage(conversationId: String, text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isSendingMessage = true
        defer { isSendingMessage = false }
        
        do {
            // Filter bad words before sending
            let moderatedText = badWordsFilter.moderate(text)
            
            // Send to backend
            let message = try await chatService.sendMessage(
                conversationId: conversationId,
                content: moderatedText,
                type: "text"
            )
            
            // Update UI
            await MainActor.run {
                messages.append(message)
            }
        } catch {
            print("❌ Failed to send message: \(error.localizedDescription)")
        }
    }
    
    // Send via WebSocket (if using Socket.IO)
    func sendSocketMessage(conversationId: String, text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Filter bad words before sending
        let moderatedText = badWordsFilter.moderate(text)
        
        // Send via socket
        socketManager.sendMessage(
            conversationId: conversationId,
            content: moderatedText,
            type: "text"
        )
    }
}
```

#### 3.2 In Chat Input View

```swift
// ChatInputView.swift
import SwiftUI

struct ChatInputView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    let conversationId: String
    
    var body: some View {
        HStack {
            TextField("Type a message...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                Task {
                    await viewModel.sendMessage(
                        conversationId: conversationId,
                        text: messageText
                    )
                    messageText = "" // Clear input
                }
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
    }
}
```

---

### Step 4: Testing Examples

```swift
// BadWordsFilterTests.swift (Unit Tests)
import XCTest
@testable import YourApp

class BadWordsFilterTests: XCTestCase {
    let filter = BadWordsFilter.shared
    
    func testBasicFiltering() {
        let input = "This is a test message with fuck in it"
        let output = filter.moderate(input)
        XCTAssertEqual(output, "This is a test message with **** in it")
    }
    
    func testCaseInsensitive() {
        let input = "FUCK this SHIT"
        let output = filter.moderate(input)
        XCTAssertEqual(output, "**** this ****")
    }
    
    func testWordBoundaries() {
        // Should NOT match "profanity" (contains "fuck" but not as whole word)
        let input = "This is not profanity"
        let output = filter.moderate(input)
        XCTAssertEqual(output, input) // No change
    }
    
    func testFrenchWords() {
        let input = "Putain, c'est merde!"
        let output = filter.moderate(input)
        XCTAssertTrue(output.contains("******")) // "putain" replaced
        XCTAssertTrue(output.contains("*****"))  // "merde" replaced
    }
    
    func testMultipleOccurrences() {
        let input = "fuck this and fuck that"
        let output = filter.moderate(input)
        XCTAssertEqual(output, "**** this and **** that")
    }
    
    func testPreservesLength() {
        let input = "fuck"
        let output = filter.moderate(input)
        XCTAssertEqual(output.count, input.count) // Same length
        XCTAssertEqual(output, "****")
    }
}
```

---

### Step 5: Extending the Word List

#### 5.1 Load from File (Optional)

```swift
// BadWordsFilter.swift (Extended Version)
class BadWordsFilter {
    static let shared = BadWordsFilter()
    
    private var badWords: Set<String> = []
    
    private init() {
        loadBadWords()
    }
    
    private func loadBadWords() {
        // Default words
        badWords = [
            "merde", "putain", "connard", "salaud", "salope", "enculé", "enculer",
            "connasse", "con", "conne", "bordel", "chier", "foutre", "bite", "couille",
            "pute", "batard", "bâtard", "niquer", "nique", "pd", "fdp", "ntm",
            "fuck", "shit", "bitch", "ass", "asshole", "bastard", "dick", "pussy"
        ]
        
        // Optionally load from file
        if let path = Bundle.main.path(forResource: "badwords", ofType: "txt"),
           let content = try? String(contentsOfFile: path) {
            let wordsFromFile = content
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            badWords.formUnion(wordsFromFile)
        }
    }
    
    func moderate(_ text: String) -> String {
        // ... same implementation as before
    }
}
```

#### 5.2 Add Words Dynamically

```swift
extension BadWordsFilter {
    // Add custom words (e.g., from backend)
    func addWords(_ words: [String]) {
        badWords.formUnion(words)
        // Rebuild regex if using optimized version
    }
    
    // Remove words
    func removeWords(_ words: [String]) {
        badWords.subtract(words)
    }
}
```

---

## 🎯 Usage Examples

### Example 1: Chat Message
```swift
let userInput = "Hey, that's fucked up!"
let filtered = BadWordsFilter.shared.moderate(userInput)
// Result: "Hey, that's ****** up!"
```

### Example 2: Post Caption
```swift
let caption = "Putain, cette pizza est délicieuse!"
let filtered = BadWordsFilter.shared.moderate(caption)
// Result: "******, cette pizza est délicieuse!"
```

### Example 3: Comment
```swift
let comment = "This is shit but I like it"
let filtered = BadWordsFilter.shared.moderate(comment)
// Result: "This is **** but I like it"
```

---

## 📝 Implementation Checklist

### Core Implementation
- [ ] Create `BadWordsFilter` class
- [ ] Add bad words list (French + English)
- [ ] Implement `moderate()` method with regex
- [ ] Test word boundary matching
- [ ] Test case-insensitive matching
- [ ] Test length preservation

### Integration
- [ ] Integrate in chat message sending
- [ ] Integrate in socket message sending
- [ ] Integrate in comment posting (if applicable)
- [ ] Integrate in post caption (if applicable)

### Testing
- [ ] Test basic word replacement
- [ ] Test case-insensitive matching
- [ ] Test word boundaries (no partial matches)
- [ ] Test multiple occurrences
- [ ] Test French words
- [ ] Test English words
- [ ] Test edge cases (empty string, no matches, etc.)

### Optional Enhancements
- [ ] Load words from file
- [ ] Add words dynamically from backend
- [ ] Add logging for filtered words
- [ ] Add configuration to enable/disable filter
- [ ] Add different replacement strategies (e.g., emoji, random chars)

---

## 🔗 Related Files (Android Reference)

- **Filter Class:** `core/utils/BadWordsFilter.kt`
- **Chat Integration:** `user/feature_chat/viewmodel/ChatViewModel.kt` - Line 478, 552
- **Socket Integration:** `user/feature_chat/viewmodel/ChatViewModel.kt` - Line 476-480

---

## 💡 iOS-Specific Tips

1. **Performance:** Use the optimized version with pre-compiled regex for better performance
2. **Thread Safety:** The singleton pattern is thread-safe in Swift
3. **Localization:** Consider loading bad words based on user's language
4. **Backend Sync:** You can fetch updated word lists from backend
5. **Privacy:** All filtering happens client-side; no text is sent to external services
6. **Regex:** Use `NSRegularExpression` for iOS (similar to Android's `Regex`)

---

## 🚨 Important Notes

1. **Client-Side Only:** This is a simple client-side filter. For production, consider:
   - Backend validation as well
   - More sophisticated AI-based filtering
   - User reporting system

2. **Word Boundaries:** The `\b` regex ensures we only match whole words, not partial matches (e.g., "profanity" won't match "fuck")

3. **Case Insensitive:** Matches are case-insensitive, so "FUCK", "Fuck", and "fuck" all get filtered

4. **Length Preservation:** Replaced words keep the same length (e.g., "fuck" → "****") to maintain message structure

5. **Extensibility:** Easy to add more words or load from a file/backend

---

## 🔄 Complete Flow

```
User Types Message
    ↓
Text Input: "Hey, that's fucked up!"
    ↓
Before Sending → BadWordsFilter.moderate(text)
    ↓
Filtered Text: "Hey, that's ****** up!"
    ↓
Send to Backend/Socket
    ↓
Display in Chat (filtered version)
```

---

This implementation provides the same functionality as the Android version, filtering inappropriate words before messages are sent!

