import Foundation

/// Fixed (exhaustive) categories for household measurements. The list of units inside each category is extensible.
enum MeasurementCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    case volumetric
    case weight
    case discretePortion
    case packageContainer
    case foodSpecificCount
    case supplementSpecialized
    case specializedTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .volumetric: return "Volumetric"
        case .weight: return "Weight"
        case .discretePortion: return "Discrete or Portion Units"
        case .packageContainer: return "Package or Container Units"
        case .foodSpecificCount: return "Food Specific Count Units"
        case .supplementSpecialized: return "Specialized & Supplement Units"
        case .specializedTime: return "Specialized Time Units"
        }
    }
}

/// A unit as defined in the catalog. `name` is always the canonical singular form.
struct MeasurementUnitDefinition: Hashable, Sendable, Identifiable {
    let name: String
    let category: MeasurementCategory
    /// Abbreviations (mL, g, tbsp...) never change with quantity.
    let isInvariant: Bool
    let irregularPlural: String?

    var id: String { name.lowercased() }

    init(_ name: String, _ category: MeasurementCategory, isInvariant: Bool = false, irregularPlural: String? = nil) {
        self.name = name
        self.category = category
        self.isInvariant = isInvariant
        self.irregularPlural = irregularPlural
    }
}

enum MeasurementUnitCatalog {
    static let builtIn: [MeasurementUnitDefinition] = [
        // Volumetric
        .init("mL", .volumetric, isInvariant: true),
        .init("cup", .volumetric),
        .init("tbsp", .volumetric, isInvariant: true),
        .init("tsp", .volumetric, isInvariant: true),
        .init("fl oz", .volumetric, isInvariant: true),
        // Weight
        .init("g", .weight, isInvariant: true),
        .init("oz", .weight, isInvariant: true),
        // Discrete / portion
        .init("piece", .discretePortion),
        .init("slice", .discretePortion),
        .init("bar", .discretePortion),
        .init("scoop", .discretePortion),
        .init("cube", .discretePortion),
        .init("strip", .discretePortion),
        .init("square", .discretePortion),
        .init("wedge", .discretePortion),
        .init("sheet", .discretePortion),
        .init("roll", .discretePortion),
        .init("ball", .discretePortion),
        // Package / container
        .init("container", .packageContainer),
        .init("pack", .packageContainer),
        .init("bottle", .packageContainer),
        .init("can", .packageContainer),
        .init("pouch", .packageContainer),
        .init("packet", .packageContainer),
        .init("bag", .packageContainer),
        .init("box", .packageContainer),
        .init("tray", .packageContainer),
        .init("carton", .packageContainer),
        // Food specific count
        .init("cookie", .foodSpecificCount),
        .init("cracker", .foodSpecificCount),
        .init("chip", .foodSpecificCount),
        .init("pretzel", .foodSpecificCount),
        .init("tortilla", .foodSpecificCount),
        .init("pancake", .foodSpecificCount),
        .init("waffle", .foodSpecificCount),
        .init("muffin", .foodSpecificCount),
        .init("bagel", .foodSpecificCount),
        .init("bun", .foodSpecificCount),
        .init("link", .foodSpecificCount),
        .init("patty", .foodSpecificCount, irregularPlural: "patties"),
        .init("fillet", .foodSpecificCount),
        .init("egg", .foodSpecificCount),
        .init("dumpling", .foodSpecificCount),
        .init("potsticker", .foodSpecificCount),
        // Specialized & supplement
        .init("spray", .supplementSpecialized),
        .init("drop", .supplementSpecialized),
        .init("capsule", .supplementSpecialized),
        .init("tablet", .supplementSpecialized),
        .init("softgel", .supplementSpecialized),
        .init("gummy", .supplementSpecialized, irregularPlural: "gummies"),
        .init("pod", .supplementSpecialized),
        // Specialized time
        .init("timed spray", .specializedTime)
    ]

    private static func key(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Built-in units followed by user-added units (user units never shadow built-ins).
    static func allDefinitions(userUnits: [UserMeasurementUnit] = []) -> [MeasurementUnitDefinition] {
        var seen = Set(builtIn.map { key($0.name) })
        var result = builtIn
        for user in userUnits {
            guard let category = user.category, seen.insert(key(user.name)).inserted else { continue }
            result.append(MeasurementUnitDefinition(user.name, category))
        }
        return result
    }

    static func definition(for name: String, userUnits: [UserMeasurementUnit] = []) -> MeasurementUnitDefinition? {
        let k = key(name)
        return allDefinitions(userUnits: userUnits).first {
            key($0.name) == k
                || (!$0.isInvariant && key($0.irregularPlural ?? MeasurementUnitFormatter.pluralize($0.name)) == k)
        }
    }

    static func category(for name: String, userUnits: [UserMeasurementUnit] = []) -> MeasurementCategory? {
        definition(for: name, userUnits: userUnits)?.category
    }

    static func isDuplicate(_ name: String, userUnits: [UserMeasurementUnit] = []) -> Bool {
        definition(for: name, userUnits: userUnits) != nil
    }

    /// Units grouped by category in `MeasurementCategory.allCases` order (empty categories included).
    static func grouped(userUnits: [UserMeasurementUnit] = []) -> [(category: MeasurementCategory, units: [MeasurementUnitDefinition])] {
        let all = allDefinitions(userUnits: userUnits)
        return MeasurementCategory.allCases.map { cat in
            (cat, all.filter { $0.category == cat })
        }
    }
}

enum MeasurementUnitFormatter {
    /// Returns the unit name for display: singular when quantity == 1, plural otherwise.
    static func display(name: String, quantity: Double, userUnits: [UserMeasurementUnit] = []) -> String {
        if quantity == 1 { return name }
        let definition = MeasurementUnitCatalog.definition(for: name, userUnits: userUnits)
        if definition?.isInvariant == true { return name }
        if let irregular = definition?.irregularPlural { return irregular }
        return pluralize(name)
    }

    /// Rule-based English pluralization of the final word.
    static func pluralize(_ word: String) -> String {
        let lower = word.lowercased()
        guard let last = lower.last else { return word }
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        if last == "y", let beforeLast = lower.dropLast().last, !vowels.contains(beforeLast) {
            return String(word.dropLast()) + "ies"
        }
        if last == "s" || last == "x" || last == "z" || lower.hasSuffix("ch") || lower.hasSuffix("sh") {
            return word + "es"
        }
        return word + "s"
    }
}
