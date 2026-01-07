import SwiftUI
import PhotosUI

// MARK: - Brand Colors (Matching Android)
private let PrimaryBrand = Color(hex: 0xFFFFC107) // Yellow
private let BackgroundColor = Color(hex: 0xFFF6F6F9) // Light gray
private let SurfaceWhite = Color.white
private let TextPrimary = Color.black
private let TextSecondary = Color(hex: 0xFF9A9A9D)
private let InputBackground = Color(hex: 0xFFEFEEEE)
private let ErrorColor = Color(hex: 0xFFD32F2F)

// MARK: - Create Ingredient UI State
struct CreateIngredientUi: Identifiable {
    let id = UUID()
    var name: String
    var supportsIntensity: Bool
    var intensityType: IntensityType?
}

// MARK: - Create Option UI State
struct CreateOptionUi: Identifiable {
    let id = UUID()
    var name: String
    var priceStr: String
}

// MARK: - Main Screen
struct CreateMenuItemScreen: View {
    @ObservedObject var viewModel: MenuViewModel
    var professionalId: String
    @Binding var path: NavigationPath
    @Environment(\.dismiss) var dismiss
    
    // Form State
    @State private var name = ""
    @State private var description = ""
    @State private var priceText = ""
    @State private var preparationTime = "15"
    @State private var category: Category? = nil
    @State private var isCategoryDropdownExpanded = false
    
    // Ingredients
    @State private var ingredients: [CreateIngredientUi] = []
    @State private var newIngredient = ""
    @State private var newIngredientSupportsIntensity = false
    @State private var newIngredientIntensityType: IntensityType? = nil
    
    // Options
    @State private var options: [CreateOptionUi] = []
    @State private var newOptionName = ""
    @State private var newOptionPrice = ""
    
    // Image
    @State private var selectedImage: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showPhotoPicker = false
    
    // Error & Success
    @State private var localError: String? = nil
    @State private var showSuccessDialog = false
    @State private var showErrorDialog = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            BackgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Section 1: Dish Photo
                        DishPhotoSection(
                            selectedImage: $selectedImage,
                            selectedPhotoItem: $selectedPhotoItem,
                            showPhotoPicker: $showPhotoPicker
                        )
                        
                        // Section 2: Essentials
                        EssentialsSection(
                            name: $name,
                            description: $description,
                            priceText: $priceText,
                            preparationTime: $preparationTime,
                            category: $category,
                            isCategoryDropdownExpanded: $isCategoryDropdownExpanded
                        )
                        
                        // Section 3: Ingredients
                        CreateIngredientsSection(
                            ingredients: $ingredients,
                            newIngredient: $newIngredient,
                            newIngredientSupportsIntensity: $newIngredientSupportsIntensity,
                            newIngredientIntensityType: $newIngredientIntensityType
                        )
                        
                        // Section 4: Extras & Add-ons
                        CreateOptionsSection(
                            options: $options,
                            newOptionName: $newOptionName,
                            newOptionPrice: $newOptionPrice
                        )
                        
