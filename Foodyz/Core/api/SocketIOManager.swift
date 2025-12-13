import Foundation
import SocketIO
import Combine

class SocketIOManager: ObservableObject {
    static let shared = SocketIOManager()
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    
    // Observables for WebRTC
    let callMadeSubject = PassthroughSubject<[String: Any], Never>()
    let answerMadeSubject = PassthroughSubject<[String: Any], Never>()
    let iceCandidateSubject = PassthroughSubject<[String: Any], Never>()
    let callEndedSubject = PassthroughSubject<Void, Never>()
    let callDeclinedSubject = PassthroughSubject<Void, Never>()
    
    // Observable for Chat
    let newMessageSubject = PassthroughSubject<[String: Any], Never>()
    
    private init() {}
    
    func connect(token: String) {
        disconnect()
        
        let config: SocketIOClientConfiguration = [
            .log(true),
            .compress,
            .connectParams(["token": token]),
            .reconnects(true),
            .reconnectAttempts(-1),
            .reconnectWait(1)
        ]
        
        let baseURLString: String
        baseURLString = APIConfig.baseURLString
        
        guard let url = URL(string: baseURLString) else { return }
        
        manager = SocketManager(socketURL: url, config: config)
        socket = manager?.defaultSocket
        
        setupHandlers()
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        socket?.removeAllHandlers()
        socket = nil
        manager = nil
        isConnected = false
    }
    
    private func setupHandlers() {
        guard let socket = socket else { return }
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("Socket connected")
            DispatchQueue.main.async { self?.isConnected = true }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("Socket disconnected")
            DispatchQueue.main.async { self?.isConnected = false }
        }
        
        socket.on("new_message") { [weak self] data, _ in
            if let dict = data.first as? [String: Any] {
                self?.newMessageSubject.send(dict)
            }
        }
        
        // WebRTC Events
        socket.on("call_made") { [weak self] data, _ in
            if let dict = data.first as? [String: Any] {
                self?.callMadeSubject.send(dict)
            }
        }
        
        socket.on("answer_made") { [weak self] data, _ in
            if let dict = data.first as? [String: Any] {
                self?.answerMadeSubject.send(dict)
            }
        }
        
        socket.on("ice_candidate_received") { [weak self] data, _ in
            if let dict = data.first as? [String: Any] {
                self?.iceCandidateSubject.send(dict)
            }
        }
        
        socket.on("call_ended") { [weak self] _, _ in
            self?.callEndedSubject.send()
        }
        
        socket.on("call_declined") { [weak self] _, _ in
            self?.callDeclinedSubject.send()
        }
    }
    
    // MARK: - Emitters
    
    func joinConversation(conversationId: String) {
        socket?.emit("join_conversation", ["conversationId": conversationId])
    }
    
    func sendMessage(conversationId: String, content: String, type: String = "text") {
        socket?.emit("send_message", [
            "conversationId": conversationId,
            "content": content,
            "type": type
        ])
    }
    
    func emitCallUser(conversationId: String, offer: [String: Any]) {
        socket?.emit("call_user", [
            "conversationId": conversationId,
            "offer": offer
        ])
    }
    
    func emitMakeAnswer(toSocketId: String, answer: [String: Any]) {
        socket?.emit("make_answer", [
            "to": toSocketId,
            "answer": answer
        ])
    }
    
    func emitIceCandidate(toSocketId: String, candidate: [String: Any]) {
        socket?.emit("ice_candidate", [
            "to": toSocketId,
            "candidate": candidate
        ])
    }
    
    func emitEndCall(conversationId: String) {
        socket?.emit("end_call", ["conversationId": conversationId])
    }
    
    func emitDeclineCall(conversationId: String) {
        socket?.emit("decline_call", ["conversationId": conversationId])
    }
}
