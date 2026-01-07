import SwiftUI
import PhotosUI

struct ProfessionalDataEditScreen: View {
    @Environment(\.dismiss) var dismiss
    
    // State variables for form fields
    @State private var description: String = ""
    @State private var phoneNumber: String = ""
    @State private var workingHours: String = ""
    @State private var locations: [LocationDto] = [] // Using DTO for locations
    
    // Image Picking States
    @State private var selectedProfileItem: PhotosPickerItem?
    @State private var selectedProfileData: Data?
    @State private var profileImage: Image?
    
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var selectedCoverData: Data?
    @State private var coverImage: Image?
    
    // Loading State
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Current Professional Data
    @State private var currentProfessional: ProfessionalDto?
    
    // Location Management
    @State private var showLocationPicker = false
    @State private var selectedLocationForEdit: LocationDto?
    @State private var editingLocationIndex: Int?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: - Header
                ZStack(alignment: .leading) {
                    Color(hex: "#F59E0B") // App theme color (orange)
                        .ignoresSafeArea(edges: .top)
                    
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.leading, 16)
                        
                        Text("Profile Settings")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.leading, 16)
                        
                        Spacer()
                        
                        // Location Picker Icon
                        Button(action: {
                            selectedLocationForEdit = nil
                            editingLocationIndex = nil
                            showLocationPicker = true
                        }) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 8)
                        
                        // Save Button
                        Button(action: saveProfile) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 16)
                        .disabled(isSaving)
                    }
                    .padding(.bottom, 16)
                }
                .frame(height: 60)
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading Profile...")
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            // 1. Profile Picture
                            VStack(spacing: 12) {
                                Text("Profile Picture")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ZStack {
                                    Circle()
                                        .stroke(Color.orange, lineWidth: 2)
                                        .background(Circle().fill(Color.black.opacity(0.1)))
                                        .frame(width: 100, height: 100)
                                    
                                    if let profileImage = profileImage {
                                        profileImage
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    } else if let urlStr = currentProfessional?.avatarUrl, 
                                              let url = URL(string: urlStr.replacingOccurrences(of: "10.0.2.2", with: "127.0.0.1")) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image.resizable().scaledToFill()
                                            } else {
                                                Image(systemName: "person.fill").foregroundColor(.gray)
                                            }
                                        }
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                PhotosPicker(selection: $selectedProfileItem, matching: .images) {
                                    Text("Change Profile Picture")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .onChange(of: selectedProfileItem) { newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            selectedProfileData = data
                                            profileImage = Image(uiImage: uiImage)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            // 2. Background Image
                            VStack(spacing: 12) {
                                Text("Background Image")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ZStack {
                                    Rectangle()
                                        .stroke(Color.orange, lineWidth: 1)
                                        .background(Color.gray.opacity(0.1))
                                        .frame(height: 150)
                                        .cornerRadius(8)
                                    
                                    if let coverImage = coverImage {
                                        coverImage
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 150)
                                            .clipped()
                                            .cornerRadius(8)
                                    } else if let urlStr = currentProfessional?.coverUrl,
                                              let url = URL(string: urlStr.replacingOccurrences(of: "10.0.2.2", with: "127.0.0.1")) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image.resizable().scaledToFill()
                                            } else {
                                                Color.gray.opacity(0.3)
                                            }
                                        }
                                        .frame(height: 150)
                                        .clipped()
                                        .cornerRadius(8)
                                    } else {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                PhotosPicker(selection: $selectedCoverItem, matching: .images) {
                                    Text("Change Background Image")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .onChange(of: selectedCoverItem) { newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            selectedCoverData = data
                                            coverImage = Image(uiImage: uiImage)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            // 3. Description
                            VStack(spacing: 12) {
                                Text("Description")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                TextEditor(text: $description)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            // 4. Phone Number
                            VStack(spacing: 12) {
                                Text("Phone Number")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.orange)
                                    TextField("Phone Number", text: $phoneNumber)
                                        .keyboardType(.phonePad)
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
                            
                            // 5. Working Hours
                            VStack(spacing: 12) {
                                Text("Working Hours")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.orange)
                                    TextField("Working Hours", text: $workingHours)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                
                                Text("Example: 17:00 - 00:00, Monday to Friday")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            // 6. Locations (Editable - Add/Remove multiple locations)
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Locations")
                                        .font(.headline)
                                    Spacer()
                                    Button(action: {
                                        selectedLocationForEdit = nil
                                        editingLocationIndex = nil
                                        showLocationPicker = true
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Location")
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#F59E0B"))
                                    }
                                }
                                
                                if locations.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "mappin.circle")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray.opacity(0.5))
                                        Text("No locations added")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("Tap 'Add Location' to add your first location")
                                            .font(.caption)
                                            .foregroundColor(.gray.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                } else {
                                    ForEach(Array(locations.enumerated()), id: \.offset) { index, location in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(location.name ?? "Unknown Location")
                                                        .font(.headline)
                                                        .foregroundColor(.black)
                                                    
                                                    if let address = location.address, !address.isEmpty {
                                                        Text(address)
                                                            .font(.subheadline)
                                                            .foregroundColor(.gray)
                                                    } else {
                                                        Text("Lat: \(String(format: "%.6f", location.lat ?? 0)), Lon: \(String(format: "%.6f", location.lon ?? 0))")
                                                            .font(.caption)
                                                            .foregroundColor(.gray)
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                // Edit button
                                                Button(action: {
                                                    selectedLocationForEdit = location
                                                    editingLocationIndex = index
                                                    showLocationPicker = true
                                                }) {
                                                    Image(systemName: "pencil.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(Color(hex: "#F59E0B"))
                                                }
                                                
                                                // Delete button
                                                Button(action: {
                                                    locations.remove(at: index)
                                                }) {
                                                    Image(systemName: "trash.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.red)
                                                }
                                            }
                                            
                                            if index < locations.count - 1 {
                                                Divider()
                                                    .padding(.top, 8)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
            .onAppear(perform: loadProfile)
            .sheet(isPresented: $showLocationPicker) {
                ProMapPickerView(
                    selectedLocation: Binding(
                        get: { selectedLocationForEdit },
                        set: { newLocation in
                            if let location = newLocation {
                                if let editIndex = editingLocationIndex, editIndex < locations.count {
                                    // Update existing location
                                    locations[editIndex] = location
                                } else {
                                    // Add new location
                                    locations.append(location)
                                }
                                selectedLocationForEdit = nil
                                editingLocationIndex = nil
                            }
                            showLocationPicker = false
                        }
                    )
                )
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - Functions
    
    private func loadProfile() {
        guard let id = TokenManager.shared.getUserId() else { return }
        isLoading = true
        
        ProfessionalRepository.shared.getProfessionalById(id: id) { result in
            isLoading = false
            switch result {
            case .success(let pro):
                self.currentProfessional = pro
                self.description = pro.description ?? ""
                self.phoneNumber = pro.phone ?? ""
                self.workingHours = pro.hours ?? ""
                self.locations = pro.locations ?? []
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    private func saveProfile() {
        guard let id = TokenManager.shared.getUserId() else { return }
        isSaving = true
        
        Task {
            var avatarUrl: String? = currentProfessional?.avatarUrl
            var coverUrl: String? = currentProfessional?.coverUrl
            
            // 1. Upload Profile Picture if changed
            if let profileData = selectedProfileData {
                do {
                    let response = try await PostsAPI.shared.uploadMedia(mediaData: [profileData], isVideoArray: [false])
                    if let newUrl = response.urls.first {
                        avatarUrl = newUrl
                    }
                } catch {
                    print("Error uploading profile picture: \(error)")
                    // Continue or fail? Let's continue.
                }
            }
            
            // 2. Upload Cover Image if changed
            if let coverData = selectedCoverData {
                do {
                    let response = try await PostsAPI.shared.uploadMedia(mediaData: [coverData], isVideoArray: [false])
                    if let newUrl = response.urls.first {
                        coverUrl = newUrl
                    }
                } catch {
                    print("Error uploading cover image: \(error)")
                }
            }
            
            // 3. Update Profile Data
            // Convert locations to dictionary format for API
            let locationsDict = locations.map { location -> [String: Any] in
                var dict: [String: Any] = [:]
                if let name = location.name { dict["name"] = name }
                if let address = location.address { dict["address"] = address }
                if let lat = location.lat { dict["lat"] = lat }
                if let lon = location.lon { dict["lon"] = lon }
                return dict
            }
            
            let updates: [String: Any] = [
                "description": description,
                "phone": phoneNumber,
                "hours": workingHours,
                "profilePictureUrl": avatarUrl ?? "", // Map to correct backend key
                "imageUrl": coverUrl ?? "", // Map cover to imageUrl
                "locations": locationsDict // Include locations array
            ]
            
            ProfessionalRepository.shared.updateProfessional(id: id, dto: updates) { result in
                DispatchQueue.main.async {
                    self.isSaving = false
                    switch result {
                    case .success:
                        self.dismiss()
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                }
            }
        }
    }
}

#Preview {
    ProfessionalDataEditScreen()
}