                        // Bottom padding for floating button
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                
                // Bottom Bar with Error & Confirm Button
                BottomBarSection(
                    localError: localError,
                    viewModelState: viewModel.uiState,
                    isLoading: {
                        if case .loading = viewModel.uiState {
                            return true
                        }
                        return false
                    }(),
                    onConfirm: {
                        handleCreate()
                    }
                )
            }
        }
        .navigationTitle("Add New Dish")
        .navigationBarBackButtonHidden(true) // Hide system back button
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(TextPrimary)
                }
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
        .onReceive(viewModel.$uiState) { state in
            switch state {
            case .success:
                showSuccessDialog = true
            case .error(let message):
                errorMessage = message
                showErrorDialog = true
            default:
                break
            }
        }
        .sheet(isPresented: $showSuccessDialog) {
            CreateSuccessDialog {
                showSuccessDialog = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                    viewModel.resetUiState()
                }
            }
        }
        .sheet(isPresented: $showErrorDialog) {
            CreateErrorDialog(message: errorMessage) {
                showErrorDialog = false
            }
        }
    }
    
    private func handleCreate() {
        localError = nil
        
        // Validation
        guard !name.isEmpty, category != nil else {
            localError = "Please add a name and category"
            return
        }
        
        guard let price = Double(priceText), price >= 0 else {
            localError = "Price must be valid"
            return
        }
        
        guard selectedImage != nil else {
            localError = "Don't forget the photo! 📸"
            return
        }
        
        // Get access token
        guard let accessToken = TokenManager.shared.getAccessToken() else {
            localError = "You must be logged in"
            return
        }
        
        // Create DTO
        let dto = CreateMenuItemDto(
            professionalId: professionalId,
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
            price: price,
            category: category!,
            ingredients: ingredients.map {
                IngredientDto(
                    name: $0.name.trimmingCharacters(in: .whitespaces),
                    isDefault: true,
                    supportsIntensity: $0.supportsIntensity,
                    intensityType: $0.intensityType
                )
            },
            options: options.compactMap {
                guard let price = Double($0.priceStr), !$0.name.isEmpty else { return nil }
                return OptionDto(name: $0.name.trimmingCharacters(in: .whitespaces), price: price)
            },
            preparationTimeMinutes: Int(preparationTime) ?? 15
        )
        
        // Create menu item
        viewModel.createMenuItem(payload: dto, image: selectedImage, token: accessToken)
    }
}

// MARK: - Dish Photo Section
struct DishPhotoSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var showPhotoPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dish Photo")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(TextPrimary)
            
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            Button(action: {
                                selectedPhotoItem = nil
                                selectedImage = nil
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                            .padding(12),
                            alignment: .bottomTrailing
                        )
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(InputBackground)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(PrimaryBrand)
                                Text("Upload Photo")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(PrimaryBrand)
                                Text("Good food needs a good look")
                                    .font(.system(size: 12))
                                    .foregroundColor(TextSecondary)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [10]))
                                .foregroundColor(TextSecondary)
                        )
                }
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
    }
}

// MARK: - Essentials Section
struct EssentialsSection: View {
    @Binding var name: String
    @Binding var description: String
    @Binding var priceText: String
    @Binding var preparationTime: String
    @Binding var category: Category?
    @Binding var isCategoryDropdownExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Essentials")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(TextPrimary)
            
            VStack(spacing: 16) {
                // Name
                FoodAppTextField(
                    value: $name,
                    placeholder: "Dish Name (e.g. Spicy Burger)",
                    label: "Name",
                    bgColor: InputBackground
                )
                
                // Price & Category Row
                HStack(spacing: 12) {
                    FoodAppTextField(
                        value: $priceText,
                        placeholder: "0.00",
                        label: "Price (TND)",
                        bgColor: InputBackground,
                        keyboardType: .decimalPad
                    )
                    
                    FoodAppTextField(
                        value: $preparationTime,
                        placeholder: "15",
                        label: "Time (min)",
                        bgColor: InputBackground,
                        keyboardType: .numberPad
                    )
                    .frame(width: 80)
                    
                    // Category Dropdown
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(TextSecondary)
                        
                        Menu {
                            ForEach(Category.allCases, id: \.self) { cat in
                                Button(action: {
                                    category = cat
                                }) {
                                    HStack {
                                        Text(cat.rawValue)
                                        if category == cat {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(category?.rawValue ?? "Select")
                                    .foregroundColor(category == nil ? TextSecondary : TextPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(TextSecondary)
                            }
                            .padding(12)
                            .background(InputBackground)
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Description
                FoodAppTextField(
                    value: $description,
                    placeholder: "Describe the taste, texture, and ingredients...",
                    label: "Description",
                    bgColor: InputBackground,
                    singleLine: false,
                    minLines: 3
                )
            }
            .padding(16)
            .background(SurfaceWhite)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: 0xFFEEEEEE), lineWidth: 1)
            )
        }
    }
}

// MARK: - Ingredients Section
struct CreateIngredientsSection: View {
    @Binding var ingredients: [CreateIngredientUi]
    @Binding var newIngredient: String
    @Binding var newIngredientSupportsIntensity: Bool
    @Binding var newIngredientIntensityType: IntensityType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(TextPrimary)
            
