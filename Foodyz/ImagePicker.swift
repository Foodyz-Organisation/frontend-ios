import SwiftUI
import PhotosUI
import UIKit

struct ImagePicker: View {
    enum ImageState {
        case empty
        case loading
        case success(Image)
        case failure(Error)
    }
    
    @Binding var imageState: ImageState
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            EmptyView()
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    let image = Image(uiImage: uiImage)
                    await MainActor.run {
                        imageState = .success(image)
                    }
                }
            }
        }
    }
}
