import SwiftUI
import WebRTC

struct VideoCallView: View {
    @ObservedObject var viewModel: ChatDetailViewModel
    @State private var isMuted = false
    @State private var isVideoEnabled = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Remote Video (main view)
                if let remoteTrack = viewModel.webRTCManager?.remoteVideoTrack {
                    RTCVideoView(videoTrack: remoteTrack)
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("En attente de connexion...")
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 40) {
                    // Mute button
                    Button(action: {
                        viewModel.toggleMute()
                        isMuted.toggle()
                    }) {
                        Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(isMuted ? Color.red : Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    // End call button
                    Button(action: {
                        viewModel.endCall()
                    }) {
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    
                    // Video toggle button
                    if viewModel.isVideoCall {
                        Button(action: {
                            viewModel.toggleVideo()
                            isVideoEnabled.toggle()
                        }) {
                            Image(systemName: isVideoEnabled ? "video.fill" : "video.slash.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(isVideoEnabled ? Color.gray.opacity(0.3) : Color.red)
                                .clipShape(Circle())
                        }
                        
                        // Switch camera button
                        Button(action: {
                            viewModel.switchCamera()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.bottom, 50)
            }
            
            // Local Video (Picture-in-Picture)
            if viewModel.isVideoCall, let localTrack = viewModel.webRTCManager?.localVideoTrack {
                VStack {
                    HStack {
                        Spacer()
                        
                        RTCVideoView(videoTrack: localTrack)
                            .frame(width: 120, height: 160)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(radius: 8)
                            .padding()
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - RTCVideoView Wrapper
struct RTCVideoView: UIViewRepresentable {
    let videoTrack: RTCVideoTrack
    
    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView()
        view.contentMode = .scaleAspectFill
        view.videoContentMode = .scaleAspectFill
        
        #if arch(arm64)
        view.videoContentMode = .scaleAspectFill
        #endif
        
        return view
    }
    
    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        videoTrack.add(uiView)
    }
    
    static func dismantleUIView(_ uiView: RTCMTLVideoView, coordinator: ()) {
        // Cleanup handled elsewhere
    }
}

// MARK: - Incoming Call Overlay
struct IncomingCallOverlay: View {
    let isVideo: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: isVideo ? "video.fill" : "phone.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "f5c42e"))
                
                Text(isVideo ? "Appel vidéo entrant" : "Appel audio entrant")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 40)
            
            HStack(spacing: 60) {
                // Decline button
                Button(action: onDecline) {
                    VStack(spacing: 10) {
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.red)
                            .clipShape(Circle())
                        
                        Text("Refuser")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
                
                // Accept button
                Button(action: onAccept) {
                    VStack(spacing: 10) {
                        Image(systemName: isVideo ? "video.fill" : "phone.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.green)
                            .clipShape(Circle())
                        
                        Text("Accepter")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.9)
                .ignoresSafeArea()
        )
    }
}
