# AI Suggestions Feature - Implementation Summary for iOS

## 📋 Overview

The "Ask AI for Suggestions" feature uses **Google Gemini AI** (via backend) to provide intelligent menu item customization suggestions. The backend handles all AI processing; the frontend only needs to call the API and display results.

---

## 🔌 Backend API Integration

### 1. API Endpoint

```
GET /menu-items/{id}/suggestions
```

**Headers:**
- `Authorization: Bearer {token}`

**Path Parameters:**
- `id`: Menu item ID (String)

**Response (200 OK):**
```json
{
  "bestCombination": {
    "ingredients": ["tomato", "lettuce", "cheese"],
    "options": ["Extra sauce", "Double patty"],
    "description": "Double patty with Swiss cheese adds a distinct flavor that complements the fresh vegetables perfectly."
  },
  "popularChoice": {
    "ingredients": ["tomato", "onion"],
    "options": ["Classic sauce"],
    "description": "Classic Cheddar Burger with fresh vegetables is the most popular choice among customers."
  },
  "reasoning": "The Swiss cheese adds a distinct flavor that complements the fresh vegetables. This combination balances richness with freshness, making it a crowd favorite."
}
```

**Error Responses:**
- `401`: Unauthorized (invalid/missing token)
- `404`: Menu item not found
- `500`: Server error

---

## 📱 Frontend Implementation Flow

### Step 1: UI Button

**Location:** Menu Item Details Screen