            Text("What's inside? Users love transparency.")
                .font(.system(size: 12))
                .foregroundColor(TextSecondary)
            
            VStack(spacing: 16) {
                // Input Row
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        FoodAppTextField(
                            value: $newIngredient,
                            placeholder: "Add ingredient...",
                            bgColor: InputBackground
                        )
                        
                        Button(action: {
                            let trimmedName = newIngredient.trimmingCharacters(in: .whitespaces)
                            if !trimmedName.isEmpty && !ingredients.contains(where: { $0.name == trimmedName }) {
                                ingredients.append(CreateIngredientUi(
                                    name: trimmedName,
                                    supportsIntensity: newIngredientSupportsIntensity,
                                    intensityType: newIngredientSupportsIntensity ? newIngredientIntensityType : nil
                                ))
                                newIngredient = ""
                                newIngredientSupportsIntensity = false
                                newIngredientIntensityType = nil
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(PrimaryBrand)
                                .clipShape(Circle())
                        }
                    }
                    
                    // Intensity Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Toggle("Enable intensity slider", isOn: $newIngredientSupportsIntensity)
                                .toggleStyle(CheckboxToggleStyle())
                                .tint(PrimaryBrand)
                        }
                        
                        if newIngredientSupportsIntensity {
                            IntensityTypeSelector(
                                selectedType: $newIngredientIntensityType
                            )
                        }
                    }
                }
                
                // Current Ingredients List
                if !ingredients.isEmpty {
                    Divider()
                        .background(Color(hex: 0xFFF0F0F0))
                    
                    VStack(spacing: 8) {
                        ForEach(ingredients.indices, id: \.self) { index in
                            CreateIngredientRow(
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
            }
            .padding(16)
            .background(SurfaceWhite)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: 0xFFEEEEEE), lineWidth: 1)
            )
        }
    }
}

// MARK: - Ingredient Row
struct CreateIngredientRow: View {
    let ingredient: CreateIngredientUi
    let onDelete: () -> Void
    @State private var intensityValue: Float = 0.5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(PrimaryBrand)
                    .frame(width: 6, height: 6)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(TextPrimary)
                    
                    if ingredient.supportsIntensity {
                        Text("Intensity: Adjustable")
                            .font(.system(size: 10))
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
        .padding(.horizontal, 12)
        .background(Color(hex: 0xFFFAFAFA))
        .cornerRadius(8)
    }
}

// MARK: - Options Section
struct CreateOptionsSection: View {
    @Binding var options: [CreateOptionUi]
    @Binding var newOptionName: String
    @Binding var newOptionPrice: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extras & Add-ons")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(TextPrimary)
            
