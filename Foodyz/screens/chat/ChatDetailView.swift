import SwiftUI
import Combine
import WebRTC

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
        content
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            messagesList

            composer
        }

        .navigationTitle(viewModel.title ?? title)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Audio Call Button
                Button {
                    viewModel.startCall(isVideo: false)
                } label: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Color(hex: "f5c42e"))
                }
                .disabled(viewModel.isInCall)
                
                // Video Call Button
                Button {
                    viewModel.startCall(isVideo: true)
                } label: {
                    Image(systemName: "video.fill")
                        .foregroundColor(Color(hex: "f5c42e"))
                }
                .disabled(viewModel.isInCall)
                
                // Refresh Button
                Button {
                    Task { await viewModel.loadMessages() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            // Initialize WebRTC with backend URL and auth token
            if let token = session.accessToken {
                viewModel.initializeWebRTC(baseURL: backendBaseURL, authToken: token)
            }
            
            await viewModel.loadMessages()
            viewModel.startLiveUpdates()
        }
        .fullScreenCover(isPresented: $viewModel.isInCall) {
            VideoCallView(viewModel: viewModel)
        }
        .overlay {
            if viewModel.incomingCall {
                IncomingCallOverlay(
                    isVideo: true, // You can enhance this to detect video vs audio
                    onAccept: {
                        viewModel.acceptCall(isVideo: true)
                    },
                    onDecline: {
                        viewModel.declineCall()
                    }
                )
            }
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
            // Explicit cleanup to prevent memory leaks and crashes
            viewModel.cleanup()
        }
        .background(AppColors.background.ignoresSafeArea())
    }
    
    private var backendBaseURL: String {
        return APIConfig.baseURLString
    }

    @ViewBuilder
    private var messagesList: some View {
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
            .onChange(of: viewModel.messages.count) { _ in
                if let last = viewModel.messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
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

                // 🔹 Badges de modération
                HStack(spacing: 8) {
                    // Badge bad words
                    if message.hasBadWords == true {
                        HStack(spacing: 4) {
                            Text("🛑")
                            Text("Message modéré")
                        }
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isCurrentUser == true ? Color(hex: "6B7280") : Color(hex: "f5c42e"))
                    }
                    
                    // Badge spam
                    if message.isSpam == true, let confidence = message.spamConfidence {
                        let percentage = Int(confidence * 100)
                        HStack(spacing: 4) {
                            Text("⚠️")
                            Text("Spam (\(percentage)%)")
                        }
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isCurrentUser == true ? Color(hex: "374151") : Color(hex: "FF6B6B"))
                    }
                }

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
    
    // WebRTC Properties
    @Published var isInCall = false
    @Published var isVideoCall = false
    @Published var incomingCall = false
    @Published var webRTCManager: WebRTCManager?
    
    private let conversationId: String
    private let chatAPI: ChatAPI
    private let userAPI: UserAPI
    private var refreshTask: Task<Void, Never>?
    private var socketManager: ChatSocketManager?
    private var callerSocketId: String?
    private var pendingOffer: [String: Any]?

    @Published var title: String?

    init(conversationId: String, chatAPI: ChatAPI? = nil, userAPI: UserAPI? = nil) {
        self.conversationId = conversationId
        self.chatAPI = chatAPI ?? ChatAPI.shared
        self.userAPI = userAPI ?? UserAPI.shared
    }



    func loadMessages(showLoading: Bool = true) async {
        if isLoading && showLoading { return }
        if showLoading { isLoading = true }
        errorMessage = nil
        do {
            let response = try await chatAPI.fetchMessages(conversationId: conversationId)
            messages = response.sorted(by: { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) })
            
            // Attempt to resolve title from participants if currently generic
            await resolveTitleFromMessages()
        } catch {
            errorMessage = error.localizedDescription
        }
        if showLoading { isLoading = false }
    }
    
    private func resolveTitleFromMessages() async {
        guard title == nil || title == "Conversation" else { return }
        
        do {
            let conversation = try await chatAPI.getConversation(id: conversationId)
            let currentUserId = SessionManager.shared.userId
            
            // If it's a private chat, find the other participant
            if conversation.kind == .privateChat,
               let otherId = conversation.participants.first(where: { $0 != currentUserId }) {
                
                if let profile = try? await userAPI.fetchProfile(userId: otherId) {
                    await MainActor.run {
                        self.title = profile.username
                    }
                }
            } else if let groupTitle = conversation.title, !groupTitle.isEmpty {
                 await MainActor.run {
                     self.title = groupTitle
                 }
            }
        } catch {
            print("Failed to resolve conversation title: \(error)")
        }
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
        let safeInterval = max(interval, 1)
        refreshTask = Task { [weak self] in
            await self?.runLiveUpdates(interval: safeInterval)
        }
    }

    func stopLiveUpdates() {
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    // MARK: - WebRTC Methods
    func initializeWebRTC(baseURL: String, authToken: String) {
        webRTCManager = WebRTCManager()
        
        webRTCManager?.onIceCandidate = { [weak self] candidate in
            guard let self, let socketId = self.callerSocketId else { return }
            
            let candidateDict: [String: Any] = [
                "sdpMid": candidate.sdpMid ?? "",
                "sdpMLineIndex": candidate.sdpMLineIndex,
                "candidate": candidate.sdp
            ]
            
            self.socketManager?.emitIceCandidate(toSocketId: socketId, candidate: candidateDict)
        }
        
        webRTCManager?.onSessionDescription = { [weak self] sdp in
            guard let self else { return }
            
            let sdpDict: [String: Any] = [
                "type": sdp.type == .offer ? "offer" : "answer",
                "sdp": sdp.sdp
            ]
            
            if sdp.type == .offer {
                self.socketManager?.emitCallUser(conversationId: self.conversationId, offer: sdpDict)
            } else if let socketId = self.callerSocketId {
                self.socketManager?.emitMakeAnswer(toSocketId: socketId, answer: sdpDict)
            }
        }
        
        // Initialize Socket Manager
        socketManager = ChatSocketManager(baseURL: baseURL, authToken: authToken)
        
        // Setup Socket callbacks
        socketManager?.onMessageReceived = { [weak self] message in
            guard let self else { return }
            if !self.messages.contains(where: { $0.id == message.id }) {
                self.messages.append(message)
                self.messages.sort(by: { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) })
            }
        }
        
        socketManager?.onCallMade = { [weak self] data in
            guard let self else { return }
            self.incomingCall = true
            self.pendingOffer = data["offer"] as? [String: Any]
            self.callerSocketId = data["socket"] as? String
        }
        
        socketManager?.onAnswerMade = { [weak self] data in
            guard let self,
                  let answerDict = data["answer"] as? [String: Any],
                  let type = answerDict["type"] as? String,
                  let sdp = answerDict["sdp"] as? String else { return }
            
            let sessionDescription = RTCSessionDescription(
                type: type == "offer" ? .offer : .answer,
                sdp: sdp
            )
            self.webRTCManager?.setRemoteDescription(sessionDescription)
        }
        
        socketManager?.onIceCandidateReceived = { [weak self] data in
            guard let self,
                  let candidateDict = data["candidate"] as? [String: Any],
                  let sdpMid = candidateDict["sdpMid"] as? String,
                  let sdpMLineIndex = candidateDict["sdpMLineIndex"] as? Int32,
                  let sdp = candidateDict["candidate"] as? String else { return }
            
            let candidate = RTCIceCandidate(
                sdp: sdp,
                sdpMLineIndex: sdpMLineIndex,
                sdpMid: sdpMid
            )
            self.webRTCManager?.addIceCandidate(candidate)
        }
        
        socketManager?.onCallEnded = { [weak self] in
            self?.endCall()
        }
        
        socketManager?.onCallDeclined = { [weak self] in
            self?.endCall()
        }
        
        socketManager?.onError = { [weak self] error in
            self?.errorMessage = error
        }
        
        // Connect socket and join conversation
        socketManager?.connect()
        
        // Give socket time to connect before joining
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            self.socketManager?.joinConversation(conversationId: self.conversationId)
        }
    }
    
    func startCall(isVideo: Bool) {
        guard let webRTCManager else { return }
        
        isInCall = true
        isVideoCall = isVideo
        
        webRTCManager.startLocalStream(isVideo: isVideo)
        webRTCManager.createPeerConnection()
        webRTCManager.createOffer()
    }
    
    func acceptCall(isVideo: Bool) {
        guard let webRTCManager,
              let offerDict = pendingOffer,
              let type = offerDict["type"] as? String,
              let sdp = offerDict["sdp"] as? String else { return }
        
        isInCall = true
        isVideoCall = isVideo
        incomingCall = false
        
        webRTCManager.startLocalStream(isVideo: isVideo)
        webRTCManager.createPeerConnection()
        
        let sessionDescription = RTCSessionDescription(
            type: type == "offer" ? .offer : .answer,
            sdp: sdp
        )
        webRTCManager.setRemoteDescription(sessionDescription)
        webRTCManager.createAnswer()
    }
    
    func declineCall() {
        incomingCall = false
        pendingOffer = nil
        socketManager?.emitDeclineCall(conversationId: conversationId)
    }
    
    func endCall() {
        isInCall = false
        isVideoCall = false
        incomingCall = false
        pendingOffer = nil
        
        webRTCManager?.endCall()
        emitEndCallSignal()
    }
    
    func toggleMute() {
        webRTCManager?.toggleMute()
    }
    
    func toggleVideo() {
        webRTCManager?.toggleVideo()
    }
    
    func switchCamera() {
        webRTCManager?.switchCamera()
    }

    private func emitEndCallSignal() {
        guard let socketManager else { return }
        // Ensure the socket is connected and in the room before emitting
        if !socketManager.isConnected {
            socketManager.connect()
            socketManager.joinConversation(conversationId: conversationId)
        }
        socketManager.emitEndCall(conversationId: conversationId)
    }

    // Run the periodic message refresh on the main actor to avoid background-thread UI crashes
    @MainActor
    private func runLiveUpdates(interval: TimeInterval) async {
        while !Task.isCancelled {
            await loadMessages(showLoading: false)
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
    }
    
    func cleanup() {
        stopLiveUpdates()
        if isInCall {
            endCall()
        }
        // Ensure explicit disconnect of socket and WebRTC cleanup
        socketManager?.disconnect()
        webRTCManager?.endCall()
    }
}
