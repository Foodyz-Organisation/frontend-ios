import SwiftUI
import PhotosUI

let BASE_URL_EDIT = "http://localhost:3000/"

// MARK: - Brand Colors (Matching Android)
private let PrimaryBrand = Color(hex: 0xFFFFC107) // Yellow
private let BackgroundColor = Color(hex: 0xFFF6F6F9) // Light gray
private let SurfaceWhite = Color.white
private let TextPrimary = Color.black
private let TextSecondary = Color(hex: 0xFF9A9A9D)
private let InputBackground = Color(hex: 0xFFEFEEEE)
private let ErrorColor = Color(hex: 0xFFD32F2F)

// MARK: - Edit Menu Item Screen (100% similar to Android ItemDetailsScreen)
struct EditMenuItemScreen: View {
    @ObservedObject var viewModel: MenuViewModel
    let itemId: String
    let professionalId: String
    @Binding var path: NavigationPath
    @Environment(\.dismiss) var dismiss
    
    // Editable State
    @State private var name = ""
    @State private var description = ""
    @State private var priceStr = ""
    @State private var ingredients: [IngredientDto] = []
    @State private var options: [OptionDto] = []
    @State private var imagePath: String? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showPhotoPicker = false
    
    // UI State
    @State private var showDeleteDialog = false
    @State private var showSuccessDialog = false
    @State private var showErrorDialog = false
    @State private var errorMessage = ""
    @State private var hasInitiatedUpdate = false
    
    var body: some View {
        ZStack {
            BackgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Section 1: Image Section
                        EditImageSection(
                            imagePath: imagePath,
                            selectedImage: $selectedImage,
                            selectedPhotoItem: $selectedPhotoItem,
                            showPhotoPicker: $showPhotoPicker
                        )
                        
                        // Section 2: Item Info Section
                        EditItemInfoSection(
                            name: $name,
                            description: $description,
                            priceStr: $priceStr
                        )
                        
                        // Section 3: Ingredients Editor Section
                        EditIngredientsListEditor(ingredients: $ingredients)
                        
                        // Section 4: Options Editor Section
                        EditOptionsListEditor(options: $options)
                        
                        // Bottom padding for floating button
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                
                // Bottom Bar with Confirm Button
                EditBottomBarSection(
                    viewModelState: viewModel.uiState,
                    isLoading: {
                        if case .loading = viewModel.uiState {
                            return true
                        }
                        return false
                    }(),
                    onConfirm: {
                        handleUpdate()
                    }
                )
            }
        }
        .navigationTitle("Edit Dish Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(TextPrimary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showDeleteDialog = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(ErrorColor)
                }
            }
        }
        .onAppear {
            guard let accessToken = TokenManager.shared.getAccessToken() else { return }
            viewModel.fetchMenuItemDetails(id: itemId, token: accessToken)
        }
        .onReceive(viewModel.$itemDetailsUiState) { state in
            if case let .success(item) = state {
                name = item.name
                description = item.description ?? ""
                priceStr = String(item.price)
                ingredients = item.ingredients
                options = item.options
                imagePath = item.image
            }
        }
        .onReceive(viewModel.$uiState) { state in
            if !hasInitiatedUpdate { return }
            
            switch state {
            case .success:
                showSuccessDialog = true
                hasInitiatedUpdate = false
            case .error(let message):
                errorMessage = message
                showErrorDialog = true
                hasInitiatedUpdate = false
            default:
                break
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
        .alert("Delete Item", isPresented: $showDeleteDialog) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                handleDelete()
            }
        } message: {
            Text("Are you sure you want to delete \"\(name)\"? This action cannot be undone.")
        }
        .sheet(isPresented: $showSuccessDialog) {
            EditSuccessDialog {
                showSuccessDialog = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                    viewModel.resetUiState()
                }
            }
        }
        .sheet(isPresented: $showErrorDialog) {
            EditErrorDialog(message: errorMessage) {
                showErrorDialog = false
            }
        }
    }
    
    private func handleUpdate() {
        guard let accessToken = TokenManager.shared.getAccessToken() else { return }
        
        guard let price = Double(priceStr) else {
            errorMessage = "Price must be valid"
            showErrorDialog = true
            return
        }
        
        let updateDto = UpdateMenuItemDto(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
            price: price,
            category: nil, // Don't update category
            ingredients: ingredients,
            options: options
        )
        
        hasInitiatedUpdate = true
        
        // Check if there's a new image to upload
        if let image = selectedImage {
            // Update with image (multipart) - Note: This requires API support for multipart update
            // For now, we'll use the regular update
            viewModel.updateMenuItem(id: itemId, payload: updateDto, professionalId: professionalId, token: accessToken)
        } else {
            // Update without image (JSON only)
            viewModel.updateMenuItem(id: itemId, payload: updateDto, professionalId: professionalId, token: accessToken)
        }
    }
    
    private func handleDelete() {
        guard let accessToken = TokenManager.shared.getAccessToken() else { return }
        viewModel.deleteMenuItem(id: itemId, professionalId: professionalId, token: accessToken)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

// MARK: - Edit Image Section
struct EditImageSection: View {
    let imagePath: String?
    @Binding var selectedImage: UIImage?
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var showPhotoPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dish Photo")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(TextPrimary)
            
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if let imagePath = imagePath, !imagePath.isEmpty {
                    AsyncImage(url: URL(string: "\(BASE_URL_EDIT)\(imagePath)")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure, .empty:
                            Rectangle()
                                .fill(InputBackground)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 48))
                                        .foregroundColor(TextSecondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Rectangle()
                        .fill(InputBackground)
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(TextSecondary)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Edit Button Overlay
                Button(action: {
                    // Trigger photo picker
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showPhotoPicker = true
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            )
        }
        .padding(16)
        .background(SurfaceWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4)
    }
}

// MARK: - Edit Item Info Section
struct EditItemInfoSection: View {
    @Binding var name: String
    @Binding var description: String
    @Binding var priceStr: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Dish Details")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(TextPrimary)
            
            Divider()
                .background(Color(hex: 0xFFF0F0F0))
            
            // Name Field
            FoodAppTextField(
                value: $name,
                placeholder: "Dish Name",
                label: "Dish Name",
                bgColor: InputBackground
            )
            
            // Price Field
            FoodAppTextField(
                value: $priceStr,
                placeholder: "Base Price (TND)",
                label: "Base Price (TND)",
                bgColor: InputBackground,
                keyboardType: .decimalPad
            )
            
            // Description Field
            FoodAppTextField(
                value: $description,
                placeholder: "Detailed Description",
                label: "Detailed Description",
                bgColor: InputBackground,
                singleLine: false,
                minLines: 3
            )
        }
        .padding(16)
        .background(SurfaceWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4)
    }
}

