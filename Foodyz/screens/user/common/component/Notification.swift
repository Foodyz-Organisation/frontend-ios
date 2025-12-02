import SwiftUI

struct NotificationDropdownView: View {
    @Binding var showNotifications: Bool
    var unreadCount: Int = 3
    var notifications: [String] = [
        "New follower: Alice",
        "Order ready for pickup!",
        "Your post got 10 likes!"
    ]
    var onSelectNotification: ((String) -> Void)? = nil
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Notification Icon Button
            Button(action: {
                showNotifications.toggle()
            }) {
                Image(systemName: "bell.fill")
                    .resizable()
                    .frame(width: 26, height: 26)
                    .foregroundColor(Color("DarkGray"))
                    .padding(9)
                    .background(Color("LightGray"))
                    .clipShape(Circle())
            }
            
            // Badge
            if unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
            
            // Dropdown Menu
            if showNotifications {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Notifications (\(unreadCount) new)")
                        .fontWeight(.bold)
                        .padding(12)
                    
                    Divider()
                    
                    ForEach(notifications.prefix(3), id: \.self) { message in
                        Button(action: {
                            showNotifications = false
                            onSelectNotification?(message)
                        }) {
                            Text(message)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color("DropdownItemBG"))
                        }
                        Divider()
                    }
                    
                    Button(action: {
                        showNotifications = false
                    }) {
                        Text("View All")
                            .fontWeight(.semibold)
                            .padding()
                    }
                }
                .frame(width: 280)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 4)
                .offset(y: 50)
            }
        }
        .animation(.easeInOut, value: showNotifications)
    }
}

// MARK: - Preview
struct NotificationDropdownView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(false) { AnyView(NotificationDropdownView(showNotifications: $0)) }
    }
}

// Helper for preview with @Binding
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ initialValue: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
