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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("Sélectionner une photo")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Appuyez pour choisir une image")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
                }
                .onChange(of: selectedItem) { oldValue, newValue in
                    guard let newValue = newValue else { return }
                    
                    Task {
                        await MainActor.run {
                            imageState = .loading
                        }
                        
                        do {
                            if let data = try? await newValue.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                let image = Image(uiImage: uiImage)
                                await MainActor.run {
                                    imageState = .success(image)
                                    dismiss()
                                }
                            } else {
                                await MainActor.run {
                                    imageState = .failure(NSError(domain: "ImagePicker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de charger l'image"]))
                                }
                            }
                        } catch {
                            await MainActor.run {
                                imageState = .failure(error)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sélectionner une photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}
