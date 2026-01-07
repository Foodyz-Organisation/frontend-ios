import SwiftUI

struct FoodyzTopBar: View {
    @Binding var path: NavigationPath
    var professionalId: String
    var openDrawer: () -> Void
    var onProfileClick: (() -> Void)? = nil
    var onLocationClick: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            // Logo/Avatar
            Button(action: { 
                print("DEBUG: Profile icon clicked in FoodyzTopBar")
                onProfileClick?() 
            }) {
                Image("burger_logo_placeholder") // Replace with valid asset or system image
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay {
                        if UIImage(named: "burger_logo_placeholder") == nil {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.black)
                        }
                    }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Foodyz Pro")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
            
            // Location Picker Icon (map pin)
            Button(action: {
                onLocationClick?()
            }) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.foodyzOrange)
            }
            .padding(.trailing, 12)
            
            // Drawer Button
            Button(action: openDrawer) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 15)
        .background(Color.white)
    }
}
