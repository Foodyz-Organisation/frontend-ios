import Foundation

/// Ingredient DTO matching backend schema 100%
struct IngredientDto: Codable {
    let name: String
    let isDefault: Bool
    let supportsIntensity: Bool
    let intensityType: IntensityType?
    let intensityColor: String? // Hex color string
    
    enum CodingKeys: String, CodingKey {
        case name
        case isDefault
        case supportsIntensity
        case intensityType
        case intensityColor
    }
    
    // Custom decoder to handle optional fields with defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        isDefault = try container.decode(Bool.self, forKey: .isDefault)
        supportsIntensity = try container.decodeIfPresent(Bool.self, forKey: .supportsIntensity) ?? false
        intensityType = try container.decodeIfPresent(IntensityType.self, forKey: .intensityType)
        intensityColor = try container.decodeIfPresent(String.self, forKey: .intensityColor)
    }
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isDefault, forKey: .isDefault)
        try container.encode(supportsIntensity, forKey: .supportsIntensity)
        try container.encodeIfPresent(intensityType, forKey: .intensityType)
        try container.encodeIfPresent(intensityColor, forKey: .intensityColor)
    }
    
    // Convenience initializer for creating ingredients
    init(name: String, isDefault: Bool, supportsIntensity: Bool = false, intensityType: IntensityType? = nil, intensityColor: String? = nil) {
        self.name = name
        self.isDefault = isDefault
        self.supportsIntensity = supportsIntensity
        self.intensityType = intensityType
        self.intensityColor = intensityColor
    }
}

