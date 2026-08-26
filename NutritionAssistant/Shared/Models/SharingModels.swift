import Foundation
import SwiftData
import UniformTypeIdentifiers
import SwiftUI

/// Data Transfer Object specifically meant for JSON encoding/decoding
struct RecipeItemDTO: Codable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var type: String
    var measurementType: RecipeMeasurementType
    var ingredients: [RecipeIngredient]
    var category: String
    var customBatchWeight: Double?
    var finalWeightPostponed: Bool?
    var servingSize: Double?
}

/// A Codable container representing the full exported JSON file structure
private struct AppSharingDocumentDTO: Sendable {
    var recipes: [RecipeItemDTO]?
    // Future Expansion:
    // var foods: [FoodItemDTO]?
    // var consumedItems: [ConsumedItemDTO]?
}

extension AppSharingDocumentDTO: Encodable {
    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(recipes, forKey: .recipes)
    }
}

extension AppSharingDocumentDTO: Decodable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.recipes = try container.decodeIfPresent([RecipeItemDTO].self, forKey: .recipes)
    }
}

extension AppSharingDocumentDTO {
    enum CodingKeys: String, CodingKey {
        case recipes
    }
}

/// The FileDocument used by SwiftUI's fileExporter/fileImporter
struct AppSharingDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var recipes: [RecipeItemDTO]?
    
    init(recipes: [RecipeItemDTO]? = nil) {
        self.recipes = recipes
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let backup = try AppSharingDocument.decode(data)
        self.recipes = backup.recipes
    }
    
    private nonisolated static func decode(_ data: Data) throws -> AppSharingDocumentDTO {
        try JSONDecoder().decode(AppSharingDocumentDTO.self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try AppSharingDocument.encode(recipes: recipes)
        return FileWrapper(regularFileWithContents: data)
    }
    
    private nonisolated static func encode(recipes: [RecipeItemDTO]?) throws -> Data {
        let backup = AppSharingDocumentDTO(recipes: recipes)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Makes the JSON human-readable
        return try encoder.encode(backup)
    }
}
