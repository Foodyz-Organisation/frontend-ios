import Foundation
import Combine
import WebRTC

@MainActor
class CallViewModel: ObservableObject {
    @Published var localVideoTrack: RTCVideoTrack?
    @Published var remoteVideoTrack: RTCVideoTrack?
    @Published var isBound = false
    @Published var callStatus: String = "Connecting..."
    @Published var hasIncomingCall = false
    
    // Call controls
    @Published var isMicMuted = false
    @Published var isVideoOff = false
    @Published var isSpeakerOn = false
    
    private let signalClient = SocketIOManager.shared
    private var webRTCClient: WebRTCClient?
    private var cancellables = Set<AnyCancellable>()
    private var conversationId: String
    private var targetSocketId: String? // Needed for answer/ice
    var incomingOffer: [String: Any]? // Store initial offer here
    
    init(conversationId: String, incomingOffer: [String: Any]? = nil) {
        self.conversationId = conversationId
        self.incomingOffer = incomingOffer
        self.hasIncomingCall = (incomingOffer != nil)
        
        self.webRTCClient = WebRTCClient()
        self.webRTCClient?.delegate = self
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Handle signals
        signalClient.answerMadeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dict in
                guard let self = self else { return }
                if let answerDict = dict["answer"] as? [String: Any],
                   let sdp = answerDict["sdp"] as? String {
                    if let sock = dict["socket"] as? String {
                        self.targetSocketId = sock
                    }
                    let sessionDesc = RTCSessionDescription(type: .answer, sdp: sdp)
                    self.webRTCClient?.set(remoteSdp: sessionDesc) { error in
                        if error == nil {
                            self.callStatus = "Connected"
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        signalClient.iceCandidateSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dict in
                guard let self = self else { return }
                if let candidateDict = dict["candidate"] as? [String: Any],
                   let sdp = candidateDict["candidate"] as? String,
                   let sdpMid = candidateDict["sdpMid"] as? String,
                   let sdpMLineIndex = candidateDict["sdpMLineIndex"] as? Int32 {
                    let candidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
                    self.webRTCClient?.set(remoteCandidate: candidate)
                }
            }
            .store(in: &cancellables)
            
        signalClient.callEndedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.endCall()
            }
            .store(in: &cancellables)
    }
    
    func startCall() {
        self.webRTCClient?.offer { [weak self] sdp in
            guard let self = self else { return }
            let offerDict: [String: Any] = ["type": "offer", "sdp": sdp.sdp]
            self.signalClient.emitCallUser(conversationId: self.conversationId, offer: offerDict)
            self.callStatus = "Calling..."
        }
    }
    
    // Called when we receive a call
    func acceptCall(offerDict: [String: Any], fromSocketId: String?) {
        self.targetSocketId = fromSocketId
        guard let sdp = offerDict["sdp"] as? String else { return }
        let sessionDesc = RTCSessionDescription(type: .offer, sdp: sdp)
        
        self.webRTCClient?.set(remoteSdp: sessionDesc) { [weak self] error in
            guard let self = self else { return }
            self.webRTCClient?.answer { [weak self] answerSdp in
                guard let self = self else { return }
                let answerDict: [String: Any] = ["type": "answer", "sdp": answerSdp.sdp]
                if let sockId = self.targetSocketId {
                    self.signalClient.emitMakeAnswer(toSocketId: sockId, answer: answerDict)
                    self.callStatus = "Connected"
                }
            }
        }
    }
    
    func endCall() {
        signalClient.emitEndCall(conversationId: conversationId)
        webRTCClient?.stopVideo()
        // Close peer connection logic?
        // In this simple example, we might need to recreate VM or Client
        callStatus = "Ended"
    }
    
    // Toggle Mute
    func toggleMic() {
        isMicMuted.toggle()
        // implementation depends on WebRTCClient exposing audio track
    }
    
    func toggleVideo() {
        isVideoOff.toggle()
        if isVideoOff {
            webRTCClient?.stopVideo()
        } else {
            // webRTCClient?.startCaptureLocalVideo...
        }
    }
}

extension CallViewModel: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        let candidateDict: [String: Any] = [
            "sdp": candidate.sdp,
            "sdpMid": candidate.sdpMid ?? "",
            "sdpMLineIndex": candidate.sdpMLineIndex
        ]
        // If we initiated call, we don't know socket yet?
        // Actually we prefer to broadcast or send to specific user. backend handles "to"
        // In this simple logic, if we are caller, we might need to know callee socket id from answer?
        // OR the backend forwards to conversation room.
        
        // Android implementation sends "to". Our backend expects "to".
        // If we are the caller, we don't know "to" until we get an answer or if backend handles it.
        // Wait, backend `ice_candidate` event:
        // payload: { to: string; candidate: any }
        
        // If we are in a conversation room, maybe we should change backend to broadcast candidate to room?
        // Current backend: client.to(conversationId).emit... for OFFER.  (Broadcasting to room)
        // But for ICE, it expects specific target?
        //     @SubscribeMessage('ice_candidate')
        //     handleIceCandidate(client: Socket, payload: { to: string; candidate: any }) {
        //        this.server.to(payload.to).emit(...)
        //     }
        
        // This implies P2P needs exact socket ID. 
        // When we receive OFFER (call_made), we get { socket: client.id }. We store it.
        // When we receive ANSWER (answer_made), we get { socket: client.id }. We store it.
        
        if let target = targetSocketId {
             signalClient.emitIceCandidate(toSocketId: target, candidate: candidateDict)
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected, .completed:
                self.callStatus = "Connected"
            case .disconnected:
                self.callStatus = "Disconnected"
            case .failed:
                self.callStatus = "Failed"
            case .closed:
                self.callStatus = "Closed"
            default:
                break
            }
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        // Data channel
    }
    
    func webRTCClient(_ client: WebRTCClient, didAdd stream: RTCMediaStream) {
        DispatchQueue.main.async {
            self.remoteVideoTrack = stream.videoTracks.first
        }
    }
}
