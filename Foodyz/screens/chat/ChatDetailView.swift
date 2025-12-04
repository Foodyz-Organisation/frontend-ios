import SwiftUI
import Combine

@MainActor
struct ChatDetailView: View {
    @StateObject private var viewModel: ChatDetailViewModel
    @EnvironmentObject private var session: SessionManager
    private let title: String

    init(conversationId: String, title: String?) {
        _viewModel = StateObject(wrappedValue: ChatDetailViewModel(conversationId: conversationId))
        self.title = title ?? "Conversation"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, isCurrentUser: message.sender == session.userId)
                                .id(message.id)
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                }
                .background(AppColors.background)
                .onChange(of: viewModel.messages) { _, _ in
                    if let last = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }

            composer
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.loadMessages() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await viewModel.loadMessages()
            viewModel.startLiveUpdates()
        }
        .alert("Chat Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .onDisappear {
            viewModel.stopLiveUpdates()
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    private func sendMessage() {
        Task {
            await viewModel.sendMessage()
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Message", text: $viewModel.draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(ChatColors.inputBackground)
                .cornerRadius(24)
                .shadow(color: ChatColors.bubbleShadow, radius: 4, y: 2)

            Button(action: sendMessage) {
                if viewModel.isSending {
                    ProgressView()
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(AppColors.primary)
                        .clipShape(Circle())
                }
            }
            .disabled(viewModel.isSending || viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }
}

private struct MessageBubble: View {
    let message: MessageDTO
    let isCurrentUser: Bool?

    var body: some View {
        HStack(alignment: .bottom) {
            if isCurrentUser == true { Spacer() }

            VStack(alignment: isCurrentUser == true ? .trailing : .leading, spacing: 6) {
                Text(message.displayContent)
                    .padding(14)
                    .background(bubbleBackground)
                    .foregroundColor(isCurrentUser == true ? .white : AppColors.darkGray)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: ChatColors.bubbleShadow, radius: 6, y: 4)

                if let createdAt = message.createdAt {
                    Text(createdAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if isCurrentUser != true { Spacer() }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if isCurrentUser == true {
            LinearGradient(colors: [AppColors.primary, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            ChatColors.bubbleIncoming
        }
    }
}

@MainActor
final class ChatDetailViewModel: ObservableObject {
    @Published var messages: [MessageDTO] = []
    @Published var draft: String = ""
    @Published var isSending = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let conversationId: String
    private let chatAPI: ChatAPI
    private var refreshTask: Task<Void, Never>?

    init(conversationId: String, chatAPI: ChatAPI? = nil) {
        self.conversationId = conversationId
        self.chatAPI = chatAPI ?? ChatAPI.shared
    }

    deinit {
        refreshTask?.cancel()
    }

    func loadMessages(showLoading: Bool = true) async {
        if isLoading && showLoading { return }
        if showLoading { isLoading = true }
        errorMessage = nil
        do {
            let response = try await chatAPI.fetchMessages(conversationId: conversationId)
            messages = response.sorted(by: { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) })
        } catch {
            errorMessage = error.localizedDescription
        }
        if showLoading { isLoading = false }
    }

    func sendMessage() async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isSending else { return }

        isSending = true
        errorMessage = nil
        do {
            let payload = SendMessageRequest(content: trimmed, type: .text)
            let message = try await chatAPI.sendMessage(conversationId: conversationId, body: payload)
            messages.append(message)
            messages.sort(by: { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) })
            draft = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }

    func startLiveUpdates(interval: TimeInterval = 5) {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.loadMessages(showLoading: false)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    func stopLiveUpdates() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
