import SwiftUI
import WebKit

struct LottieView: UIViewRepresentable {
    let filename: String
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        // Try multiple paths to find the animation file
        var animationData: Data?
        
        // Path 1: Try from NSDataAsset (for Assets.xcassets Data Sets)
        if let asset = NSDataAsset(name: filename) {
            animationData = asset.data
            print("✅ LottieView: Found animation '\(filename)' as NSDataAsset")
        }
        // Path 2: Try direct in bundle
        else if let url = Bundle.main.url(forResource: filename, withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            animationData = data
            print("✅ LottieView: Found animation '\(filename)' in Bundle")
        }
        
        if let data = animationData {
            let webView = WKWebView()
            webView.backgroundColor = .clear
            webView.isOpaque = false
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false
            
            let base64Json = data.base64EncodedString()
            
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <script src="https://cdnjs.cloudflare.com/ajax/libs/bodymovin/5.12.2/lottie.min.js"></script>
                <style>
                    * { margin: 0; padding: 0; box-sizing: border-box; }
                    body { 
                        background: transparent !important; 
                        display: flex; 
                        justify-content: center; 
                        align-items: center; 
                        height: 100vh; 
                        width: 100vw; 
                        overflow: hidden; 
                    }
                    #lottie-container { 
                        width: 100%; 
                        height: 100%; 
                        background: transparent !important;
                    }
                </style>
            </head>
            <body>
                <div id="lottie-container"></div>
                <script>
                    (function() {
                        function loadAnimation() {
                            try {
                                var jsonBase64 = '\(base64Json)';
                                var jsonString = atob(jsonBase64);
                                var animationData = JSON.parse(jsonString);
                                
                                if (typeof lottie === 'undefined') {
                                    setTimeout(loadAnimation, 100);
                                    return;
                                }
                                
                                var anim = lottie.loadAnimation({
                                    container: document.getElementById('lottie-container'),
                                    renderer: 'svg',
                                    loop: true,
                                    autoplay: true,
                                    animationData: animationData,
                                    rendererSettings: {
                                        preserveAspectRatio: 'xMidYMid meet',
                                        clearCanvas: true,
                                        hideOnTransparent: true
                                    }
                                });
                            } catch(e) { console.error('Lottie error:', e); }
                        }
                        loadAnimation();
                    })();
                </script>
            </body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: nil)
            
            containerView.addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                webView.topAnchor.constraint(equalTo: containerView.topAnchor),
                webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        } else {
            print("❌ LottieView: '\(filename)' not found as NSDataAsset or in bundle")
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
