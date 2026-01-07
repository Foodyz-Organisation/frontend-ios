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
    var iconColor: Color = .gray // Default to gray

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }
}

// MARK: - CustomSecureField
struct CustomSecureField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    var iconColor: Color = .gray // Default to gray

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .autocapitalization(.none)
            } else {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
            }
            
            Spacer()
            
            Button(action: {
                showPassword.toggle()
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }
}

