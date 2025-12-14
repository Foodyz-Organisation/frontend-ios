import SwiftUI
import Combine

@MainActor
struct ChatListView: View {
    let role: AppUserRole
    var onConversationSelected: (ConversationDTO, String?) -> Void

    @StateObject private var viewModel = ChatListViewModel()
    @EnvironmentObject private var session: SessionManager

    @State private var isPeerSelectorPresented = false
    @State private var isStartingConversation = false
    @State private var startConversationError: String?
    @State private var isDeleteConfirmationPresented = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    statusSection

                    ForEach(viewModel.conversations) { conversation in
                        Button {
                            openConversation(conversation)
                        } label: {
                            conversationRow(for: conversation)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .background(AppColors.background)
            .refreshable {
                async let convTask: Void = viewModel.loadConversations()
                async let peerTask: Void = viewModel.loadPeers(force: true)
                _ = await (convTask, peerTask)
            }
            .task {
                await viewModel.loadPeers()
                await viewModel.loadConversations()
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
            .overlay(alignment: .center) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }

            newChatButton
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle(role == .professional ? "Client Chats" : "Messages")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    isDeleteConfirmationPresented = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Delete All Chats?", isPresented: $isDeleteConfirmationPresented) {
            Button("Delete All", role: .destructive) {
                Task {
                    await viewModel.deleteAllConversations()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your conversations and messages.")
        }
        .sheet(isPresented: $isPeerSelectorPresented) {
            PeerSelectorView(initialPeers: viewModel.peers) { peer in
                startConversation(with: peer)
            }
        }
        .alert("Unable to start chat", isPresented: Binding(
            get: { startConversationError != nil },
            set: { _ in startConversationError = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(startConversationError ?? "Unknown error")
        }
        .overlay {
            if isStartingConversation {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    ProgressView("Starting chat…")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
    }

    private var newChatButton: some View {
        Button(action: { isPeerSelectorPresented = true }) {
            Image(systemName: "plus.bubble.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .padding()
                .background(AppColors.primary)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
        }
        .padding()
        .accessibilityLabel("Start new chat")
    }

    @ViewBuilder
    private var statusSection: some View {
        if let error = viewModel.errorMessage {
            ChatStatusCard(text: error, systemImage: "exclamationmark.triangle.fill", tint: .red)
        } else if viewModel.conversations.isEmpty && !viewModel.isLoading {
            ChatStatusCard(
                text: "No recent conversations. Tap the button below to start chatting.",
                systemImage: "bubble.left.and.bubble.right.fill",
                tint: AppColors.primary
            )
        }
    }

    private func conversationRow(for conversation: ConversationDTO) -> some View {
        let title = viewModel.displayName(for: conversation, currentUserId: session.userId)
        let subtitle = summary(for: conversation)
        let avatarURL = viewModel.avatarURL(for: conversation, currentUserId: session.userId)

        return HStack(alignment: .center, spacing: 16) {
            AvatarView(avatarURL: avatarURL, size: 54, fallback: title)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.darkGray)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let updatedAt = conversation.updatedAt {
                Text(updatedAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle()) // Ensure tap target covers the whole row within the button
        .padding()
        .background(AppColors.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
    }

    private func summary(for conversation: ConversationDTO) -> String {
        let participantCount = conversation.participants.count
        switch conversation.kind {
        case .group:
            return "Group · \(participantCount) participants"
        case .privateChat:
            return participantCount == 2 ? "1-on-1 chat" : "Conversation"
        }
    }

    private func openConversation(_ conversation: ConversationDTO) {
        let title = viewModel.displayName(for: conversation, currentUserId: session.userId)
        onConversationSelected(conversation, title)
    }

    private func startConversation(with peer: ChatPeer) {
        guard !isStartingConversation else { return }
        isPeerSelectorPresented = false
        isStartingConversation = true
        startConversationError = nil

        let currentUserId = session.userId

        Task {
            if let existing = viewModel.existingConversation(with: peer.id, currentUserId: currentUserId) {
                isStartingConversation = false
                openConversation(existing)
                return
            }

            do {
                let conversation = try await viewModel.createConversation(with: peer)
                isStartingConversation = false
                openConversation(conversation)
            } catch {
                startConversationError = error.localizedDescription
                isStartingConversation = false
            }
        }
    }
}

private struct ChatStatusCard: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(.white)
                .padding(12)
                .background(tint)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundColor(AppColors.darkGray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

@MainActor
final class ChatListViewModel: ObservableObject {
    @Published var conversations: [ConversationDTO] = []
    @Published var peers: [ChatPeer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var peersErrorMessage: String?

    private let chatAPI: ChatAPI
    private let userAPI: UserAPI
    private var refreshTask: Task<Void, Never>?
    private var peersDictionary: [String: ChatPeer] = [:]

    init(chatAPI: ChatAPI? = nil, userAPI: UserAPI? = nil) {
        self.chatAPI = chatAPI ?? ChatAPI.shared
        self.userAPI = userAPI ?? UserAPI.shared
    }

    deinit {
        refreshTask?.cancel()
    }

    func loadConversations(showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        errorMessage = nil
        do {
            let response = try await chatAPI.fetchConversations()
            conversations = response
            await fetchMissingPeers()
        } catch {
            errorMessage = error.localizedDescription
        }
        if showLoading { isLoading = false }
    }

    func loadPeers(force: Bool = false) async {
        if !force, !peers.isEmpty { return }
        do {
            let currentUserId = await MainActor.run { SessionManager.shared.userId }
            let response = try await chatAPI.fetchPeers()
            let filtered = response.filter { $0.id != currentUserId }
            updatePeers(with: filtered)
        } catch {
            peersErrorMessage = error.localizedDescription
        }
    }



    private func fetchMissingPeers() async {
        let currentUserId = SessionManager.shared.userId
         // Re-calculate existing IDs from the dictionary to be safe
        let existingPeerIds = Set(peersDictionary.keys)
        
        var missingIds = Set<String>()
        for conversation in conversations {
            guard conversation.kind == .privateChat else { continue }
            for participant in conversation.participants {
                if participant != currentUserId && !existingPeerIds.contains(participant) {
                    missingIds.insert(participant)
                }
            }
        }
        
        guard !missingIds.isEmpty else { return }
        
        // Fetch sequentially to handle missing peers
        for id in missingIds {
            // Check dictionary again in case a parallel task added it (unlikely here but good practice)
            if peersDictionary[id] != nil { continue }

            if let profile = try? await userAPI.fetchProfile(userId: id) {
                let peer = ChatPeer(
                    id: profile.id,
                    name: profile.username,
                    email: profile.email,
                    role: profile.role ?? "user",
                    kind: "user",
                    avatarUrl: profile.avatarUrl
                )
                
                // Update immediately so UI refreshes for this user
                await MainActor.run {
                    updatePeers(with: [peer], appending: true)
                }
            }
        }
    }

    private func updatePeers(with newPeers: [ChatPeer], appending: Bool = false) {
        if appending {
            var combined = peers
            for peer in newPeers {
                if !peersDictionary.keys.contains(peer.id) {
                    combined.append(peer)
                    peersDictionary[peer.id] = peer
                }
            }
            peers = combined.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            peers = newPeers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            peersDictionary = Dictionary(uniqueKeysWithValues: newPeers.map { ($0.id, $0) })
        }
    }


    func startAutoRefresh(interval: TimeInterval = 10) {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.loadConversations(showLoading: false)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func displayName(for conversation: ConversationDTO, currentUserId: String?) -> String {
        if let resolved = resolvedTitle(for: conversation, currentUserId: currentUserId) {
            return resolved
        }
        return conversation.displayTitle
    }

    func avatarURL(for conversation: ConversationDTO, currentUserId: String?) -> String? {
        guard conversation.kind == .privateChat,
              let otherId = otherParticipant(in: conversation, excluding: currentUserId) else { return nil }
        return peersDictionary[otherId]?.avatarUrl
    }

    func existingConversation(with peerId: String, currentUserId: String?) -> ConversationDTO? {
        guard let currentUserId else { return nil }
        return conversations.first { conversation in
            conversation.kind == .privateChat &&
                conversation.participants.contains(currentUserId) &&
                conversation.participants.contains(peerId) &&
                conversation.participants.count == 2
        }
    }

    func createConversation(with peer: ChatPeer) async throws -> ConversationDTO {
        let request = CreateConversationRequest(kind: .privateChat, participants: [peer.id], title: peer.name)
        cachePeer(peer)
        let conversation = try await chatAPI.createConversation(request)
        upsertConversation(conversation)
        return conversation
    }

    func deleteAllConversations() async {
        isLoading = true
        do {
            try await chatAPI.deleteAllConversations()
            conversations = []
        } catch {
            errorMessage = "Failed to delete conversations: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func upsertConversation(_ conversation: ConversationDTO) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
    }

    private func resolvedTitle(for conversation: ConversationDTO, currentUserId: String?) -> String? {
        // For private chats, always try to use the peer's name first
        if conversation.kind == .privateChat,
           let otherId = otherParticipant(in: conversation, excluding: currentUserId),
           let peer = peersDictionary[otherId] {
            return peer.name
        }
        
        // Fallback to conversation title if available
        if let title = conversation.title, !title.isEmpty {
            return title
        }
        
        return nil
    }

    private func otherParticipant(in conversation: ConversationDTO, excluding currentUserId: String?) -> String? {
        guard let currentUserId else { return nil }
        return conversation.participants.first { $0 != currentUserId }
    }

    private func cachePeer(_ peer: ChatPeer) {
        peersDictionary[peer.id] = peer
        if !peers.contains(where: { $0.id == peer.id }) {
            peers.append(peer)
            peers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}
