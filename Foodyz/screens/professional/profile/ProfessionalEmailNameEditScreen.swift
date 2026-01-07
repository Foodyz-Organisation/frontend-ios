import SwiftUI

struct ProfessionalEmailNameEditScreen: View {
    @Environment(\.dismiss) var dismiss
    
    // State variables for form fields
    @State private var email: String = "charlot@gmail.com"
    @State private var businessName: String = "charlot"
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            ZStack(alignment: .leading) {
                Color.orange // Match Color.foodyzOrange
                    .ignoresSafeArea(edges: .top)
                
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 16)
                    
                    Text("Email & Name")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading, 16)
                    
                    Spacer()
                    
                    // Checkmark/Save Button
                    Button(action: {
                        // TODO: Save Action
                        dismiss()
                    }) {
                        Image(systemName: "checkmark.circle.fill") // Design uses a checkmark in circle
                            .font(.system(size: 24, weight: .bold)) // Slightly larger
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 16)
            }
            .frame(height: 60)
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 1. Email
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.orange)
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // 2. Business Name
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Business Name")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(.orange)
                            TextField("Business Name", text: $businessName)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ProfessionalEmailNameEditScreen()
}
