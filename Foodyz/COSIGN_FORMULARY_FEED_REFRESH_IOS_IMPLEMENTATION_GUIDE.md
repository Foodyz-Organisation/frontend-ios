# Cosign Formulary - Feed Refresh & Food Category Prioritization Guide

## 📋 Overview

The "Cosign Formulary" is a feed refresh mechanism that automatically prioritizes posts from the same food category when a user interacts with a post (likes it or accesses/clicks it). This creates a personalized feed experience where users see more content similar to what they've shown interest in.

---

## 🎯 Core Concept

**When a user interacts with a post:**
1. The interaction (like/access) is tracked by the backend
2. The backend learns the user's preference for that food category
3. The home feed refreshes
4. Posts from the same food category are prioritized and displayed first

---

## 🔄 Complete Flow

```
User on Home Feed
    ↓
User clicks on a post (or likes it)
    ↓
Post details screen opens (or like action completes)
    ↓
Backend tracks interaction:
    - Post ID
    - Food Category (foodType)
    - User ID (from x-user-id header)
    - Interaction type (view, like, comment, save)
    ↓
Backend updates user preferences automatically
    ↓
User navigates back to home feed
    ↓
Home feed refreshes automatically
    ↓
Backend returns personalized feed:
    - Posts from interacted food category appear first
    - Other posts follow
    ↓
User sees prioritized content based on their interactions
```

---

## 📱 Android Implementation

### 1. Backend Personalization (Automatic)

The backend automatically personalizes the feed based on user interactions. The `GET /posts` endpoint returns posts in priority order when the `x-user-id` header is present.

**API Endpoint**: `GET /posts`

**Headers**:
```
x-user-id: {currentUserId}
```

**Response**: List of posts ordered by:
1. Posts from food categories the user has interacted with (highest priority)
2. Other posts (lower priority)

**Note**: The backend learns preferences automatically from:
- Like actions (`PATCH /posts/{postId}/like`)
- View actions (when `GET /posts/{id}` is called)
- Comment actions (`POST /posts/{postId}/comments`)
- Save actions (`PATCH /posts/{postId}/save`)

### 2. Frontend Implementation

#### A. Post Interaction Tracking

**File**: `PostsHomeScreen.kt`

When a user clicks on a post:

```kotlin
onPostClick = { postId ->
    // Navigate to post details
    // Backend automatically tracks view when getPostById is called
    navController.navigate("${UserRoutes.POST_DETAILS_SCREEN}/$postId")
}
```

When a user likes a post:

```kotlin
onFavoriteClick = { postId ->
    // Like action tracked by backend
    postsViewModel.incrementLikeCount(post._id)
    // Backend automatically updates preferences
}
```

#### B. Feed Refresh on Return

**File**: `PostsHomeScreen.kt`

The feed should refresh when the user returns from post details:

```kotlin
@Composable
fun PostsScreen(
    navController: NavController,
    postsViewModel: PostsViewModel = viewModel(),
    // ... other params
) {
    val posts by postsViewModel.posts.collectAsState()
    
    // Refresh feed when returning from post details
    LaunchedEffect(navController.currentBackStackEntry) {
        val route = navController.currentBackStackEntry?.destination?.route
        if (route == UserRoutes.HOME_SCREEN) {
            // Refresh to get updated personalized feed
            postsViewModel.fetchPosts()
        }
    }
    
    // ... rest of UI
}
```

#### C. ViewModel Implementation

**File**: `PostsViewModel.kt`

```kotlin
open fun fetchPosts() {
    viewModelScope.launch {
        _isLoading.value = true
        _errorMessage.value = null
        try {
            // Backend returns personalized feed based on user interactions
            // Posts from interacted food categories appear first
            val fetchedPosts = postsApiService.getPosts()
            _posts.value = fetchedPosts
        } catch (e: Exception) {
            _errorMessage.value = "Failed to load posts: ${e.localizedMessage ?: e.message}"
        } finally {
            _isLoading.value = false
        }
    }
}
```

#### D. Interaction Tracking

**Like Action**:
```kotlin
open fun incrementLikeCount(postId: String) {
    viewModelScope.launch {
        try {
            // Backend tracks like and updates preferences
            val updatedPost = postsApiService.addLike(postId)
            _posts.update { currentPosts ->
                currentPosts.map { post ->
                    if (post._id == postId) updatedPost else post
                }
            }
            // Note: Backend automatically learns preference for this food category
        } catch (e: Exception) {
            _errorMessage.value = "Failed to like post: ${e.localizedMessage ?: e.message}"
        }
    }
}
```

**View Action** (automatic when fetching post details):
```kotlin
suspend fun getPostById(postId: String): PostResponse {
    // Backend automatically tracks view when x-user-id header is present
    return postsApiService.getPostById(postId)
}
```

