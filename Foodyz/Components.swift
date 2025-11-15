import SwiftUI

// MARK: - Field Label
struct FieldLabel: View {
    let text: String
    
    var body: some View {
        HStack {
            Text(text)
                .foregroundColor(BrandColors.TextPrimary)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}

// MARK: - Dropdown Field
struct DropdownField: View {
    @Binding var selected: String
    let placeholder: String
    let options: [String]
    let icon: String
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: { selected = option }) {
                    Text(option)
                }
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(BrandColors.TextSecondary)
                Text(selected.isEmpty ? placeholder : selected)
                    .foregroundColor(selected.isEmpty ? BrandColors.TextSecondary : BrandColors.TextPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(BrandColors.TextSecondary)
                    .font(.system(size: 12))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(BrandColors.FieldFill)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        }
    }
}

// MARK: - Description Field
struct DescriptionField: View {
    @Binding var text: String
    private let maxLength = 500
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Describe your issue...")
                        .foregroundColor(BrandColors.TextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $text)
                    .frame(minHeight: 140)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .onChange(of: text) { newValue in
                        if newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
            
            Text("\(text.count)/\(maxLength)")
                .foregroundColor(BrandColors.TextSecondary)
                .font(.system(size: 12))
        }
    }
}

// MARK: - Photos Section
struct PhotosSection: View {
    @Binding var photos: [UIImage]
    @Binding var showImagePicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FieldLabel(text: "Attach Photos (Optional)")
            
            if photos.isEmpty {
                HStack {
                    Spacer()
                    AddPhotoTile(action: { showImagePicker = true })
                    Spacer()
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(photos.indices, id: \.self) { index in
                        PhotoThumbnail(image: photos[index], onRemove: { photos.remove(at: index) })
                    }
                    if photos.count < 4 {
                        AddPhotoTile(action: { showImagePicker = true })
                    }
                }
            }
        }
    }
}

// MARK: - Add Photo Tile
struct AddPhotoTile: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .foregroundColor(BrandColors.TextSecondary)
                    .font(.system(size: 24))
                Text("Add")
                    .foregroundColor(BrandColors.TextSecondary)
                    .font(.system(size: 14))
            }
            .frame(width: 140, height: 120)
            .background(Color.clear)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(BrandColors.Dashed))
        }
    }
}

// MARK: - Photo Thumbnail
struct PhotoThumbnail: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .clipped()
                .cornerRadius(16)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.system(size: 12))
                    .padding(6)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
            }
            .padding(8)
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            if isShowing {
                Text(message)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: isShowing)
    }
}
