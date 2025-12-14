import Foundation
import Combine
import SocketIO
import WebRTC

class ChatSocketManager: ObservableObject {
    
    // MARK: - Properties
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    
    // Callbacks
    var onMessageReceived: ((MessageDTO) -> Void)?
    var onError: ((String) -> Void)?
    
    // WebRTC Callbacks
    var onCallMade: (([String: Any]) -> Void)?
    var onAnswerMade: (([String: Any]) -> Void)?
    var onIceCandidateReceived: (([String: Any]) -> Void)?
    var onCallEnded: (() -> Void)?
    var onCallDeclined: (() -> Void)?
    
    // MARK: - Initialization
    init(baseURL: String, authToken: String, socketPath: String = "/socket.io") {
        let url = URL(string: baseURL)!
        
        manager = SocketManager(
            socketURL: url,
            config: [
                .log(false),
                .compress,
                .path(socketPath),
                .connectParams(["token": authToken]),
                .forceWebsockets(true),
                .reconnects(true),
                .reconnectWait(1),
                .reconnectWaitMax(5)
            ]
        )
        
        socket = manager?.defaultSocket
        setupEventHandlers()
    }
    
    // MARK: - Connection Management
    
    func connect() {
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
    
    // MARK: - Event Handlers Setup
    
    private func setupEventHandlers() {
        guard let socket = socket else { return }
        
        // Connection events
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("✅ Socket connected")
            Task { @MainActor in
                self?.isConnected = true
            }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("❌ Socket disconnected")
            Task { @MainActor in
                self?.isConnected = false
            }
        }
        
        socket.on(clientEvent: .error) { [weak self] data, _ in
            let error = data.first as? String ?? "Unknown error"
            print("❌ Socket error: \(error)")
            Task { @MainActor in
                self?.onError?(error)
            }
        }
        
        // Chat message event
        socket.on("new_message") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                  let message = try? JSONDecoder().decode(MessageDTO.self, from: jsonData) else {
                print("Failed to parse message")
                return
            }
            
            Task { @MainActor in
                self?.onMessageReceived?(message)
            }
        }
        
        // WebRTC Signaling Events
        socket.on("call_made") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any] else { return }
            print("📞 Incoming call")
            Task { @MainActor in
                self?.onCallMade?(dict)
            }
        }
        
        socket.on("answer_made") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any] else { return }
            print("✅ Answer received")
            Task { @MainActor in
                self?.onAnswerMade?(dict)
            }
        }
        
        socket.on("ice_candidate_received") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any] else { return }
            print("🧊 ICE candidate received")
            Task { @MainActor in
                self?.onIceCandidateReceived?(dict)
            }
        }
        
        socket.on("call_ended") { [weak self] _, _ in
            print("📵 Call ended")
            Task { @MainActor in
                self?.onCallEnded?()
            }
        }
        
        socket.on("call_declined") { [weak self] _, _ in
            print("🚫 Call declined")
            Task { @MainActor in
                self?.onCallDeclined?()
            }
        }
    }
    
    // MARK: - Chat Methods
    
    func joinConversation(conversationId: String) {
        socket?.emit("join_conversation", ["conversationId": conversationId])
        print("Joined conversation: \(conversationId)")
    }
    
    func sendMessage(conversationId: String, content: String, type: String = "text") {
        let payload: [String: Any] = [
            "conversationId": conversationId,
            "content": content,
            "type": type
        ]
        socket?.emit("send_message", payload)
        print("Message sent to conversation: \(conversationId)")
    }
    
    // MARK: - WebRTC Signaling Methods
    
    func emitCallUser(conversationId: String, offer: [String: Any]) {
        let payload: [String: Any] = [
            "conversationId": conversationId,
            "offer": offer
        ]
        socket?.emit("call_user", payload)
        print("📞 Emitting call_user")
    }
    
    func emitMakeAnswer(toSocketId: String, answer: [String: Any]) {
        let payload: [String: Any] = [
            "to": toSocketId,
            "answer": answer
        ]
        socket?.emit("make_answer", payload)
        print("✅ Emitting make_answer")
    }
    
    func emitIceCandidate(toSocketId: String, candidate: [String: Any]) {
        let payload: [String: Any] = [
            "to": toSocketId,
            "candidate": candidate
        ]
        socket?.emit("ice_candidate", payload)
        print("🧊 Emitting ice_candidate")
    }
    
    func emitEndCall(conversationId: String) {
        let payload: [String: Any] = [
            "conversationId": conversationId
        ]
        socket?.emit("end_call", payload)
        print("📵 Emitting end_call")
    }
    
    func emitDeclineCall(conversationId: String) {
        let payload: [String: Any] = [
            "conversationId": conversationId
        ]
        socket?.emit("decline_call", payload)
        print("🚫 Emitting decline_call")
    }
    
    deinit {
        disconnect()
    }
}