---

## 🍎 iOS Implementation Guide

### Step 1: API Service

**File**: `PostsApiService.swift`

```swift
import Foundation

struct PostResponse: Codable {
    let _id: String
    let caption: String
    let mediaUrls: [String]
    let foodType: String?  // Food category
    let likeCount: Int
    let commentCount: Int
    let saveCount: Int
    let isLiked: Bool?
    let isSaved: Bool?
    let ownerId: OwnerDetails?
    let ownerModel: String?
    // ... other fields
}

struct OwnerDetails: Codable {
    let _id: String
    let fullName: String?
    let username: String?
    let profilePictureUrl: String?
}

class PostsApiService {
    private let baseURL: String = "YOUR_BASE_URL"
    private let session: URLSession
    private let tokenManager: TokenManager
    
    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let configuration = URLSessionConfiguration.default
        self.session = URLSession(configuration: configuration)
    }
    
    /// Fetch personalized feed (posts ordered by user preferences)
    func getPosts() async throws -> [PostResponse] {
        let url = URL(string: "\(baseURL)/posts")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add x-user-id header for personalization
        if let userId = tokenManager.getUserId() {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
        
        // Add authorization token
        if let token = tokenManager.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PostsApiService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to fetch posts"])
        }
        
        let decoder = JSONDecoder()
        let posts = try decoder.decode([PostResponse].self, from: data)
        
        // Posts are already ordered by backend:
        // 1. Posts from interacted food categories (first)
        // 2. Other posts (after)
        
        return posts
    }
    
    /// Get single post (automatically tracks view)
    func getPostById(_ postId: String) async throws -> PostResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add x-user-id header for view tracking
        if let userId = tokenManager.getUserId() {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
        
        // Add authorization token
        if let token = tokenManager.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PostsApiService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to fetch post"])
        }
        
        let decoder = JSONDecoder()
        let post = try decoder.decode(PostResponse.self, from: data)
        
        // Backend automatically tracks this view and updates preferences
        
        return post
    }
    
    /// Like a post (updates preferences automatically)
    func addLike(_ postId: String) async throws -> PostResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        
        // Add x-user-id header
        if let userId = tokenManager.getUserId() {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
        
        // Add authorization token
        if let token = tokenManager.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PostsApiService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to like post"])
        }
        
        let decoder = JSONDecoder()
        let updatedPost = try decoder.decode(PostResponse.self, from: data)
        
        // Backend automatically learns preference for this post's food category
        
        return updatedPost
    }
    
    /// Unlike a post
    func removeLike(_ postId: String) async throws -> PostResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Add headers
        if let userId = tokenManager.getUserId() {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
        if let token = tokenManager.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PostsApiService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to unlike post"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(PostResponse.self, from: data)
    }
}
```

### Step 2: ViewModel

**File**: `PostsViewModel.swift`

```swift
import SwiftUI
import Combine

class PostsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var posts: [PostResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Dependencies
    private let postsApiService: PostsApiService
    
    init(postsApiService: PostsApiService) {
        self.postsApiService = postsApiService
        fetchPosts() // Initial load
    }
    
    // MARK: - Fetch Posts (Personalized Feed)
    func fetchPosts() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedPosts = try await postsApiService.getPosts()
                
                await MainActor.run {
                    // Posts are already ordered by backend:
                    // 1. Posts from interacted food categories (first)
                    // 2. Other posts (after)
                    self.posts = fetchedPosts
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
    }
    
    // MARK: - Like Post
    func incrementLikeCount(_ postId: String) {
        Task {
            do {
                let updatedPost = try await postsApiService.addLike(postId)
                
                await MainActor.run {
                    // Update the post in the list
                    if let index = self.posts.firstIndex(where: { $0._id == postId }) {
                        self.posts[index] = updatedPost
                    }
                }
                
                // Backend automatically learns preference for this food category
                // Refresh feed to see updated order
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.fetchPosts()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to like post: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Unlike Post
    func decrementLikeCount(_ postId: String) {
        Task {
            do {
                let updatedPost = try await postsApiService.removeLike(postId)
                
                await MainActor.run {
                    if let index = self.posts.firstIndex(where: { $0._id == postId }) {
                        self.posts[index] = updatedPost
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to unlike post: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Get Post by ID (Tracks View)
    func getPostById(_ postId: String) async throws -> PostResponse {
        let post = try await postsApiService.getPostById(postId)
        // Backend automatically tracks view and updates preferences
        
        // Refresh feed after viewing to get updated personalized order
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchPosts()
        }
        
        return post
    }
}
```

### Step 3: Home Screen with Refresh Logic

**File**: `HomeScreen.swift`

