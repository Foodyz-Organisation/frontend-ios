import Foundation
import WebRTC

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
    func webRTCClient(_ client: WebRTCClient, didAdd stream: RTCMediaStream)
}

final class WebRTCClient: NSObject {
    
    // MARK: - Properties
    static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    weak var delegate: WebRTCClientDelegate?
    private let peerConnection: RTCPeerConnection
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]    
    private var videoCapturer: RTCVideoCapturer?
    var localVideoTrack: RTCVideoTrack?
    var remoteVideoTrack: RTCVideoTrack?
    
    // MARK: - Init
    
    override init() {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: WebRTCConfig.iceServers)]
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue])
        
        guard let connection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil) else {
            fatalError("Unable to create RTCPeerConnection")
        }
        self.peerConnection = connection
        
        super.init()
        self.createMediaSenders()
        self.configureAudioSession()
        self.peerConnection.delegate = self
    }
    
    // MARK: - Local Media
    
    private func createMediaSenders() {
        let streamId = "stream"
        
        // Audio
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = WebRTCClient.factory.audioSource(with: audioConstrains)
        let audioTrack = WebRTCClient.factory.audioTrack(with: audioSource, trackId: "audio0")
        self.peerConnection.add(audioTrack, streamIds: [streamId])
        
        // Video
        let videoSource = WebRTCClient.factory.videoSource()
        self.videoCapturer = RTCVideoCapturer(delegate: videoSource)
        let videoTrack = WebRTCClient.factory.videoTrack(with: videoSource, trackId: "video0")
        self.localVideoTrack = videoTrack
        self.peerConnection.add(videoTrack, streamIds: [streamId])
    }
    
    func startCaptureLocalVideo(renderer: RTCVideoRenderer) {
        guard let capturer = self.videoCapturer as? RTCVideoCapturer else { return }
        self.localVideoTrack?.add(renderer)
        
        // Simple camera capture logic (using standard camera if available)
        // Note: For a real app, use RTCCameraVideoCapturer
        if let cameraCapturer = RTCVideoCapturer(delegate: WebRTCClient.factory.videoSource()) as? RTCCameraVideoCapturer {
             // Setup omitted for brevity, would require finding text device
        }
        
        // Simplified: Assume we are using the Camera helper from WebRTC usually provided in examples
        // But here we'll try to use the capturer directly if we can instantiated it
        // We will need a helper to start the camera.
        startCamera(renderer: renderer)
    }
    
    private func startCamera(renderer: RTCVideoRenderer) {
        // This part often requires more code to select device (front/back)
        guard let source = self.localVideoTrack?.source as? RTCVideoSource else { return }
        let capturer = RTCCameraVideoCapturer(delegate: source)
        self.videoCapturer = capturer
        
        guard let frontCamera = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == .front }) else { return }
        
        // Find 720p 30fps format
        let formats = RTCCameraVideoCapturer.supportedFormats(for: frontCamera)
        let format = formats.last ?? formats[0]
        let fps = 30
        
        capturer.startCapture(with: frontCamera, format: format, fps: fps)
    }
    
    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        self.remoteVideoTrack?.add(renderer)
    }
    
    func stopVideo() {
        if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
            capturer.stopCapture()
        }
    }
    
    // MARK: - Signaling
    
    func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains, optionalConstraints: nil)
        self.peerConnection.offer(for: constrains) { (sdp, error) in
            guard let sdp = sdp else { return }
            self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                completion(sdp)
            })
        }
    }
    
    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains, optionalConstraints: nil)
        self.peerConnection.answer(for: constrains) { (sdp, error) in
            guard let sdp = sdp else { return }
            self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                completion(sdp)
            })
        }
    }
    
    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> Void) {
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    func set(remoteCandidate: RTCIceCandidate) {
        self.peerConnection.add(remoteCandidate)
    }
    
    private func configureAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat)
        } catch let error {
            debugPrint("Error changeing AVAudioSession category: \(error)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("peerConnection new signaling state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        debugPrint("peerConnection did add stream")
        if let track = stream.videoTracks.first {
            self.remoteVideoTrack = track
            self.delegate?.webRTCClient(self, didAdd: stream)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("peerConnection did remove stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        debugPrint("peerConnection should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection new connection state: \(newState)")
        self.delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection new gathering state: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection did remove candidate(s)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection did open data channel")
    }
}
