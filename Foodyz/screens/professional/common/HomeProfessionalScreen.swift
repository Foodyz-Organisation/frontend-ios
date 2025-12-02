import SwiftUI

struct HomeProfessionalView: View {
    var onOpenMessages: (() -> Void)? = nil

    var body: some View {
        VStack {
            Text("Hello, Professional!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Button {
                onOpenMessages?()
            } label: {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Messages")
                        .fontWeight(.semibold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(12)
            }
            .padding()
            
            Spacer()
        }
    }
}

#Preview {
    HomeProfessionalView()
}