// MARK: - Edit Ingredients List Editor
struct EditIngredientsListEditor: View {
    @Binding var ingredients: [IngredientDto]
    @State private var newName = ""
    @State private var supportsIntensity = false
    @State private var selectedIntensityType: IntensityType? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Ingredients (\(ingredients.count))")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(TextPrimary)
            
            Divider()
                .background(Color(hex: 0xFFF0F0F0))
            
            // Add New Ingredient Row
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    FoodAppTextField(
                        value: $newName,
                        placeholder: "Ingredient Name",
                        label: nil,
                        bgColor: InputBackground
                    )
                    
                    Button(action: {
                        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
                        if !trimmedName.isEmpty {
                            ingredients.append(IngredientDto(
                                name: trimmedName,
                                isDefault: true,
                                supportsIntensity: supportsIntensity,
                                intensityType: supportsIntensity ? selectedIntensityType : nil
                            ))
                            newName = ""
                            supportsIntensity = false
                            selectedIntensityType = nil
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(PrimaryBrand)
                            .cornerRadius(8)
                    }
                }
                
                // Intensity Toggle
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle("Enable intensity slider", isOn: $supportsIntensity)
                            .toggleStyle(CheckboxToggleStyle())
                            .tint(PrimaryBrand)
                    }
                    
                    if supportsIntensity {
                        IntensityTypeSelector(
                            selectedType: $selectedIntensityType
                        )
                    }
                }
            }
            
            // Current Ingredients List
            if !ingredients.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(ingredients.indices, id: \.self) { index in
                            EditIngredientRow(
                                ingredient: ingredients[index],
                                onDelete: {
                                    ingredients.remove(at: index)
                                }
                            )
                            
                            if index < ingredients.count - 1 {
                                Divider()
                                    .background(Color(hex: 0xFFF0F0F0))
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            } else {
                Text("No ingredients added yet. These are typically included by default.")
                    .font(.system(size: 12))
                    .foregroundColor(TextSecondary)
                    .padding(.top, 8)
            }
        }
        .padding(16)
        .background(SurfaceWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4)
    }
}