**Button Design:**
- Text: "Ask AI for Suggestions" or "✨ Ask AI"
- Icon: Sparkle/AutoAwesome icon
- Color: Orange (#FF6B35)
- Style: Rounded corners, full width or prominent placement

**When to Show:**
- Always visible on the menu item details screen
- Can be placed below the item description, before customization options

---

### Step 2: State Management

**Required State Variables:**
```swift
// iOS Swift Example
@State private var showAISuggestions = false
@State private var aiSuggestions: MenuSuggestionsDto? = nil
@State private var isLoadingSuggestions = false
@State private var suggestionsError: String? = nil
```

**State Flow:**
1. User taps "Ask AI" button
2. Set `showAISuggestions = true`
3. Set `isLoadingSuggestions = true`
4. Call API
5. On success: Set `aiSuggestions` and `isLoadingSuggestions = false`
6. On error: Set `suggestionsError` and `isLoadingSuggestions = false`

---

### Step 3: API Call Implementation

**Network Service:**
```swift
// iOS Swift Example
func getMenuItemSuggestions(itemId: String, token: String) async throws -> MenuSuggestionsDto {
    let url = URL(string: "\(baseURL)/menu-items/\(itemId)/suggestions")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw APIError.invalidResponse
    }
    
    let decoder = JSONDecoder()
    return try decoder.decode(MenuSuggestionsDto.self, from: data)
}
```

**Data Models:**
```swift
// iOS Swift Example
struct MenuSuggestionsDto: Codable {
    let bestCombination: SuggestionCombination
    let popularChoice: SuggestionCombination
    let reasoning: String
}

struct SuggestionCombination: Codable {
    let ingredients: [String]
    let options: [String]
    let description: String
}
```

---

### Step 4: UI Dialog/Modal

**Display Options:**
- **Modal Dialog** (recommended): Full-screen or centered modal
- **Bottom Sheet**: Slide up from bottom (iOS native style)
- **Popover**: For iPad

**Dialog Components:**

1. **Header:**
   - Icon: Sparkle/AI icon
   - Title: "AI Suggestions"
   - Close button (X)

2. **Loading State:**
   - Spinner/Activity indicator
   - Text: "AI is analyzing ingredients..."

3. **Error State:**
   - Error icon
   - Error message
   - Retry button (optional)

4. **Success State:**
   - **Best Combination Card:**
     - Title: "Best Combination" with star icon
     - Gradient background (Orange: #FF6B35 → #FF8C42)
     - Description text
     - Ingredients list
     - Options list
   
   - **Popular Choice Card:**
     - Title: "Popular Choice" with trending icon
     - Gradient background (Teal: #4ECDC4 → #44A08D)
     - Description text
     - Ingredients list
     - Options list
   
   - **Reasoning Section:**
     - Title: "Why these suggestions?"
     - Reasoning text (explanation from AI)

---

## 🎨 UI Design Specifications

### Button Style
- **Background Color:** #FF6B35 (Orange)
- **Text Color:** White
- **Corner Radius:** 12dp
- **Padding:** 16dp horizontal, 12dp vertical
- **Icon Size:** 20dp
- **Font:** Semi-bold, 15sp

### Dialog Style
- **Background:** White
- **Corner Radius:** 24dp
- **Padding:** 24dp
- **Elevation/Shadow:** 8dp
- **Max Width:** 92% of screen width

### Card Style (Suggestions)
- **Best Combination:**
  - Gradient: #FF6B35 → #FF8C42
  - Text: White
  - Corner Radius: 16dp
  - Padding: 16dp

- **Popular Choice:**
  - Gradient: #4ECDC4 → #44A08D
  - Text: White
  - Corner Radius: 16dp
  - Padding: 16dp

### Typography
- **Title:** Bold, 22sp, Dark (#2D3142)
- **Card Title:** Bold, 15sp, White
- **Description:** Regular, 13sp, White (95% opacity)
- **Reasoning:** Regular, 12sp, Gray
- **Labels:** Semi-bold, 11sp

---

## 🔄 Complete Flow Diagram

```
User on Menu Item Details Screen
    ↓
Taps "Ask AI for Suggestions" Button
    ↓
Show Loading State (Spinner + "AI is analyzing...")
    ↓
API Call: GET /menu-items/{id}/suggestions
    ↓
    ├─ Success → Parse JSON → Display Suggestions Dialog
    │   ├─ Best Combination Card
    │   ├─ Popular Choice Card
    │   └─ Reasoning Section
    │
    └─ Error → Show Error Message
        └─ User can retry or dismiss
```

---

## 📝 Implementation Checklist for iOS

### Backend Integration
- [ ] Create API service method for `GET /menu-items/{id}/suggestions`
- [ ] Add authentication token to request headers
- [ ] Handle network errors (timeout, no connection, etc.)
- [ ] Parse JSON response into data models

### UI Components
- [ ] Add "Ask AI for Suggestions" button to menu item details screen
- [ ] Create modal/dialog component for displaying suggestions
- [ ] Implement loading state UI
- [ ] Implement error state UI
- [ ] Implement success state UI with cards

### State Management
- [ ] Add state variables for suggestions, loading, error
- [ ] Implement button tap handler
- [ ] Implement API call in async/await or completion handler
- [ ] Update UI based on state changes

### Data Models
- [ ] Create `MenuSuggestionsDto` struct/class
- [ ] Create `SuggestionCombination` struct/class
- [ ] Implement Codable/Decodable for JSON parsing

### Testing
- [ ] Test with valid menu item ID
- [ ] Test with invalid menu item ID (404 error)
- [ ] Test with expired token (401 error)
- [ ] Test network failure scenarios
- [ ] Test UI responsiveness and animations

---

## 🎯 Key Points

1. **Backend Does AI Processing:** Frontend only calls API and displays results
2. **No AI SDK Needed:** All Gemini AI logic is on backend
3. **Optional Feature:** User can view suggestions but doesn't have to apply them
4. **Real-time:** Suggestions are generated on-demand when user taps button
5. **Error Handling:** Always handle network errors gracefully

---

## 📚 Example Code Structure

```
Menu Item Details Screen
├── UI Components
│   ├── Item Image
│   ├── Item Name & Description
│   ├── "Ask AI for Suggestions" Button ← Trigger
│   └── Customization Options
│
└── AI Suggestions Dialog (Modal)
    ├── Header (Close button)
    ├── Loading State
    ├── Error State
    └── Success State
        ├── Best Combination Card
        ├── Popular Choice Card
        └── Reasoning Section
```

---

## 🔗 Related Files (Android Reference)

- **API Service:** `MenuItemApi.kt` - Line 67-73
- **Repository:** `MenuItemRepository.kt` - Line 190-216
- **Data Model:** `MenuSuggestionsDto.kt`
- **UI Dialog:** `AISuggestionsDialog.kt`
- **Integration:** `DynamicMenu.kt` - Line 654-875

---

## 💡 Tips for iOS Implementation

1. **Use SwiftUI Modals:** `.sheet()` or `.fullScreenCover()` for dialog
2. **Async/Await:** Use modern Swift concurrency for API calls
3. **Combine Framework:** Can use for reactive state management
4. **SF Symbols:** Use system icons (sparkles, star, trending up)
5. **Native Styling:** Match iOS design guidelines (HIG)
6. **Accessibility:** Add proper labels and hints for VoiceOver

---

This implementation is **backend-driven** - the frontend is just a client that displays the AI-generated suggestions. The actual AI processing happens on your backend using Google Gemini.

