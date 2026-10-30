import Foundation
import SwiftData

/// A user-added household measurement unit (canonical singular name) with its category.
@Model
final class UserMeasurementUnit {
    var id: UUID = UUID()
    var name: String = ""
    var categoryRaw: String = MeasurementCategory.discretePortion.rawValue

    var category: MeasurementCategory? {
        MeasurementCategory(rawValue: categoryRaw)
    }

    init(name: String, category: MeasurementCategory) {
        self.name = name
        self.categoryRaw = category.rawValue
    }
}
