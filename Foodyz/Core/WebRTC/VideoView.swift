import SwiftUI
import WebRTC

struct VideoView: UIViewRepresentable {
    
    let videoTrack: RTCVideoTrack?
    
    func makeUIView(context: Context) -> RTCMTLVideoView {
        let videoView = RTCMTLVideoView(frame: .zero)
        videoView.videoContentMode = .scaleAspectFill
        return videoView
    }
    
    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        if let track = videoTrack {
            track.add(uiView)
        } else {
            // Cleanup if needed, but tracks usually manage their renderers
        }
    }
}
