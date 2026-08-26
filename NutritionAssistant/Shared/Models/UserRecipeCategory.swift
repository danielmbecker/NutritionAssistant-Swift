import Foundation
import SwiftData

@Model
final class UserRecipeCategory {
    var id: UUID = UUID()
    var name: String
    
    init(name: String) {
        self.name = name
    }
}