```swift
import SwiftUI

struct HomeScreen: View {
    @StateObject private var postsViewModel: PostsViewModel
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    init(postsApiService: PostsApiService) {
        _postsViewModel = StateObject(wrappedValue: PostsViewModel(postsApiService: postsApiService))
    }
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.path) {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(postsViewModel.posts) { post in
                        PostCard(
                            post: post,
                            onPostClick: { postId in
                                // Navigate to post details
                                navigationCoordinator.navigateToPostDetails(postId)
                            },
                            onLikeClick: { postId in
                                // Like post
                                postsViewModel.incrementLikeCount(postId)
                                // Feed will refresh automatically
                            },
                            postsViewModel: postsViewModel
                        )
                    }
                }
                .padding()
            }
            .refreshable {
                // Pull to refresh
                postsViewModel.fetchPosts()
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .postDetails(let postId):
                    PostDetailsScreen(
                        postId: postId,
                        postsViewModel: postsViewModel
                    )
                }
            }
            .onAppear {
                // Refresh when screen appears (e.g., returning from post details)
                postsViewModel.fetchPosts()
            }
        }
    }
}
```

### Step 4: Post Details Screen with Refresh on Return

**File**: `PostDetailsScreen.swift`

```swift
import SwiftUI

struct PostDetailsScreen: View {
    let postId: String
    @ObservedObject var postsViewModel: PostsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var post: PostResponse? = nil
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            if let post = post {
                // Post content
                PostContentView(post: post)
            } else if isLoading {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                    // Feed will refresh when returning to home screen
                }
            }
        }
        .task {
            do {
                // Fetch post (automatically tracks view)
                let fetchedPost = try await postsViewModel.getPostById(postId)
                post = fetchedPost
                isLoading = false
                
                // Backend has updated preferences
                // Feed will refresh when returning to home
            } catch {
                isLoading = false
            }
        }
    }
}
```

### Step 5: Refresh Logic on Navigation Return

**Option A: Using SwiftUI Navigation**

```swift
struct HomeScreen: View {
    @StateObject private var postsViewModel: PostsViewModel
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        NavigationStack {
            // ... content
        }
        .onChange(of: navigationCoordinator.path.count) { newCount in
            // When returning from post details (path count decreases)
            if newCount == 0 {
                // Refresh feed to get updated personalized order
                postsViewModel.fetchPosts()
            }
        }
    }
}
```

**Option B: Using NotificationCenter**

```swift
// In PostDetailsScreen when navigating back
Button("Back") {
    // Post notification that we're returning
    NotificationCenter.default.post(
        name: NSNotification.Name("PostDetailsDismissed"),
        object: nil,
        userInfo: ["postId": postId, "foodType": post?.foodType]
    )
    dismiss()
}

// In HomeScreen
.onReceive(NotificationCenter.default.publisher(
    for: NSNotification.Name("PostDetailsDismissed")
)) { notification in
    // Refresh feed to get updated personalized order
    postsViewModel.fetchPosts()
}
```

**Option C: Using Environment Object**

```swift
// Create a FeedRefreshCoordinator
class FeedRefreshCoordinator: ObservableObject {
    @Published var shouldRefresh = false
    
    func triggerRefresh() {
        shouldRefresh = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldRefresh = false
        }
    }
}

// In App/Scene
@StateObject private var refreshCoordinator = FeedRefreshCoordinator()

// In HomeScreen
.environmentObject(refreshCoordinator)
.onChange(of: refreshCoordinator.shouldRefresh) { shouldRefresh in
    if shouldRefresh {
        postsViewModel.fetchPosts()
    }
}

// In PostDetailsScreen
@EnvironmentObject var refreshCoordinator: FeedRefreshCoordinator

Button("Back") {
    refreshCoordinator.triggerRefresh()
    dismiss()
}
```

---

## 🔌 API Details

### Get Personalized Feed

**Endpoint**: `GET /posts`

**Headers**:
```
x-user-id: {currentUserId}
Authorization: Bearer {accessToken}
```

**Response**: Array of posts ordered by:
1. Posts from food categories user has interacted with (first)
2. Other posts (after)

**Example Response**:
```json
[
  {
    "_id": "post1",
    "caption": "Delicious pasta",
    "foodType": "PASTA_ITALIAN",
    "likeCount": 10,
    // ... user liked a pasta post earlier, so pasta posts appear first
  },
  {
    "_id": "post2",
    "caption": "Amazing burger",
    "foodType": "BURGER_AMERICAN",
    "likeCount": 5,
    // ... user hasn't interacted with burgers, so appears later
  }
]
```

### Track View (Automatic)

**Endpoint**: `GET /posts/{id}`

**Headers**:
```
x-user-id: {currentUserId}
Authorization: Bearer {accessToken}
```

