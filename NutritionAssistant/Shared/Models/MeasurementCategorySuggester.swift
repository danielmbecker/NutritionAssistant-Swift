import Foundation
import FoundationModels
import NaturalLanguage

/// Suggests a category for a user-typed unit. Suggestions are never saved silently; the user confirms.
protocol MeasurementCategorySuggesting {
    func suggest(for unitName: String) async -> MeasurementCategory?
}

// MARK: - Foundation Models (primary)

@Generable
private struct MeasurementCategoryGuess {
    @Guide(
        description: "The category that best fits the household food measurement unit.",
        .anyOf([
            "volumetric", "weight", "discretePortion", "packageContainer",
            "foodSpecificCount", "supplementSpecialized", "specializedTime"
        ])
    )
    var category: String
}

struct FoundationModelsCategorySuggester: MeasurementCategorySuggesting {
    private static let instructions = """
    You classify household measurement units used on food and supplement labels into exactly one category.
    - volumetric: liquid/dry volume (mL, cup, tbsp, tsp, fl oz)
    - weight: mass (g, oz)
    - discretePortion: a generic portion of something (piece, slice, bar, scoop, cube, strip, square, wedge, sheet, roll, ball)
    - packageContainer: packaging (container, pack, bottle, can, pouch, packet, bag, box, tray, carton)
    - foodSpecificCount: a count of a specific food (cookie, cracker, chip, pretzel, tortilla, pancake, waffle, muffin, bagel, bun, link, patty, fillet, egg, dumpling, potsticker)
    - supplementSpecialized: supplement or dosing forms (spray, drop, capsule, tablet, softgel, gummy, pod)
    - specializedTime: units measured by duration (timed spray)
    """

    func suggest(for unitName: String) async -> MeasurementCategory? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(
                to: "Classify this unit: \(unitName)",
                generating: MeasurementCategoryGuess.self
            )
            return MeasurementCategory(rawValue: response.content.category)
        } catch {
            return nil
        }
    }
}

// MARK: - NaturalLanguage embeddings (fallback)

struct EmbeddingCategorySuggester: MeasurementCategorySuggesting {
    /// Maximum cosine distance to the nearest seed unit to accept a suggestion.
    var maxDistance: Double = 1.0

    func suggest(for unitName: String) async -> MeasurementCategory? {
        let word = unitName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !word.isEmpty,
              let embedding = NLEmbedding.wordEmbedding(for: .english),
              embedding.contains(word) else { return nil }

        var best: (category: MeasurementCategory, distance: Double)?
        for seed in MeasurementUnitCatalog.builtIn {
            let seedWord = seed.name.lowercased()
            guard embedding.contains(seedWord) else { continue }
            let d = embedding.distance(between: word, and: seedWord)
            if best == nil || d < best!.distance { best = (seed.category, d) }
        }
        guard let best, best.distance <= maxDistance else { return nil }
        return best.category
    }
}

// MARK: - Composite

struct CompositeCategorySuggester: MeasurementCategorySuggesting {
    var suggesters: [any MeasurementCategorySuggesting] = [
        FoundationModelsCategorySuggester(),
        EmbeddingCategorySuggester()
    ]

    func suggest(for unitName: String) async -> MeasurementCategory? {
        for suggester in suggesters {
            if let result = await suggester.suggest(for: unitName) { return result }
        }
        return nil
    }
}
