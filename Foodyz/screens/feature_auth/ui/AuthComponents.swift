import SwiftUI

// MARK: - LoginTextField
struct LoginTextField<TrailingContent: View>: View {
    var icon: String
    var title: String
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool = false
    var trailingIcon: TrailingContent

    init(icon: String, title: String, text: Binding<String>, placeholder: String, isSecure: Bool = false, @ViewBuilder trailingIcon: () -> TrailingContent) {
        self.icon = icon
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
        self.trailingIcon = trailingIcon()
    }

    init(icon: String, title: String, text: Binding<String>, placeholder: String, isSecure: Bool = false) where TrailingContent == EmptyView {
        self.icon = icon
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
        self.trailingIcon = EmptyView()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.gray)

            HStack {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
                trailingIcon
            }
            .padding(.horizontal, 12)
            .frame(height: 50)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.5), lineWidth: 1))
        }
    }
}

// MARK: - CustomTextField
struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.gray)
            TextField(placeholder, text: $text).keyboardType(keyboardType).autocapitalization(.none)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - CustomSecureField
struct CustomSecureField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.gray)
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