// MARK: - Edit Ingredient Row
struct EditIngredientRow: View {
    let ingredient: IngredientDto
    let onDelete: () -> Void
    @State private var intensityValue: Float = 0.5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(TextPrimary)
                    
                    if ingredient.supportsIntensity {
                        Text("Intensity: Adjustable")
                            .font(.system(size: 11))
                            .foregroundColor(PrimaryBrand)
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(ErrorColor)
                        .font(.system(size: 16))
                }
            }
            
            if ingredient.supportsIntensity {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Intensity")
                            .font(.system(size: 12))
                            .foregroundColor(TextSecondary)
                        Spacer()
                        Text("\(Int(intensityValue * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(PrimaryBrand)
                    }
                    
                    Slider(value: $intensityValue, in: 0...1)
                        .tint(PrimaryBrand)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Edit Options List Editor
struct EditOptionsListEditor: View {
    @Binding var options: [OptionDto]
    @State private var newName = ""
    @State private var newPrice = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Options (\(options.count))")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(TextPrimary)
            
            Divider()
                .background(Color(hex: 0xFFF0F0F0))
            
            // Add New Option Row
            HStack(spacing: 8) {
                FoodAppTextField(
                    value: $newName,
                    placeholder: "Option Name (e.g., Large size)",
                    label: nil,
                    bgColor: InputBackground
                )
                
                FoodAppTextField(
                    value: $newPrice,
                    placeholder: "Price (TND)",
                    label: nil,
                    bgColor: InputBackground,
                    keyboardType: .decimalPad
                )
                .frame(width: 100)
                
                Button(action: {
                    guard let price = Double(newPrice), !newName.isEmpty, price >= 0 else { return }
                    options.append(OptionDto(name: newName.trimmingCharacters(in: .whitespaces), price: price))
                    newName = ""
                    newPrice = ""
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(PrimaryBrand)
                        .cornerRadius(8)
                }
            }
            
            // Current Options List
            if !options.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(options.indices, id: \.self) { index in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(options[index].name)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(TextPrimary)
                                    Text("+TND \(String(format: "%.3f", options[index].price))")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(PrimaryBrand)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    options.remove(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(ErrorColor)
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(.vertical, 8)
                            
                            if index < options.count - 1 {
                                Divider()
                                    .background(Color(hex: 0xFFF0F0F0))
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            } else {
                Text("No custom options added yet. (e.g., Extra Cheese, Different Size)")
                    .font(.system(size: 12))
                    .foregroundColor(TextSecondary)
                    .padding(.top, 8)
            }
        }
        .padding(16)
        .background(SurfaceWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4)
    }
}

// MARK: - Edit Bottom Bar Section
struct EditBottomBarSection: View {
    let viewModelState: MenuItemUiState
    let isLoading: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onConfirm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: TextPrimary))
                        .frame(height: 56)
                } else {
                    Text("Confirm Changes")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(TextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
            }
            .disabled(isLoading)
            .background(PrimaryBrand)
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(SurfaceWhite)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -5)
    }
}

// MARK: - Edit Success Dialog
struct EditSuccessDialog: View {
    let onDismiss: () -> Void
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 16) {
                // Animated Success Icon
                ZStack {
                    Circle()
                        .fill(PrimaryBrand.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(PrimaryBrand)
                }
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        scale = 1.0
                    }
                }
                
                Text("Success!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(TextPrimary)
                
                Text("Item updated successfully!")
                    .font(.system(size: 16))
                    .foregroundColor(TextSecondary)
                
                Button(action: onDismiss) {
                    Text("OK")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(TextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(PrimaryBrand)
                        .cornerRadius(12)
                }
            }
            .padding(32)
            .background(SurfaceWhite)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.2), radius: 8)
            .padding(24)
        }
    }
}

// MARK: - Edit Error Dialog
struct EditErrorDialog: View {
    let message: String
    let onDismiss: () -> Void
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 16) {
                // Animated Error Icon
                ZStack {
                    Circle()
                        .fill(ErrorColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(ErrorColor)
                }
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        scale = 1.0
                    }
                }
                
                Text("Update Failed")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(TextPrimary)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(TextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                Button(action: onDismiss) {
                    Text("OK")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(ErrorColor)
                        .cornerRadius(12)
                }
            }
            .padding(32)
            .background(SurfaceWhite)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.2), radius: 8)
            .padding(24)
        }
    }
}