**Behavior**: Backend automatically:
1. Tracks the view
2. Extracts the post's `foodType`
3. Updates user preferences for that food category
4. Future `GET /posts` calls will prioritize posts from this category

### Track Like (Automatic)

**Endpoint**: `PATCH /posts/{postId}/like`

**Headers**:
```
x-user-id: {currentUserId}
Authorization: Bearer {accessToken}
```

**Behavior**: Backend automatically:
1. Records the like
2. Extracts the post's `foodType`
3. Updates user preferences for that food category
4. Future `GET /posts` calls will prioritize posts from this category

---

## 🔄 Complete iOS Implementation Flow

### Scenario: User Likes a Post

```
1. User sees a post with foodType: "PASTA_ITALIAN"
   ↓
2. User clicks like button
   ↓
3. iOS calls: postsApiService.addLike(postId)
   - Sends PATCH /posts/{postId}/like
   - Includes x-user-id header
   ↓
4. Backend processes:
   - Records like action
   - Extracts foodType: "PASTA_ITALIAN"
   - Updates user preferences
   ↓
5. iOS updates local state
   ↓
6. iOS refreshes feed: postsViewModel.fetchPosts()
   ↓
7. Backend returns personalized feed:
   - All PASTA_ITALIAN posts appear first
   - Other posts follow
   ↓
8. User sees pasta posts prioritized in feed
```

### Scenario: User Accesses Post Details

```
1. User clicks on a post with foodType: "BURGER_AMERICAN"
   ↓
2. iOS navigates to PostDetailsScreen
   ↓
3. iOS calls: postsApiService.getPostById(postId)
   - Sends GET /posts/{postId}
   - Includes x-user-id header
   ↓
4. Backend processes:
   - Records view action
   - Extracts foodType: "BURGER_AMERICAN"
   - Updates user preferences
   ↓
5. User views post details
   ↓
6. User clicks back button
   ↓
7. iOS detects navigation return
   ↓
8. iOS refreshes feed: postsViewModel.fetchPosts()
   ↓
9. Backend returns personalized feed:
   - All BURGER_AMERICAN posts appear first
   - Other posts follow
   ↓
10. User sees burger posts prioritized in feed
```

---

## ✅ Implementation Checklist

### Core Functionality
- [ ] API service with x-user-id header support
- [ ] ViewModel with fetchPosts() method
- [ ] Like/unlike functionality
- [ ] Post details navigation
- [ ] Feed refresh on navigation return
- [ ] Feed refresh after like action

### UI Components
- [ ] Home feed screen
- [ ] Post card component
- [ ] Post details screen
- [ ] Pull-to-refresh functionality
- [ ] Loading states
- [ ] Error handling

### Navigation
- [ ] Navigate to post details on click
- [ ] Detect return from post details
- [ ] Trigger feed refresh on return
- [ ] Handle back button press

### Testing
- [ ] Test like action triggers refresh
- [ ] Test post click triggers view tracking
- [ ] Test feed reordering after interaction
- [ ] Test multiple interactions with different categories
- [ ] Test pull-to-refresh
- [ ] Test navigation return refresh

---

## 📝 Key Points

### Backend Behavior
- **Automatic Learning**: Backend learns preferences from all interactions (like, view, comment, save)
- **No Explicit Preference API**: No need to call a separate "preferFoodType" endpoint
- **Header-Based**: Personalization happens automatically when `x-user-id` header is present
- **Real-time Updates**: Preferences update immediately after each interaction

### Frontend Behavior
- **Refresh After Interactions**: Feed should refresh after like/access to see updated order
- **Refresh on Return**: Feed should refresh when returning from post details
- **No Manual Sorting**: Backend handles all sorting/prioritization
- **Transparent to User**: User just sees relevant content first

### Food Category Priority
The backend prioritizes posts based on:
1. **Interaction Frequency**: Categories with more interactions get higher priority
2. **Recent Interactions**: Recent interactions weighted more heavily
3. **Interaction Type**: Different weights for like vs view vs comment vs save
4. **Category Affinity**: Calculated score for each food category

---

## 🎯 Summary

The "Cosign Formulary" is a **backend-driven personalization system** that:

1. **Tracks Interactions**: Automatically tracks when users like, view, comment, or save posts
2. **Learns Preferences**: Extracts food categories from interacted posts
3. **Prioritizes Feed**: Returns posts ordered by user preferences
4. **Requires Refresh**: Frontend must refresh feed after interactions to see updated order

**iOS Implementation Steps:**
1. Add `x-user-id` header to all post-related API calls
2. Refresh feed after like actions
3. Refresh feed when returning from post details
4. Use pull-to-refresh for manual refresh
5. Backend handles all prioritization automatically

The key is ensuring the feed refreshes after interactions so users see the updated personalized order.

