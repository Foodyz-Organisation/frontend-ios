import SwiftUI
import WebRTC

struct CallView: View {
    @ObservedObject var viewModel: CallViewModel
    @Environment(\.dismiss) var dismiss
    
    init(conversationId: String, incomingOffer: [String: Any]? = nil) {
        self.viewModel = CallViewModel(conversationId: conversationId, incomingOffer: incomingOffer)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Remote Video
            if let remoteTrack = viewModel.remoteVideoTrack {
                VideoView(videoTrack: remoteTrack)
                    .edgesIgnoringSafeArea(.all)
            } else {
                VStack {
                    Spacer()
                    Text(viewModel.callStatus)
                        .foregroundColor(.white)
                        .font(.title)
                    Spacer()
                }
            }
            
            // Local Video (PIP)
            if let localTrack = viewModel.localVideoTrack, !viewModel.isVideoOff {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VideoView(videoTrack: localTrack)
                            .frame(width: 120, height: 160)
                            .cornerRadius(12)
                            .padding()
                    }
                    .padding(.bottom, 80)
                }
            }
            
            // Controls
            if !viewModel.hasIncomingCall {
                VStack {
                    Spacer()
                    HStack(spacing: 40) {
                        
                        // Toggle Video
                        Button(action: {
                            viewModel.toggleVideo()
                        }) {
                            Image(systemName: viewModel.isVideoOff ? "video.slash.fill" : "video.fill")
                                .font(.title)
                                .padding()
                                .background(Color.gray.opacity(0.5))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        
                        // End Call
                        Button(action: {
                            viewModel.endCall()
                            dismiss()
                        }) {
                            Image(systemName: "phone.down.fill")
                                .font(.title)
                                .padding(20)
                                .background(Color.red)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                        
                        // Toggle Mic
                        Button(action: {
                            viewModel.toggleMic()
                        }) {
                            Image(systemName: viewModel.isMicMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.title)
                                .padding()
                                .background(Color.gray.opacity(0.5))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            
            // Incoming Call Overlay
            if viewModel.hasIncomingCall {
                ZStack {
                    Color.black.opacity(0.9).ignoresSafeArea()
                    VStack(spacing: 40) {
                        Text("Incoming Call")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Someone is calling you...")
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 60) {
                            // Decline
                            Button(action: {
                                viewModel.endCall() // Or declineCall
                                dismiss()
                            }) {
                                VStack {
                                    Image(systemName: "phone.down.fill")
                                        .font(.largeTitle)
                                        .padding()
                                        .background(Color.red)
                                        .clipShape(Circle())
                                    Text("Decline")
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Accept
                            Button(action: {
                                if let offer = viewModel.incomingOffer {
                                    let socketId = offer["socket"] as? String
                                    viewModel.acceptCall(offerDict: offer, fromSocketId: socketId)
                                    viewModel.hasIncomingCall = false
                                }
                            }) {
                                VStack {
                                    Image(systemName: "phone.fill")
                                        .font(.largeTitle)
                                        .padding()
                                        .background(Color.green)
                                        .clipShape(Circle())
                                    Text("Accept")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if !viewModel.hasIncomingCall {
                viewModel.startCall()
            }
        }
    }
}
