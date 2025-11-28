import SwiftUI

// Assuming DTOs and ViewModel are available in scope
// struct UpdateMenuItemDto: ...
// struct IngredientDto: ...
// struct OptionDto: ...
// enum Category: ...
// class MenuViewModel: ...

struct ItemDetailsView: View {
    
    // Use dismiss for modal or simple stack dismissal
    @Environment(\.dismiss) var dismiss
    
    // If using a custom NavigationPath:
    // @Binding var path: NavigationPath
    
    @ObservedObject var viewModel: MenuViewModel
    let itemId: String
    let professionalId: String

    @State private var selectedTab = 0
    @State private var name = ""
    @State private var description = ""
    @State private var price = ""
    @State private var category: Category? = nil
    @State private var ingredients: [IngredientDto] = []
    @State private var options: [OptionDto] = []

    private let tabs = ["Info", "Ingredients", "Options"]
    private let dummyToken = "YOUR_AUTH_TOKEN"

    var body: some View {
        VStack {
            // Top Bar
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.backward")
                }
                Spacer()
                Text("Edit Item").font(.headline)
                Spacer()
            }.padding()

            // Tabs
            Picker("Tabs", selection: $selectedTab) {
                ForEach(0..<tabs.count, id: \.self) { idx in
                    Text(tabs[idx]).tag(idx)
                }
            }.pickerStyle(SegmentedPickerStyle())
            .padding([.leading, .trailing])

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case 0:
                        // Info Tab
                        VStack(spacing: 12) {
                            TextField("Name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Price", text: $price)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                            TextEditor(text: $description)
                                .frame(height: 80)
                                .border(Color.gray)
                        }.padding()
                    case 1:
                        // Ingredients Tab
                        IngredientsEditor(ingredients: $ingredients)
                    case 2:
                        // Options Tab
                        OptionsEditor(options: $options)
                    default: EmptyView()
                    }
                }.padding()
            }

            // Save Button
            Button(action: saveChanges) {
                Text("Confirm Changes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }.padding()
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.fetchMenuItemDetails(id: itemId, token: dummyToken)
        }
        .onReceive(viewModel.$itemDetailsUiState) { state in
            if case let .success(item) = state {
                name = item.name
                description = item.description ?? ""
                price = String(item.price)
                ingredients = item.ingredients
                options = item.options
            }
        }
        // 🟢 FIXED: Observe the existing general state publisher $uiState
        .onReceive(viewModel.$uiState) { state in
            if case .success = state {
                // Dismiss the view upon successful update (create/update/delete)
                dismiss()
                // Optionally, reset the state so subsequent updates work cleanly
                viewModel.resetUiState()
            }
        }
    }

    func saveChanges() {
        guard let priceValue = Double(price) else { return }
        let updateDto = UpdateMenuItemDto(
            name: name,
            description: description,
            price: priceValue,
            category: category,
            ingredients: ingredients,
            options: options
        )
        // This update call triggers the change in viewModel.$uiState
        viewModel.updateMenuItem(id: itemId, payload: updateDto, professionalId: professionalId, token: dummyToken)
    }
}

// MARK: - IngredientsEditor
struct IngredientsEditor: View {
    @Binding var ingredients: [IngredientDto]
    @State private var newIngredient = ""

    var body: some View {
        VStack {
            HStack {
                TextField("New Ingredient", text: $newIngredient)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: addIngredient) { Image(systemName: "plus") }
            }
            ForEach(ingredients.indices, id: \.self) { i in
                HStack {
                    Text(ingredients[i].name)
                    Spacer()
                    Button(action: { ingredients.remove(at: i) }) {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                }.padding(.vertical, 4)
            }
        }
        .padding(.horizontal)
    }

    func addIngredient() {
        if !newIngredient.isEmpty {
            ingredients.append(IngredientDto(name: newIngredient, isDefault: true))
            newIngredient = ""
        }
    }

}

// MARK: - OptionsEditor
struct OptionsEditor: View {
    @Binding var options: [OptionDto]
    @State private var newName = ""
    @State private var newPrice = ""

    var body: some View {
        VStack {
            HStack {
                TextField("Option Name", text: $newName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Price", text: $newPrice)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                Button(action: addOption) { Image(systemName: "plus") }
            }
            ForEach(options.indices, id: \.self) { i in
                HStack {
                    Text("\(options[i].name) (+\(String(format: "%.2f", options[i].price)))")
                    Spacer()
                    Button(action: { options.remove(at: i) }) {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                }.padding(.vertical, 4)
            }
        }
        .padding(.horizontal)
    }
    func addOption() {
        if let priceValue = Double(newPrice), !newName.isEmpty {
            options.append(OptionDto(name: newName, price: priceValue))
            newName = ""
            newPrice = ""
        }
    }
}
