# OCR License Number Extraction - Android Implementation Review & iOS Implementation Guide

## 📋 Table of Contents
1. [Android Implementation Overview](#android-implementation-overview)
2. [Architecture & Flow](#architecture--flow)
3. [Key Components Analysis](#key-components-analysis)
4. [iOS Implementation Guide](#ios-implementation-guide)
5. [API Integration Details](#api-integration-details)
6. [Error Handling Patterns](#error-handling-patterns)

---

## 🔍 Android Implementation Overview

### Summary
The OCR license extraction feature in the Android app **does NOT perform OCR on the client side**. Instead, it:
1. Captures/uploads the license/permit image
2. Compresses the image to under 800 KB
3. Converts it to base64 format
4. Sends it to the backend API endpoint
5. The **backend performs OCR processing** and extracts the license number
6. Returns the extracted permit number in the API response

### Key Point
**The OCR processing happens on the backend server, not in the Android app.** The Android app is responsible for:
- Image selection/capture
- Image compression and optimization
- Base64 encoding
- API communication
- Displaying the extracted license number

---

## 🏗️ Architecture & Flow

### Complete User Flow

```
1. User reaches Step 2 (Business Verification) in professional signup
   ↓
2. User taps "Upload Restaurant Permit" button
   ↓
3. Image source dialog appears (Gallery/Camera)
   ↓
4. User selects image from gallery
   ↓
5. Image compression process starts (shown with loading indicator)
   ↓
6. Image compressed to base64 format (< 800 KB)
   ↓
7. Image preview displayed with file info
   ↓
8. User continues to Step 3 (Location)
   ↓
9. User completes registration and submits
   ↓
10. POST request sent to /auth/signup/professional with base64 image
    ↓
11. Backend performs OCR processing (5-30 seconds)
    ↓
12. Backend extracts permit number and validates document
    ↓
13. Response received with extracted permitNumber
    ↓
14. Success dialog displays extracted permit number
    ↓
15. User redirected to login screen
```

---

## 🔧 Key Components Analysis

### 1. **ViewModel: `ProSignupViewModel.kt`**

#### State Management
```kotlin
// Image upload states
val permitImageUri: MutableState<Uri?>           // Selected image URI
val permitImageBase64: MutableState<String?>     // Base64 encoded image
val isCompressingImage: MutableState<Boolean>    // Compression loading state
val permitFileName: MutableState<String?>        // Original filename
val permitFileSize: MutableState<String?>        // Formatted file size
val permitNumberExtracted: MutableState<String?> // Extracted permit number from API
```

#### Key Functions

**`convertImageToBase64(context: Context, uri: Uri)`**
- **Purpose**: Handles image selection and conversion
- **Process**:
  1. Extracts file metadata (name, size) from URI
  2. Launches compression on background thread (`Dispatchers.IO`)
  3. Uses `ImageCompressor.compressImageToBase64()` utility
  4. Calculates compressed file size
  5. Updates state with base64 string and metadata
  6. Handles errors gracefully

**`signup()`**
- **Purpose**: Submits professional signup request
- **Key Points**:
  - Includes `licenseImage` field in request (base64 string)
  - API timeout set to 30 seconds (for OCR processing)
  - Stores `permitNumberExtracted` from response
  - Handles document validation errors specifically
  - Navigates user back to Step 2 if document validation fails

### 2. **Image Compression Utility: `ImageCompressor.kt`**

#### Compression Algorithm
```kotlin
fun compressImageToBase64(context: Context, uri: Uri): String
```

**Process Steps:**
1. **Load Bitmap**: Reads image from URI using `ContentResolver`
2. **Fix Orientation**: Uses EXIF data to correct image rotation
3. **Resize if Needed**: Reduces dimensions to max 1920x1920 (maintains aspect ratio)
4. **Quality Compression**: 
   - Starts at 85% JPEG quality
   - If size > 800 KB, reduces quality by 10%
   - Repeats until size < 800 KB or quality reaches 20% minimum
5. **Base64 Encoding**: Converts to base64 string
6. **Format Output**: Returns `"data:image/jpeg;base64,{base64String}"`

#### Compression Constants
```kotlin
private const val MAX_DIMENSION = 1920    // Max width/height for OCR
private const val TARGET_SIZE_KB = 800    // Target file size
private const val MIN_QUALITY = 20        // Minimum JPEG quality
```

#### Features
- ✅ Maintains aspect ratio
- ✅ Handles EXIF orientation data
- ✅ Progressive quality reduction
- ✅ Comprehensive error handling
- ✅ Memory management (bitmap recycling)
- ✅ Detailed logging for debugging

### 3. **UI Component: `SignupScreenPro.kt` - Step2LicenseInfo**

#### Image Selection
```kotlin
// Gallery picker launcher
val imagePickerLauncher = rememberLauncherForActivityResult(
    contract = ActivityResultContracts.GetContent(),
    onResult = { uri: Uri? ->
        uri?.let {
            viewModel.convertImageToBase64(context, it)
        }
    }
)
```

#### UI States
1. **Before Upload**: Upload card with camera icon and instructions
2. **During Compression**: Loading spinner with "Compressing image..." message
3. **After Upload**: 
   - Image preview (200dp height)
   - File name and size display
   - "Change Photo" button
   - Close button to remove image

#### Image Source Dialog
- Gallery option (primary)
- Camera option (prepared but simplified)
- Cancel option

### 4. **API Service: `AuthApiService.kt`**

#### Professional Signup Endpoint
```kotlin
suspend fun professionalSignup(request: ProfessionalSignupRequest): ProfessionalSignupResponse
```

**Request Format:**
```kotlin
data class ProfessionalSignupRequest(
    val email: String,
    val password: String,
    val fullName: String,
    val licenseImage: String? = null,  // Base64: "data:image/jpeg;base64,..."
    val linkedUserId: String? = null,
    val locations: List<LocationDto>? = null
)
```

**Response Format:**
```kotlin
data class ProfessionalSignupResponse(
    val message: String? = null,
    val professionalId: String? = null,
    val permitNumber: String? = null,    // ← Extracted license number
    val confidence: String? = null,       // OCR confidence (high/medium/low)
    val id: String? = null,
    val role: String? = null,
    val token: String? = null
)
```

**API Configuration:**
- **Endpoint**: `POST /auth/signup/professional`
- **Content-Type**: `application/json`
- **Timeout**: 30 seconds (extended for OCR processing)
- **Error Handling**: Parses JSON error responses with detailed messages

### 5. **Error Handling**

#### Document Validation Errors
The app specifically handles these error scenarios:
- Document doesn't appear to be a Tunisian restaurant permit
- Could not extract permit number
- Image quality too low
- No readable text found
- Permit already registered

**User Experience:**
- Error message: "We were not able to validate the document provided, please provide another one"
- Automatically clears invalid image
- Navigates user back to Step 2 to upload a new document

---

## 📱 iOS Implementation Guide

### Overview
To implement the same functionality on iOS, you need to replicate:
1. Image picker (UIImagePickerController or PHPickerViewController)
2. Image compression utility
3. Base64 encoding
4. API service with extended timeout
5. Response handling and UI updates

---

## 🛠️ Step-by-Step iOS Implementation

### Step 1: Image Compression Utility

Create: `ImageCompressor.swift`

```swift
import UIKit
import ImageIO
import MobileCoreServices

class ImageCompressor {
    private static let maxDimension: CGFloat = 1920
    private static let targetSizeKB = 800
    private static let minQuality: CGFloat = 0.2
    
    /// Compress image to base64 string under 800 KB
    /// - Parameters:
    ///   - image: UIImage to compress
    /// - Returns: Base64 string with data URI prefix
    static func compressImageToBase64(_ image: UIImage) throws -> String {
        print("🔄 Starting image compression")
        
        // Step 1: Fix orientation
        let orientedImage = image.fixedOrientation()
        
        // Step 2: Resize if needed
        let resizedImage = resizeIfNeeded(orientedImage)
        
        // Step 3: Compress with quality adjustment
        let compressedData = try compressToTargetSize(resizedImage)
        
        // Step 4: Convert to base64
        let base64String = compressedData.base64EncodedString(options: .lineLength64Characters)
        let finalSizeKB = compressedData.count / 1024
        print("✅ Compression complete! Final size: \(finalSizeKB) KB")
        
        return "data:image/jpeg;base64,\(base64String)"
    }
    
    /// Resize image if dimensions exceed max
    private static func resizeIfNeeded(_ image: UIImage) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        
        // Check if resize is needed
        if width <= maxDimension && height <= maxDimension {
            print("📐 No resize needed: \(width)x\(height)")
            return image
        }
        
        // Calculate new dimensions maintaining aspect ratio
        let ratio = width > height ? maxDimension / width : maxDimension / height
        let newWidth = width * ratio
        let newHeight = height * ratio
        
        print("📐 Resizing from \(width)x\(height) to \(newWidth)x\(newHeight)")
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    /// Compress image to meet target size
    private static func compressToTargetSize(_ image: UIImage) throws -> Data {
        var quality: CGFloat = 0.85 // Start with good quality
        var imageData: Data
        
        repeat {
            guard let data = image.jpegData(compressionQuality: quality) else {
                throw NSError(domain: "ImageCompressor", code: -1, 
                             userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }
            
            imageData = data
            let sizeKB = data.count / 1024
            print("🗜️ Trying quality \(Int(quality * 100))%: \(sizeKB) KB")
            
            if data.count <= targetSizeKB * 1024 {
                // Success! Size is acceptable
                break
            }
            
            quality -= 0.10 // Reduce quality by 10%
            
        } while quality >= minQuality
        
        return imageData
    }
}

// MARK: - UIImage Extension for Orientation Fix
extension UIImage {
    /// Fix image orientation based on EXIF data
    func fixedOrientation() -> UIImage {
        // If orientation is already up, return as is
        if imageOrientation == .up {
            return self
        }
        
        // Calculate proper transform
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
            
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        default:
            break
        }
        
        // Draw the image
        guard let cgImage = self.cgImage else { return self }
        guard let colorSpace = cgImage.colorSpace else { return self }
        
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else { return self }
        
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let newCGImage = context.makeImage() else { return self }
        return UIImage(cgImage: newCGImage, scale: 1, orientation: .up)
    }
}
```

### Step 2: ViewModel/ViewModel Equivalent

Create: `ProSignupViewModel.swift` (or use SwiftUI @Published properties)

```swift
import SwiftUI
import Combine

class ProSignupViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var fullName: String = ""
    
    // Image upload states
    @Published var permitImage: UIImage? = nil
    @Published var permitImageBase64: String? = nil
    @Published var isCompressingImage: Bool = false
    @Published var permitFileName: String? = nil
    @Published var permitFileSize: String? = nil
    @Published var permitNumberExtracted: String? = nil
    
    // UI states
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isSignupSuccess: Bool = false
    @Published var showSuccessDialog: Bool = false
    @Published var currentStep: Int = 1
    
    // MARK: - Dependencies
    private let authApiService: AuthApiService
    
    init(authApiService: AuthApiService) {
        self.authApiService = authApiService
    }
    
    // MARK: - Image Processing
    func convertImageToBase64(_ image: UIImage, fileName: String? = nil) {
        isCompressingImage = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                print("📸 Image selected: \(fileName ?? "unknown")")
                
                // Store original file name
                DispatchQueue.main.async {
                    self?.permitFileName = fileName
                }
                
                // Compress image
                let compressedBase64 = try ImageCompressor.compressImageToBase64(image)
                
                // Calculate compressed size
                if let data = Data(base64Encoded: compressedBase64.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")) {
                    let sizeKB = data.count / 1024
                    let formattedSize = self?.formatFileSize(sizeKB * 1024) ?? "\(sizeKB) KB"
                    
                    DispatchQueue.main.async {
                        self?.permitImageBase64 = compressedBase64
                        self?.permitImage = image
                        self?.permitFileSize = formattedSize
                        self?.isCompressingImage = false
                        print("✅ Image compressed and ready! Size: \(formattedSize)")
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to process image. Please try another photo."
                    self?.clearPermitImage()
                    print("❌ Image compression failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func clearPermitImage() {
        permitImage = nil
        permitImageBase64 = nil
        permitFileName = nil
        permitFileSize = nil
        isCompressingImage = false
    }
    
    private func formatFileSize(_ size: Int) -> String {
        let kb = Double(size) / 1024.0
        let mb = kb / 1024.0
        
        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.2f KB", kb)
        } else {
            return "\(size) B"
        }
    }
    
    // MARK: - Signup
    func signup() {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let request = ProfessionalSignupRequest(
            email: email,
            password: password,
            fullName: fullName,
            licenseImage: permitImageBase64,
            locations: nil // Add location handling as needed
        )
        
        Task {
            do {
                print("📤 Sending signup request to backend...")
                let response = try await authApiService.professionalSignup(request: request)
                print("✅ Signup response received!")
                
                await MainActor.run {
                    permitNumberExtracted = response.permitNumber
                    isSignupSuccess = true
                    showSuccessDialog = true
                    isLoading = false
                    
                    // Delay navigation to show success animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        // Navigate to login screen
                        self.currentStep = 0 // or use navigation coordinator
                    }
                }
                
            } catch {
                await MainActor.run {
                    let errorMsg = error.localizedDescription
                    print("❌ Professional signup failed: \(errorMsg)")
                    
                    // Check if it's a permit validation error
                    let isPermitValidationError = errorMsg.localizedCaseInsensitiveContains("tunisian restaurant") ||
                                                 errorMsg.localizedCaseInsensitiveContains("extract permit number") ||
                                                 errorMsg.localizedCaseInsensitiveContains("permit") ||
                                                 errorMsg.localizedCaseInsensitiveContains("validation") ||
                                                 errorMsg.localizedCaseInsensitiveContains("Image quality too low") ||
                                                 errorMsg.localizedCaseInsensitiveContains("no readable text") ||
                                                 errorMsg.localizedCaseInsensitiveContains("clearer photo")
                    
                    if isPermitValidationError {
                        errorMessage = "We were not able to validate the document provided, please provide another one"
                        clearPermitImage()
                        currentStep = 2 // Go back to step 2
                    } else if errorMsg.localizedCaseInsensitiveContains("email") || 
                              errorMsg.localizedCaseInsensitiveContains("mail") {
                        errorMessage = "This mail already exist"
                        currentStep = 1 // Go back to step 1
                    } else {
                        errorMessage = errorMsg.replacingOccurrences(of: "Technical Details: ", with: "")
                    }
                    
                    isLoading = false
                }
            }
        }
    }
}
```

### Step 3: API Service

Create: `AuthApiService.swift`

```swift
import Foundation

struct ProfessionalSignupRequest: Codable {
    let email: String
    let password: String
    let fullName: String
    let licenseImage: String?  // Base64 encoded image
    let linkedUserId: String?
    let locations: [LocationDto]?
}

struct ProfessionalSignupResponse: Codable {
    let message: String?
    let professionalId: String?
    let permitNumber: String?     // Extracted license number
    let confidence: String?       // OCR confidence level
    let id: String?
    let role: String?
    let token: String?
}

struct LocationDto: Codable {
    let name: String?
    let address: String?
    let lat: Double
    let lon: Double
}

class AuthApiService {
    private let baseURL: String = "YOUR_BASE_URL" // Replace with actual base URL
    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0 // 30 seconds for OCR processing
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)
    }
    
    func professionalSignup(request: ProfessionalSignupRequest) async throws -> ProfessionalSignupResponse {
        let url = URL(string: "\(baseURL)/auth/signup/professional")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        print("🔄 Professional signup request to: \(url.absoluteString)")
        print("📧 Email: \(request.email), Has image: \(request.licenseImage != nil)")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AuthApiService", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Parse error response
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            print("❌ Professional signup failed with status \(httpResponse.statusCode)")
            print("❌ Error body: \(errorBody)")
            
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                let errorMsg = errorResponse.reason ?? errorResponse.message ?? errorResponse.error ?? "Signup failed"
                throw NSError(domain: "AuthApiService", code: httpResponse.statusCode, 
                             userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
            
            throw NSError(domain: "AuthApiService", code: httpResponse.statusCode, 
                         userInfo: [NSLocalizedDescriptionKey: "Signup failed: \(httpResponse.statusCode)"])
        }
        
        let decoder = JSONDecoder()
        let successResponse = try decoder.decode(ProfessionalSignupResponse.self, from: data)
        print("✅ Professional signup successful! Permit: \(successResponse.permitNumber ?? "N/A")")
        
        return successResponse
    }
}

struct ErrorResponse: Codable {
    let statusCode: Int?
    let message: String?
    let reason: String?
    let error: String?
}
```

### Step 4: Image Picker Implementation (SwiftUI)

Create: `ImagePicker.swift`

```swift
import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        self?.parent.selectedImage = uiImage
                    }
                }
            }
            
            // Get file name (optional)
            if let identifier = results.first?.assetIdentifier {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
                if let asset = assets.firstObject {
                    let resources = PHAssetResource.assetResources(for: asset)
                    if let resource = resources.first {
                        let fileName = resource.originalFilename
                        print("📄 Selected file: \(fileName)")
                    }
                }
            }
        }
    }
}
```

### Step 5: SwiftUI View Implementation

```swift
import SwiftUI

struct Step2LicenseInfoView: View {
    @ObservedObject var viewModel: ProSignupViewModel
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        VStack(spacing: 28) {
            // Icon
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 42))
                .foregroundColor(.white)
                .frame(width: 90, height: 90)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.86, green: 0.99, blue: 0.91), Color(red: 0.06, green: 0.73, blue: 0.51)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
            
            Text("Business Verification")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(Color(red: 0.72, green: 0.45, blue: 0.0))
            
            Text("Build trust with your customers")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
            
            // Upload Section
            if viewModel.isCompressingImage {
                // Compression Progress
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                        .scaleEffect(1.5)
                    
                    Text("Compressing image...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.yellow)
                    
                    Text("This will take a few seconds")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow, lineWidth: 2)
                )
                
            } else if viewModel.permitImage == nil {
                // Upload Button
                Button(action: {
                    showImagePicker = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                        
                        Text("📷 Upload Restaurant Permit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Tap to upload permit photo\nor take a photo")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.90, green: 0.91, blue: 0.93), lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
            } else {
                // Image Preview
                VStack(spacing: 16) {
                    if let image = viewModel.permitImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                    }
                    
                    if let fileName = viewModel.permitFileName {
                        Text(fileName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    if let fileSize = viewModel.permitFileSize {
                        Text(fileSize)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                    }
                    
                    HStack(spacing: 16) {
                        Button("Change Photo") {
                            showImagePicker = true
                        }
                        .foregroundColor(Color(red: 0.06, green: 0.73, blue: 0.51))
                        
                        Button("Remove") {
                            viewModel.clearPermitImage()
                        }
                        .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.06, green: 0.73, blue: 0.51), lineWidth: 2)
                )
            }
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, isPresented: $showImagePicker)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                viewModel.convertImageToBase64(image, fileName: viewModel.permitFileName)
            }
        }
    }
}
```

---

## 🔌 API Integration Details

### Request Format

**Endpoint**: `POST /auth/signup/professional`

**Headers**:
```
Content-Type: application/json
```

**Request Body**:
```json
{
  "email": "restaurant@example.com",
  "password": "secure123",
  "fullName": "My Restaurant",
  "licenseImage": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
  "locations": [
    {
      "lat": 36.8065,
      "lon": 10.1815,
      "address": "Tunis, Tunisia"
    }
  ]
}
```

**Key Points**:
- `licenseImage` is optional (can be `null`)
- Format: `"data:image/jpeg;base64,{base64String}"`
- Image should be under 800 KB for optimal processing
- Backend will perform OCR and extract permit number

### Response Format

**Success (200 OK)**:
```json
{
  "message": "Professional account created successfully",
  "professionalId": "123e4567-e89b-12d3-a456-426614174000",
  "permitNumber": "12345",  // ← Extracted license number
  "confidence": "high",     // OCR confidence: high/medium/low
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "role": "professional",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error (400/422)**:
```json
{
  "statusCode": 400,
  "message": "Could not extract permit number from image",
  "reason": "Image quality too low or no readable text found"
}
```

### Timeout Configuration

**Important**: Set API timeout to **30 seconds** for OCR processing:
- iOS URLSession: `timeoutIntervalForRequest = 30.0`
- Android Ktor: `requestTimeoutMillis = 30000`

---

## ⚠️ Error Handling Patterns

### Common Error Scenarios

1. **Document Validation Failed**
   - Message: "does not appear to be a Tunisian restaurant permit"
   - Action: Clear image, navigate back to Step 2

2. **OCR Extraction Failed**
   - Message: "Could not extract permit number"
   - Action: Clear image, allow user to upload another

3. **Image Quality Too Low**
   - Message: "Image quality too low or no readable text found"
   - Action: Clear image, suggest taking a clearer photo

4. **Permit Already Registered**
   - Message: "Permit number already registered"
   - Action: Show error, stay on current step

5. **Network Timeout**
   - Action: Show timeout error, allow retry

### Error Message Mapping

```swift
func handleError(_ error: Error) {
    let errorMsg = error.localizedDescription
    
    if errorMsg.localizedCaseInsensitiveContains("tunisian restaurant") ||
       errorMsg.localizedCaseInsensitiveContains("extract permit number") ||
       errorMsg.localizedCaseInsensitiveContains("Image quality too low") ||
       errorMsg.localizedCaseInsensitiveContains("no readable text") {
        // Document validation error
        errorMessage = "We were not able to validate the document provided, please provide another one"
        clearPermitImage()
        currentStep = 2
    } else if errorMsg.localizedCaseInsensitiveContains("email") ||
              errorMsg.localizedCaseInsensitiveContains("mail") {
        // Email error
        errorMessage = "This mail already exist"
        currentStep = 1
    } else {
        // Generic error
        errorMessage = errorMsg
    }
}
```

---

## ✅ Checklist for iOS Implementation

### Core Functionality
- [ ] Image picker integration (PHPickerViewController)
- [ ] Image compression utility (under 800 KB)
- [ ] Base64 encoding with data URI prefix
- [ ] EXIF orientation fix
- [ ] Progressive quality compression
- [ ] File metadata extraction (name, size)

### UI Components
- [ ] Upload button/card
- [ ] Compression loading indicator
- [ ] Image preview after selection
- [ ] File info display (name, size)
- [ ] Change/Remove photo buttons
- [ ] Error message display
- [ ] Success dialog with extracted permit number

### API Integration
- [ ] Professional signup endpoint
- [ ] Extended timeout (30 seconds)
- [ ] Request/Response models
- [ ] Error response parsing
- [ ] Permit number extraction from response

### Error Handling
- [ ] Document validation errors
- [ ] OCR extraction failures
- [ ] Image quality errors
- [ ] Network timeout handling
- [ ] Navigation back to appropriate step on error

### Testing
- [ ] Test with various image sizes
- [ ] Test compression quality
- [ ] Test with different image orientations
- [ ] Test API error scenarios
- [ ] Test success flow with permit number display

---

## 📝 Notes & Best Practices

### Image Compression
- **Target**: Keep images under 800 KB
- **Quality**: Start at 85%, reduce to minimum 20%
- **Dimensions**: Max 1920x1920 pixels (maintains aspect ratio)
- **Format**: JPEG output (best for photos)
- **Orientation**: Always fix EXIF orientation data

### Performance
- Run compression on background thread (`DispatchQueue.global`)
- Show loading indicator during compression
- Clean up bitmap/image memory after processing
- Use async/await for API calls (iOS 15+)

### User Experience
- Show compression progress (takes 1-3 seconds)
- Display file info after selection
- Clear error messages for validation failures
- Allow easy image replacement
- Show extracted permit number in success dialog

### Security
- Don't store base64 images in UserDefaults
- Clear images from memory after upload
- Validate image format before processing
- Handle sensitive data appropriately

---

## 🔗 Related Files Reference

### Android Files (Reference)
- `ProSignupVeiwModel.kt` - ViewModel with state management
- `ImageCompressor.kt` - Image compression utility
- `SignupScreenPro.kt` - UI component (Step 2)
- `AuthApiService.kt` - API service
- `ProSingupRequest.kt` - Request/Response DTOs

### Documentation Files
- `BUSINESS_VERIFICATION_IMAGE_UPLOAD_IMPLEMENTATION.md`
- `IMAGE_COMPRESSION_IMPLEMENTATION.md`
- `BUG_FIX_PROFESSIONAL_SIGNUP_ERROR_HANDLING.md`

---

## 🎯 Summary

The Android implementation uses a **backend-based OCR approach**:
1. Client handles image selection, compression, and encoding
2. Backend performs OCR processing and license number extraction
3. Client displays the extracted permit number from API response

To implement on iOS:
1. Replicate image picker functionality
2. Implement equivalent image compression (under 800 KB)
3. Convert to base64 with data URI prefix
4. Call API with 30-second timeout
5. Handle responses and errors similar to Android implementation

The key is maintaining consistency in:
- Image format and size
- API request/response structure
- Error handling patterns
- User experience flow

