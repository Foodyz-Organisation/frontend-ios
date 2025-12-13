import Foundation
import Combine
import WebRTC
import AVFoundation

@MainActor
class WebRTCManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var localVideoTrack: RTCVideoTrack?
    @Published var remoteVideoTrack: RTCVideoTrack?
    @Published var isConnected = false
    @Published var isMuted = false
    @Published var isVideoEnabled = true
    
    // MARK: - Private Properties
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var peerConnection: RTCPeerConnection?
    private var localAudioTrack: RTCAudioTrack?
    private var videoCapturer: RTCCameraVideoCapturer?
    private var videoSource: RTCVideoSource?
    
    // Callbacks
    var onIceCandidate: ((RTCIceCandidate) -> Void)?
    var onSessionDescription: ((RTCSessionDescription) -> Void)?
    var onConnectionStateChange: ((RTCPeerConnectionState) -> Void)?
    
    // MARK: - Configuration
    private let config: RTCConfiguration = {
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
            RTCIceServer(urlStrings: ["stun:stun1.l.google.com:19302"])
        ]
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        return config
    }()
    
    private let mediaConstraints: RTCMediaConstraints = {
        RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "true"
            ],
            optionalConstraints: nil
        )
    }()
    
    // MARK: - Initialization
    override init() {
        super.init()
        initializePeerConnectionFactory()
    }
    
    private func initializePeerConnectionFactory() {
        RTCInitializeSSL()
        
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        
        peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }
    
    // MARK: - Public Methods
    
    /// Start local media stream
    func startLocalStream(isVideo: Bool) {
        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = peerConnectionFactory.audioSource(with: audioConstraints)
        localAudioTrack = peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio0")
        
        if isVideo {
            let videoSource = peerConnectionFactory.videoSource()
            self.videoSource = videoSource
            
            localVideoTrack = peerConnectionFactory.videoTrack(with: videoSource, trackId: "video0")
            startCameraCapture(videoSource: videoSource)
        }
    }
    
    /// Create peer connection
    func createPeerConnection() {
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
        )
        
        peerConnection = peerConnectionFactory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )
        
        if let audioTrack = localAudioTrack {
            peerConnection?.add(audioTrack, streamIds: ["stream0"])
        }
        
        if let videoTrack = localVideoTrack {
            peerConnection?.add(videoTrack, streamIds: ["stream0"])
        }
    }
    
    /// Create an offer
    func createOffer() {
        peerConnection?.offer(for: mediaConstraints) { [weak self] sdp, error in
            guard let self = self, let sdp = sdp else {
                print("Error creating offer: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            self.peerConnection?.setLocalDescription(sdp) { error in
                if let error = error {
                    print("Error setting local description: \(error.localizedDescription)")
                    return
                }
                
                Task { @MainActor in
                    self.onSessionDescription?(sdp)
                }
            }
        }
    }
    
    /// Create an answer
    func createAnswer() {
        peerConnection?.answer(for: mediaConstraints) { [weak self] sdp, error in
            guard let self = self, let sdp = sdp else {
                print("Error creating answer: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            self.peerConnection?.setLocalDescription(sdp) { error in
                if let error = error {
                    print("Error setting local description: \(error.localizedDescription)")
                    return
                }
                
                Task { @MainActor in
                    self.onSessionDescription?(sdp)
                }
            }
        }
    }
    
    /// Set remote session description
    func setRemoteDescription(_ sdp: RTCSessionDescription) {
        peerConnection?.setRemoteDescription(sdp) { error in
            if let error = error {
                print("Error setting remote description: \(error.localizedDescription)")
            }
        }
    }
    
    /// Add ICE candidate
    func addIceCandidate(_ candidate: RTCIceCandidate) {
        peerConnection?.add(candidate) { error in
            if let error = error {
                print("Error adding ICE candidate: \(error.localizedDescription)")
            }
        }
    }
    
    /// Toggle mute
    func toggleMute() {
        isMuted.toggle()
        localAudioTrack?.isEnabled = !isMuted
    }
    
    /// Toggle video
    func toggleVideo() {
        isVideoEnabled.toggle()
        localVideoTrack?.isEnabled = isVideoEnabled
    }
    
    /// Switch camera
    func switchCamera() {
        guard let capturer = videoCapturer else { return }
        
        let position: AVCaptureDevice.Position = .front
        let newPosition: AVCaptureDevice.Position = (position == .front) ? .back : .front
        
        let devices = RTCCameraVideoCapturer.captureDevices()
        guard let device = devices.first(where: { $0.position == newPosition }) else { return }
        
        capturer.stopCapture {
            self.startCameraCapture(on: device)
        }
    }
    
    /// End call and cleanup
    nonisolated func endCall() {
        Task { @MainActor in
            peerConnection?.close()
            peerConnection = nil
            
            videoCapturer?.stopCapture()
            videoCapturer = nil
            
            localAudioTrack = nil
            localVideoTrack = nil
            remoteVideoTrack = nil
            
            isConnected = false
        }
    }
    
    // MARK: - Private Methods
    
    private func startCameraCapture(videoSource: RTCVideoSource) {
        let devices = RTCCameraVideoCapturer.captureDevices()
        guard let frontCamera = devices.first(where: { $0.position == .front }) else {
            print("No front camera available")
            return
        }
        
        startCameraCapture(on: frontCamera)
    }
    
    private func startCameraCapture(on device: AVCaptureDevice) {
        let capturer = RTCCameraVideoCapturer(delegate: videoSource!)
        self.videoCapturer = capturer
        
        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        guard let format = formats.first(where: { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return dimensions.width == 640 && dimensions.height == 480
        }) ?? formats.first else {
            print("No suitable video format found")
            return
        }
        
        let fps = format.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30
        capturer.startCapture(with: device, format: format, fps: Int(fps))
    }
    

}

// MARK: - RTCPeerConnectionDelegate
extension WebRTCManager: RTCPeerConnectionDelegate {
    
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling state changed: \(stateChanged)")
    }
    
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Stream added with \(stream.videoTracks.count) video tracks")
        
        if let videoTrack = stream.videoTracks.first {
            Task { @MainActor in
                self.remoteVideoTrack = videoTrack
            }
        }
    }
    
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("Stream removed")
        Task { @MainActor in
            self.remoteVideoTrack = nil
        }
    }
    
    nonisolated func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Peer connection should negotiate")
    }
    
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("ICE connection state: \(newState)")
    }
    
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE gathering state: \(newState)")
    }
    
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("ICE candidate generated")
        Task { @MainActor in
            self.onIceCandidate?(candidate)
        }
    }
    
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("ICE candidates removed")
    }
    
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Data channel opened")
    }
    
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        print("Peer connection state: \(newState)")
        
        Task { @MainActor in
            self.isConnected = (newState == .connected)
            self.onConnectionStateChange?(newState)
        }
    }
}
