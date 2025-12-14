import Foundation
import WebRTC

struct WebRTCConfig {
    static let iceServers: [String] = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302"
    ]
}
