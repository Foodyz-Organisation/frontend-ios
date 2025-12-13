import SwiftUI
import PhotosUI


struct CreateMenuItemScreen: View {
    @ObservedObject var viewModel: MenuViewModel
    var professionalId: String
    @Binding var path: NavigationPath // 🟢 ADDED: Binding to the root NavigationPath
    
    // ---------- Form State ----------
    @State private var name = ""
    // ... (rest of state variables)
    @State private var description = ""
    @State private var priceText = ""
    @State private var category = ""
    
    @State private var ingredients: [String] = []
    @State private var options: [CreateOptionUi] = []
    
    @State private var newIngredient = ""
    @State private var newOptionName = ""
    @State private var newOptionPrice = ""
    
    @State private var selectedImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var localError: String? = nil
    @State private var isCategoryDropdownExpanded = false
    
    let yellowAccent = Color.yellow.opacity(0.8)
    let lightGrayBackground = Color(white: 0.95)
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // MARK: - Item Details
                    GroupBox("Item Details") {
                        VStack(spacing: 12) {
                            TextField("Name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Price (TND)", text: $priceText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextEditor(text: $description)
                                .frame(minHeight: 60)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
                            
                            // Category picker
                            Menu {
                                ForEach(Category.allCases, id: \.self) { cat in
                                    Button(cat.rawValue) { category = cat.rawValue }
                                }
                            } label: {
                                HStack {
                                    Text(category.isEmpty ? "Select Category" : category)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // MARK: - Image Picker
                    GroupBox("Item Image") {
                        VStack {
                            if let img = selectedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                                    .overlay(Image(systemName: "photo").font(.largeTitle))
                                    .cornerRadius(12)
                            }
                            Button(selectedImage == nil ? "Select Image" : "Change Image") {
                                showingImagePicker = true
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    // MARK: - Ingredients
                    GroupBox("Ingredients") {
                        VStack(spacing: 8) {
                            HStack {
                                TextField("New Ingredient", text: $newIngredient)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: {
                                    if !newIngredient.isEmpty && !ingredients.contains(newIngredient) {
                                        ingredients.append(newIngredient)
                                        newIngredient = ""
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .padding(6)
                                        .background(yellowAccent)
                                        .clipShape(Circle())
                                }
                            }
                            
                            ForEach(ingredients.indices, id: \.self) { i in
                                HStack {
                                    Text(ingredients[i])
                                    Spacer()
                                    Button(action: { ingredients.remove(at: i) }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                    
                    // MARK: - Options
                    GroupBox("Options") {
                        VStack(spacing: 8) {
                            HStack {
                                TextField("Option Name", text: $newOptionName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                TextField("Price", text: $newOptionPrice)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: {
                                    if let price = Double(newOptionPrice), !newOptionName.isEmpty, price >= 0 {
                                        options.append(CreateOptionUi(name: newOptionName, priceStr: newOptionPrice))
                                        newOptionName = ""
                                        newOptionPrice = ""
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .padding(6)
                                        .background(yellowAccent)
                                        .clipShape(Circle())
                                }
                            }
                            
                            ForEach(options.indices, id: \.self) { i in
                                HStack {
                                    Text("\(options[i].name) (+\(options[i].priceStr) TND)")
                                    Spacer()
                                    Button(action: { options.remove(at: i) }) {
                                        Image(systemName: "trash").foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            
            // MARK: - Error & Confirm Button
            VStack {
                if let err = localError {
                    Text(err).foregroundColor(.red)
                }
                if case .error(let msg) = viewModel.uiState {
                    Text(msg).foregroundColor(.red)
                }
                
                Button(action: {
                    localError = nil
                    guard !name.isEmpty, !category.isEmpty else {
                        localError = "Name & Category required"
                        return
                    }
                    guard let price = Double(priceText), price >= 0 else {
                        localError = "Enter valid price"
                        return
                    }
                    guard let img = selectedImage else {
                        localError = "Select an image"
                        return
                    }
                    
                    // Convert ingredients & options
                    let dto = CreateMenuItemDto(
                        professionalId: professionalId,
                        name: name,
                        description: description,
                        price: price,
                        category: Category(rawValue: category)!,
                        ingredients: ingredients.map { IngredientDto(name: $0, isDefault: true) },
                        options: options.map { OptionDto(name: $0.name, price: Double($0.priceStr)!) }
                    )
                    
                    viewModel.createMenuItem(payload: dto, image: img, token: "YOUR_JWT_TOKEN")
                }) {
                    if case .loading = viewModel.uiState {
                        ProgressView().padding()
                    } else {
                        Text("Confirm Item").bold().frame(maxWidth: .infinity, minHeight: 50)
                            .background(yellowAccent).cornerRadius(12).foregroundColor(.black)
                    }
                }
                // 🟢 ADDED: Logic to pop the view on successful creation
                .onReceive(viewModel.$uiState) { state in
                    if case .success = state {
                        // Pop the current view from the stack
                        path.removeLast()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Create New Item") // Added title for clarity
        .sheet(isPresented: $showingImagePicker) {
            UIKitImagePicker(image: $selectedImage)
        }
    }
}
// MARK: - Image Picker (UIKit wrapper)
private struct UIKitImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator  // ✅ correct
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: UIKitImagePicker
        init(_ parent: UIKitImagePicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first?.itemProvider,
                  item.canLoadObject(ofClass: UIImage.self) else { return }
            item.loadObject(ofClass: UIImage.self) { img, _ in
                DispatchQueue.main.async { self.parent.image = img as? UIImage }
            }
        }
    }
}

// MARK: - Helper structs
struct CreateOptionUi { var name: String; var priceStr: String }

