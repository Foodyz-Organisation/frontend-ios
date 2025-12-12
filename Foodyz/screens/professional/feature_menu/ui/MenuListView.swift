import SwiftUI

let BASE_URL = "http://localhost:3000/"

// MARK: - MenuItemManagementScreen (Container View)
struct MenuItemManagementScreen: View {
    @ObservedObject var viewModel: MenuViewModel
    var professionalId: String
    let dummyAuthToken = "YOUR_PROFESSIONAL_AUTH_TOKEN"
    @Binding var path: NavigationPath // BINDING TO THE ROOT NAVIGATION STACK
    
    var body: some View {
        // ❌ REMOVED: NavigationView is provided by AppNavigation/NavigationStack
        ZStack {
            content
            floatingButton
        }
        .navigationTitle("Menu Items")
        .onAppear {
            viewModel.fetchGroupedMenu(professionalId: professionalId, token: dummyAuthToken)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.menuListUiState {
        case .idle:
            Text("Idle state")
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            Text("Error: \(message)").foregroundColor(.red)
        case .success(let groupedMenu):
            if groupedMenu.isEmpty {
                Text("No items yet. Click + to create one.")
            } else {
                MenuSectionList(viewModel: viewModel,
                                path: $path, // 🟢 PASS PATH
                                professionalId: professionalId,
                                groupedMenu: groupedMenu)
            }
        }
    }

    private var floatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    // NAVIGATE TO CREATE SCREEN
                    path.append(Screen.createMenuItem(professionalId))
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.yellow)
                        .clipShape(Circle())
                }
                .padding()
            }
        }
    }
}

// MARK: - MenuSectionList
struct MenuSectionList: View {
    @ObservedObject var viewModel: MenuViewModel
    @Binding var path: NavigationPath // REQUIRED: Path to pass down
    var professionalId: String
    var groupedMenu: [String: [MenuItemResponse]]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedMenu.keys.sorted(), id: \.self) { category in
                    VStack(alignment: .leading) {
                        Text(category)
                            .font(.headline)
                            .foregroundColor(.blue)
                        Divider().padding(.vertical, 4)

                        ForEach(groupedMenu[category] ?? [], id: \.id) { item in
                            // PASS THE PATH BINDING HERE
                            MenuItemCard(viewModel: viewModel,
                                         path: $path, // 🟢 PATH PASSED
                                         item: item,
                                         professionalId: professionalId)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - MenuItemCard
struct MenuItemCard: View {
    @ObservedObject var viewModel: MenuViewModel
    @Binding var path: NavigationPath // ⭐️ NEW: Added path binding
    var item: MenuItemResponse
    var professionalId: String

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                AsyncImage(url: URL(string: BASE_URL + item.image)) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading) {
                    HStack {
                        Text(item.name).font(.title3)
                        Spacer()
                        Text(String(format: "$%.2f", item.price))
                            .foregroundColor(.secondary)
                    }
                    Text(item.description ?? "No description")
                        .lineLimit(1)
                        .foregroundColor(.gray)
                }
            }

            HStack {
                Button("Edit") {
                    // 🟢 IMPLEMENT NAVIGATION TO EDIT SCREEN
                    let navItem = MenuNavigationItem(professionalId: professionalId, itemId: item.id)
                    path.append(Screen.editMenuItem(navItem))
                }
                Spacer()
                Button("Delete") {
                    viewModel.deleteMenuItem(id: item.id, professionalId: professionalId, token: "YOUR_PROFESSIONAL_AUTH_TOKEN")
                }
                .foregroundColor(.red)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