            VStack(spacing: 16) {
                // Input Row
                HStack(spacing: 8) {
                    FoodAppTextField(
                        value: $newOptionName,
                        placeholder: "Name (e.g. Cheese)",
                        bgColor: InputBackground
                    )
                    
                    FoodAppTextField(
                        value: $newOptionPrice,
                        placeholder: "Price",
                        bgColor: InputBackground,
                        keyboardType: .decimalPad
                    )
                    .frame(width: 80)
                    
                    Button(action: {
                        guard let price = Double(newOptionPrice), !newOptionName.isEmpty, price >= 0 else { return }
                        options.append(CreateOptionUi(name: newOptionName.trimmingCharacters(in: .whitespaces), priceStr: newOptionPrice))
                        newOptionName = ""
                        newOptionPrice = ""
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(PrimaryBrand)
                            .clipShape(Circle())
                    }
                }
                
                // Current Options List
                if !options.isEmpty {
                    Divider()
                        .background(Color(hex: 0xFFF0F0F0))
                    
                    VStack(spacing: 8) {
                        ForEach(options.indices, id: \.self) { index in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(options[index].name)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(TextPrimary)
                                    Text("+ \(options[index].priceStr) TND")
                                        .font(.system(size: 12))
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
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(Color(hex: 0xFFFAFAFA))
                            .cornerRadius(12)
                            
                            if index < options.count - 1 {
                                Divider()
                                    .background(Color(hex: 0xFFF0F0F0))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(SurfaceWhite)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: 0xFFEEEEEE), lineWidth: 1)
            )
        }
    }
}

// MARK: - Bottom Bar Section
struct BottomBarSection: View {
    let localError: String?
    let viewModelState: MenuItemUiState
    let isLoading: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Error Display
            if let localErr = localError {
                Text(localErr)
                    .font(.system(size: 12))
                    .foregroundColor(ErrorColor)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: 0xFFFFEBEE))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            } else if case .error(let message) = viewModelState {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(ErrorColor)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: 0xFFFFEBEE))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            
            // Confirm Button
            Button(action: onConfirm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: TextPrimary))
                        .frame(height: 56)
                } else {
                    Text("Save to Menu")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(TextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
            }
            .disabled(isLoading)
            .background(PrimaryBrand)
            .cornerRadius(30)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(SurfaceWhite)
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
    }
}

// MARK: - Food App Text Field
struct FoodAppTextField: View {
    @Binding var value: String
    var placeholder: String
    var label: String? = nil
    var bgColor: Color
    var singleLine: Bool = true
    var minLines: Int = 1
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label = label {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(TextSecondary)
            }
            
            if singleLine {
                TextField(placeholder, text: $value)
                    .keyboardType(keyboardType)
                    .padding(12)
                    .background(bgColor)
                    .cornerRadius(12)
            } else {
                TextEditor(text: $value)
                    .frame(minHeight: CGFloat(minLines * 20))
                    .padding(8)
                    .background(bgColor)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Intensity Type Selector
struct IntensityTypeSelector: View {
    @Binding var selectedType: IntensityType?
    
    private let intensityTypes: [(IntensityType, String, String)] = [
        (.coffee, "☕", "Coffee"),
        (.harissa, "🌶️", "Harissa"),
        (.sauce, "🍯", "Sauce"),
        (.spice, "🌿", "Spice"),
        (.sugar, "🍬", "Sugar"),
        (.salt, "🧂", "Salt"),
        (.pepper, "🫚", "Pepper"),
        (.chili, "🌶️", "Chili"),
        (.garlic, "🧄", "Garlic"),
        (.lemon, "🍋", "Lemon"),
        (.custom, "⭐", "Custom")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Intensity Type:")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(TextSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(intensityTypes, id: \.0) { type, emoji, label in
                        Button(action: {
                            selectedType = selectedType == type ? nil : type
                        }) {
                            HStack(spacing: 6) {
                                Text(emoji)
                                    .font(.system(size: 16))
                                Text(label)
                                    .font(.system(size: 12, weight: selectedType == type ? .semibold : .regular))
                                    .foregroundColor(selectedType == type ? TextPrimary : TextSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedType == type ? PrimaryBrand : InputBackground)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(selectedType == type ? PrimaryBrand : Color(hex: 0xFFE0E0E0), lineWidth: selectedType == type ? 2 : 1)
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Button(action: {
                configuration.isOn.toggle()
            }) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? PrimaryBrand : TextSecondary)
                    .font(.system(size: 20))
            }
        }
    }
}

// MARK: - Success Dialog
struct CreateSuccessDialog: View {
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
                
                Text("Item created successfully!")
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

// MARK: - Error Dialog
struct CreateErrorDialog: View {
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
                
                Text("Creation Failed")
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

// MARK: - Color Extension (using existing extension from Color.swift)
// Extension removed - using existing Color(hex:) from screens/feature_auth/ui/Color.swift

