# Share Post & Save Post Features - iOS Implementation Guide

## 📋 Table of Contents
1. [Overview](#overview)
2. [Share Post Feature](#share-post-feature)
3. [Save Post Feature](#save-post-feature)
4. [Complete iOS Implementation](#complete-ios-implementation)
5. [API Integration Details](#api-integration-details)
6. [Testing Checklist](#testing-checklist)

---

## 🎯 Overview

This guide provides a complete implementation guide for two key features:
1. **Share Post**: Allows users to share posts with other users/professionals through chat
2. **Save Post**: Allows users to bookmark/save posts for later viewing

Both features follow the exact same logic and API structure as the Android implementation.

---

## 📤 Share Post Feature

### Android Implementation Summary

**Flow:**
1. User clicks Share icon on a post
2. Share dialog opens with search functionality
3. User searches for recipients using `/chat/peers` endpoint
4. User selects recipient → API call to share post
5. Backend creates a message in the conversation with post metadata
6. Shared post appears as a card in chat messages
7. Recipient can click to view full post

**Key Components:**
- `SharePostDialog.kt` - Full-screen dialog with search
- `PostsApiService.sharePost()` - API endpoint
- `ChatApiService.getPeers()` - User search endpoint
- Chat message rendering with shared post metadata

### API Endpoints

#### 1. Get Peers (User Search)
```
GET /chat/peers
Headers:
  Authorization: Bearer <token>
```

**Response:**
```json
[
  {
    "id": "user_id",
    "name": "User Name",
    "avatarUrl": "avatar_url",
    "email": "user@example.com",
    "kind": "user" | "professional"
  }
]
```

#### 2. Share Post
```
POST /posts/{postId}/share
Headers:
  Authorization: Bearer <token>
  x-user-id: <senderId>
  x-owner-type: UserAccount | ProfessionalAccount
Body:
{
  "recipientId": "recipient_id",
  "message": "Shared a post with you"
}
```

**Response:**
```json
{
  "success": true,
  "message": {
    "_id": "message_id",
    "conversation": "conversation_id",
    "sender": "sender_id",
    "content": "Shared a post with you",
    "type": "shared_post",
    "meta": {
      "sharedPostId": "post_id",
      "sharedPostCaption": "Post caption",
      "sharedPostImage": "image_url"
    },
    "createdAt": "2025-12-30T19:41:08.000Z"
  }
}
```

---

## 💾 Save Post Feature

### Android Implementation Summary

**Flow:**
1. User clicks bookmark icon on a post
2. API call to save/unsave post
3. UI updates immediately (optimistic update)
4. Post is added/removed from saved posts list
5. User can view all saved posts in profile screen

**Key Components:**
- `PostsViewModel.incrementSaveCount()` / `decrementSaveCount()`
- `PostsApiService.addSave()` / `removeSave()`
- `PostsApiService.getSavedPosts()`
- `AllSavedPosts.kt` - Saved posts screen

### API Endpoints

#### 1. Save Post
```
PATCH /posts/{postId}/save
Headers:
  Authorization: Bearer <token>
  x-user-id: <userId>
  x-owner-type: UserAccount | ProfessionalAccount
```

**Response:**
```json
{
  "_id": "post_id",
  "caption": "Post caption",
  "mediaUrls": ["url1", "url2"],
  "likeCount": 10,
  "saveCount": 5,
  "commentCount": 3,
  "isLiked": false,
  "isSaved": true,
  ...
}
```

#### 2. Unsave Post
```
DELETE /posts/{postId}/save
Headers:
  Authorization: Bearer <token>
  x-user-id: <userId>
  x-owner-type: UserAccount | ProfessionalAccount
```

**Response:** Same as Save Post (but `isSaved: false`)

#### 3. Get Saved Posts
```
GET /posts/saved/
Headers:
  Authorization: Bearer <token>
  x-user-id: <userId>
  x-owner-type: UserAccount | ProfessionalAccount
```

**Response:**
```json
[
  {
    "_id": "post_id",
    "caption": "Post caption",
    "mediaUrls": ["url1"],
    "likeCount": 10,
    "saveCount": 5,
    "isLiked": false,
    "isSaved": true,
    ...
  }
]
```

---

## 🛠️ Complete iOS Implementation

### Step 1: API Service Layer

Create: `PostsApiService.swift`

```swift
import Foundation

// MARK: - Share Post DTOs
struct SharePostRequest: Codable {
    let recipientId: String
    let message: String
}

struct SharePostResponse: Codable {
    let success: Bool
    let message: SharePostMessageResponse?
}

struct SharePostMessageResponse: Codable {
    let id: String?
    let conversation: String?
    let sender: String?
    let content: String?
    let type: String?
    let meta: SharedPostMeta?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversation, sender, content, type, meta
        case createdAt
    }
}

struct SharedPostMeta: Codable {
    let sharedPostId: String?
    let sharedPostCaption: String?
    let sharedPostImage: String?
}

// MARK: - Peer DTO
struct PeerDto: Codable {
    let id: String
    let name: String
    let avatarUrl: String?
    let email: String?
    let kind: String? // "user" or "professional"
}

// MARK: - Posts API Service
class PostsApiService {
    private let baseURL: String = "YOUR_BASE_URL" // Replace with actual base URL
    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15.0
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Share Post
    func sharePost(
        postId: String,
        request: SharePostRequest,
        token: String,
        userId: String,
        ownerType: String
    ) async throws -> SharePostResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)/share")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(userId, forHTTPHeaderField: "x-user-id")
        urlRequest.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PostsApiService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "PostsApiService", code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Share failed: \(errorBody)"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(SharePostResponse.self, from: data)
    }
    
    // MARK: - Save Post
    func savePost(
        postId: String,
        token: String,
        userId: String,
        ownerType: String
    ) async throws -> PostResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)/save")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(userId, forHTTPHeaderField: "x-user-id")
        urlRequest.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PostsApiService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PostsApiService", code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Save failed"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(PostResponse.self, from: data)
    }
    
    // MARK: - Unsave Post
    func unsavePost(
        postId: String,
        token: String,
        userId: String,
        ownerType: String
    ) async throws -> PostResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)/save")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(userId, forHTTPHeaderField: "x-user-id")
        urlRequest.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PostsApiService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PostsApiService", code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Unsave failed"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(PostResponse.self, from: data)
    }
    
    // MARK: - Get Saved Posts
    func getSavedPosts(
        token: String,
        userId: String,
        ownerType: String
    ) async throws -> [PostResponse] {
        let url = URL(string: "\(baseURL)/posts/saved/")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(userId, forHTTPHeaderField: "x-user-id")
        urlRequest.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PostsApiService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PostsApiService", code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to load saved posts"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([PostResponse].self, from: data)
    }
    
    // MARK: - Get Post By ID
    func getPostById(
        postId: String,
        token: String,
        userId: String,
        ownerType: String
    ) async throws -> PostResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(userId, forHTTPHeaderField: "x-user-id")
        urlRequest.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PostsApiService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PostsApiService", code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to load post"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(PostResponse.self, from: data)
    }
}

// MARK: - PostResponse Model (Example - adjust to match your backend)
struct PostResponse: Codable {
    let id: String
    let caption: String
    let mediaUrls: [String]
    let mediaType: String?
    let thumbnailUrl: String?
    let likeCount: Int
    let saveCount: Int
    let commentCount: Int
    let isLiked: Bool?
    let isSaved: Bool?
    let ownerId: String?
    let ownerName: String?
    let ownerAvatarUrl: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case caption, mediaUrls, mediaType, thumbnailUrl
        case likeCount, saveCount, commentCount
        case isLiked, isSaved
        case ownerId, ownerName, ownerAvatarUrl
        case createdAt
    }
}
```

Create: `ChatApiService.swift`

```swift
import Foundation

class ChatApiService {
    private let baseURL: String = "YOUR_BASE_URL" // Replace with actual base URL
    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15.0
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Get Peers
    func getPeers(token: String) async throws -> [PeerDto] {
        let url = URL(string: "\(baseURL)/chat/peers")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ChatApiService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "ChatApiService", code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to load peers"])
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([PeerDto].self, from: data)
    }
}
```

### Step 2: ViewModel Layer

Create: `PostsViewModel.swift`

```swift
import SwiftUI
import Combine

class PostsViewModel: ObservableObject {
    @Published var posts: [PostResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let postsApiService: PostsApiService
    private let tokenManager: TokenManager // Your token management
    private let userId: String
    private let ownerType: String
    
    init(postsApiService: PostsApiService, tokenManager: TokenManager, userId: String, ownerType: String) {
        self.postsApiService = postsApiService
        self.tokenManager = tokenManager
        self.userId = userId
        self.ownerType = ownerType
    }
    
    // MARK: - Save Post
    func savePost(postId: String) {
        Task {
            do {
                let token = try await tokenManager.getAccessToken()
                let updatedPost = try await postsApiService.savePost(
                    postId: postId,
                    token: token,
                    userId: userId,
                    ownerType: ownerType
                )
                
                await MainActor.run {
                    // Update post in list
                    if let index = posts.firstIndex(where: { $0.id == postId }) {
                        posts[index] = updatedPost
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save post: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Unsave Post
    func unsavePost(postId: String) {
        Task {
            do {
                let token = try await tokenManager.getAccessToken()
                let updatedPost = try await postsApiService.unsavePost(
                    postId: postId,
                    token: token,
                    userId: userId,
                    ownerType: ownerType
                )
                
                await MainActor.run {
                    // Update post in list
                    if let index = posts.firstIndex(where: { $0.id == postId }) {
                        posts[index] = updatedPost
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to unsave post: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Get Saved Posts
    func fetchSavedPosts() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                let token = try await tokenManager.getAccessToken()
                let savedPosts = try await postsApiService.getSavedPosts(
                    token: token,
                    userId: userId,
                    ownerType: ownerType
                )
                
                await MainActor.run {
                    posts = savedPosts
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load saved posts: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Get Post By ID
    func getPostById(postId: String) async throws -> PostResponse {
        let token = try await tokenManager.getAccessToken()
        return try await postsApiService.getPostById(
            postId: postId,
            token: token,
            userId: userId,
            ownerType: ownerType
        )
    }
}
```

### Step 3: Share Post Dialog (SwiftUI)

Create: `SharePostDialog.swift`

```swift
import SwiftUI

struct SharePostDialog: View {
    let postId: String
    let onDismiss: () -> Void
    let onShareSuccess: () -> Void
    
    @StateObject private var viewModel: SharePostDialogViewModel
    @State private var searchQuery: String = ""
    
    init(
        postId: String,
        postsApiService: PostsApiService,
        chatApiService: ChatApiService,
        tokenManager: TokenManager,
        userId: String,
        ownerType: String,
        onDismiss: @escaping () -> Void,
        onShareSuccess: @escaping () -> Void
    ) {
        self.postId = postId
        self.onDismiss = onDismiss
        self.onShareSuccess = onShareSuccess
        _viewModel = StateObject(wrappedValue: SharePostDialogViewModel(
            postId: postId,
            postsApiService: postsApiService,
            chatApiService: chatApiService,
            tokenManager: tokenManager,
            userId: userId,
            ownerType: ownerType
        ))
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Share Post")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                Divider()
                
                // Post Preview
                if let postData = viewModel.postData {
                    HStack(spacing: 12) {
                        // Post thumbnail
                        AsyncImage(url: URL(string: getImageUrl(post: postData))) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        
                        // Post caption
                        Text(postData.caption.isEmpty ? "Post" : postData.caption)
                            .font(.body)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                } else if viewModel.isLoadingPost {
                    ProgressView()
                        .frame(height: 80)
                }
                
                Divider()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search users or kitchens...", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchQuery) { newValue in
                            viewModel.search(query: newValue)
                        }
                    
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Success/Error Messages
                if let successMessage = viewModel.shareSuccessMessage {
                    Text(successMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                if let error = viewModel.shareError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // Search Results
                if viewModel.isSearching {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if searchQuery.isEmpty {
                    Spacer()
                    Text("Search for users or kitchens to share with")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                } else if viewModel.searchResults.isEmpty {
                    Spacer()
                    Text("No users found")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.searchResults) { user in
                                UserResultItem(
                                    user: user,
                                    isSharing: viewModel.isSharing,
                                    onShare: {
                                        viewModel.sharePost(to: user.id)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width * 0.95, height: UIScreen.main.bounds.height * 0.7)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(radius: 10)
        }
        .onAppear {
            viewModel.loadPostData()
        }
        .onChange(of: viewModel.shareSuccess) { success in
            if success {
                onShareSuccess()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onDismiss()
                }
            }
        }
    }
    
    private func getImageUrl(post: PostResponse) -> String {
        if post.mediaType == "reel", let thumbnail = post.thumbnailUrl {
            return thumbnail
        }
        return post.mediaUrls.first ?? ""
    }
}

struct UserResultItem: View {
    let user: SearchableUser
    let isSharing: Bool
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            AsyncImage(url: URL(string: user.profilePictureUrl ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    Color.gray.opacity(0.2)
                    Text(user.name.first?.uppercased() ?? "?")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.body)
                    .fontWeight(.semibold)
                
                // Badge
                Text(user.kind == "professional" ? "Kitchen" : "User")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        user.kind == "professional" 
                            ? Color.orange.opacity(0.2) 
                            : Color.blue.opacity(0.2)
                    )
                    .foregroundColor(
                        user.kind == "professional" 
                            ? .orange 
                            : .blue
                    )
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Share Button
            Button(action: onShare) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(Color(red: 1.0, green: 0.76, blue: 0.03))
            }
            .disabled(isSharing)
        }
        .padding()
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .cornerRadius(12)
    }
}

struct SearchableUser: Identifiable {
    let id: String
    let name: String
    let profilePictureUrl: String?
    let email: String?
    let kind: String
}

// MARK: - Share Post Dialog ViewModel
@MainActor
class SharePostDialogViewModel: ObservableObject {
    let postId: String
    private let postsApiService: PostsApiService
    private let chatApiService: ChatApiService
    private let tokenManager: TokenManager
    private let userId: String
    private let ownerType: String
    
    @Published var postData: PostResponse? = nil
    @Published var isLoadingPost: Bool = false
    @Published var searchResults: [SearchableUser] = []
    @Published var isSearching: Bool = false
    @Published var isSharing: Bool = false
    @Published var shareError: String? = nil
    @Published var shareSuccessMessage: String? = nil
    @Published var shareSuccess: Bool = false
    
    private var searchTask: Task<Void, Never>?
    
    init(
        postId: String,
        postsApiService: PostsApiService,
        chatApiService: ChatApiService,
        tokenManager: TokenManager,
        userId: String,
        ownerType: String
    ) {
        self.postId = postId
        self.postsApiService = postsApiService
        self.chatApiService = chatApiService
        self.tokenManager = tokenManager
        self.userId = userId
        self.ownerType = ownerType
    }
    
    func loadPostData() {
        Task {
            isLoadingPost = true
            do {
                let token = try await tokenManager.getAccessToken()
                postData = try await postsApiService.getPostById(
                    postId: postId,
                    token: token,
                    userId: userId,
                    ownerType: ownerType
                )
            } catch {
                shareError = "Failed to load post details"
            }
            isLoadingPost = false
        }
    }
    
    func search(query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            // Debounce: wait 500ms
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            guard !Task.isCancelled else { return }
            
            isSearching = true
            shareError = nil
            
            do {
                let token = try await tokenManager.getAccessToken()
                let peers = try await chatApiService.getPeers(token: token)
                
                // Filter peers by search query
                let filtered = peers.filter { peer in
                    peer.name.localizedCaseInsensitiveContains(query) ||
                    (peer.email?.localizedCaseInsensitiveContains(query) ?? false)
                }
                
                // Map to SearchableUser
                searchResults = filtered.map { peer in
                    // Clean name (remove email in parentheses)
                    let cleanName = peer.name.split(separator: " (").first.map(String.init) ?? peer.name
                    
                    return SearchableUser(
                        id: peer.id,
                        name: cleanName,
                        profilePictureUrl: peer.avatarUrl,
                        email: peer.email,
                        kind: peer.kind ?? "user"
                    )
                }
            } catch {
                shareError = "Search failed: \(error.localizedDescription)"
                searchResults = []
            }
            
            isSearching = false
        }
    }
    
    func sharePost(to recipientId: String) {
        Task {
            isSharing = true
            shareError = nil
            shareSuccessMessage = nil
            
            do {
                let token = try await tokenManager.getAccessToken()
                
                let request = SharePostRequest(
                    recipientId: recipientId,
                    message: "Shared a post with you"
                )
                
                let response = try await postsApiService.sharePost(
                    postId: postId,
                    request: request,
                    token: token,
                    userId: userId,
                    ownerType: ownerType
                )
                
                if response.success {
                    // Find recipient name
                    if let recipient = searchResults.first(where: { $0.id == recipientId }) {
                        shareSuccessMessage = "Post shared with \(recipient.name)!"
                    } else {
                        shareSuccessMessage = "Post shared successfully!"
                    }
                    shareSuccess = true
                } else {
                    shareError = "Failed to share post"
                }
            } catch {
                shareError = "Failed to share post: \(error.localizedDescription)"
            }
            
            isSharing = false
        }
    }
}
```

### Step 4: Post Card with Share/Save Buttons

Create: `PostCard.swift` (Example)

```swift
import SwiftUI

struct PostCard: View {
    let post: PostResponse
    let onShare: (String) -> Void
    let onSave: (String, Bool) -> Void
    
    @State private var isSaved: Bool
    @State private var saveCount: Int
    
    init(post: PostResponse, onShare: @escaping (String) -> Void, onSave: @escaping (String, Bool) -> Void) {
        self.post = post
        self.onShare = onShare
        self.onSave = onSave
        _isSaved = State(initialValue: post.isSaved ?? false)
        _saveCount = State(initialValue: post.saveCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Post Image
            AsyncImage(url: URL(string: post.mediaUrls.first ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 300)
            .clipped()
            
            // Action Buttons
            HStack(spacing: 16) {
                // Like button (existing)
                
                // Comment button (existing)
                
                // Share button
                Button(action: {
                    onShare(post.id)
                }) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Save button
                Button(action: {
                    isSaved.toggle()
                    if isSaved {
                        saveCount += 1
                    } else {
                        saveCount -= 1
                    }
                    onSave(post.id, isSaved)
                }) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 24))
                        .foregroundColor(isSaved ? Color(red: 1.0, green: 0.76, blue: 0.03) : .primary)
                }
            }
            .padding(.horizontal)
            
            // Caption
            Text(post.caption)
                .font(.body)
                .padding(.horizontal)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
```

### Step 5: Saved Posts Screen

Create: `SavedPostsScreen.swift`

```swift
import SwiftUI

struct SavedPostsScreen: View {
    @StateObject private var viewModel: PostsViewModel
    @Environment(\.dismiss) var dismiss
    
    init(viewModel: PostsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                } else if viewModel.posts.isEmpty {
                    VStack {
                        Text("No saved posts available.")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.posts) { post in
                                SavedPostItem(
                                    post: post,
                                    onUnsave: {
                                        viewModel.unsavePost(postId: post.id)
                                        // Remove from list after unsaving
                                        viewModel.posts.removeAll { $0.id == post.id }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Saved Posts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            .onAppear {
                viewModel.fetchSavedPosts()
            }
        }
    }
}

struct SavedPostItem: View {
    let post: PostResponse
    let onUnsave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Post Image
            AsyncImage(url: URL(string: post.mediaUrls.first ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 300)
            .clipped()
            
            // Action Row
            HStack {
                // Like, Comment buttons (existing)
                
                Spacer()
                
                // Unsave button
                Button(action: onUnsave) {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.76, blue: 0.03))
                }
            }
            .padding(.horizontal)
            
            // Caption
            Text(post.caption)
                .font(.body)
                .padding(.horizontal)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
```

---

## 🔌 API Integration Details

### Headers Required

All endpoints require these headers:
```swift
Authorization: Bearer <token>
x-user-id: <userId>
x-owner-type: UserAccount | ProfessionalAccount
```

### Error Handling

Handle these scenarios:
- **401 Unauthorized**: Token expired, refresh token
- **404 Not Found**: Post/user not found
- **400 Bad Request**: Invalid request data
- **Network Errors**: Show user-friendly messages

### Response Format Notes

- **Share Post Response**: The `message` field can be either a `String` or `SharePostMessageResponse` object. Handle both cases.
- **Save/Unsave**: Both return the updated `PostResponse` with `isSaved` flag updated.
- **Get Saved Posts**: Returns array of `PostResponse` where `isSaved` is always `true`.

---

## ✅ Testing Checklist

### Share Post Feature
- [ ] Click share icon on post
- [ ] Share dialog appears
- [ ] Post preview loads correctly
- [ ] Search for users/professionals
- [ ] Search results appear with correct badges
- [ ] Profile pictures load correctly
- [ ] Click on user to share
- [ ] Success message appears
- [ ] Dialog closes after sharing
- [ ] Shared post appears in chat
- [ ] Clicking shared post navigates to post details
- [ ] Error handling works for network failures
- [ ] Empty search results handled gracefully

### Save Post Feature
- [ ] Click bookmark icon to save post
- [ ] Icon changes to filled bookmark
- [ ] Save count increments
- [ ] Post appears in saved posts list
- [ ] Click bookmark again to unsave
- [ ] Icon changes to outline
- [ ] Save count decrements
- [ ] Post removed from saved posts list
- [ ] Saved posts screen loads correctly
- [ ] Empty state shown when no saved posts
- [ ] Unsave button works in saved posts screen
- [ ] Error handling for API failures
- [ ] Optimistic UI updates work correctly

### Edge Cases
- [ ] Share to same user multiple times
- [ ] Save/unsave with network delay
- [ ] Search with special characters
- [ ] Very long post captions
- [ ] Posts without images
- [ ] Network timeout scenarios
- [ ] Token expiration during operation

---

## 📝 Notes & Best Practices

### Share Post
- Use debounced search (500ms) to reduce API calls
- Show loading states during search and sharing
- Clean user names (remove email in parentheses)
- Handle both success and error responses
- Close dialog after successful share

### Save Post
- Use optimistic UI updates for better UX
- Update local state immediately, then sync with API
- Handle save count synchronization
- Remove from saved list when unsaved
- Persist saved state across app restarts if needed

### Performance
- Cache search results for better performance
- Lazy load images in lists
- Cancel in-flight requests when navigating away
- Use async/await for cleaner code

### UI/UX
- Match Android design patterns for consistency
- Show clear visual feedback for actions
- Use appropriate colors for states (saved = yellow)
- Handle empty states gracefully
- Provide clear error messages

---

## 🔗 Related Android Files (Reference)

### Share Post
- `SharePostDialog.kt` - Share dialog component
- `PostsApiService.kt` - API endpoints
- `ChatApiService.kt` - Get peers endpoint
- `ChatDetailScreen.kt` - Shared post message rendering

### Save Post
- `PostsViewModel.kt` - Save/unsave functions
- `AllSavedPosts.kt` - Saved posts screen
- `PostsHomeScreen.kt` - Post card with save button

---

## 🎯 Summary

Both features follow a similar pattern:
1. **UI Trigger**: User clicks button (share/save)
2. **API Call**: Make request to backend
3. **State Update**: Update local state optimistically
4. **Error Handling**: Show errors if API call fails
5. **UI Feedback**: Show success/error messages

The iOS implementation should mirror the Android logic exactly, using SwiftUI instead of Jetpack Compose and Swift's async/await instead of Kotlin coroutines.

