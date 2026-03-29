import SwiftUI

class GameState: ObservableObject {
    @Published var currentPage: AppPage = .launch
    @Published var selectedIngredients: [Ingredient] = []
    @Published var ingredientRatios: [String: Double] = [:]
    @Published var discoveredCocktails: Set<String> = []
    @Published var matchResult: MatchResult?
    @Published var challengeTarget: Cocktail?
    @Published var isShaking: Bool = false

    /// Each pour segment: which ingredient and how much (absolute amount, not normalized)
    @Published var pourSegments: [PourSegment] = []

    enum AppPage {
        case launch
        case welcome
        case selectIngredients
        case mixing
        case reveal
        case challenge
        case challengeMixing
        case challengeReveal
        case library
    }

    // MARK: - Pour Segment
    struct PourSegment: Identifiable {
        let id = UUID()
        let ingredientId: String
        let color: Color
        var amount: CGFloat
    }

    var totalPoured: CGFloat {
        pourSegments.reduce(0) { $0 + $1.amount }
    }

    var isFull: Bool {
        totalPoured >= 1.0
    }

    // MARK: - Computed mixed color
    var mixedColor: Color {
        let rgb = mixedColorRGB
        return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    var mixedColorRGB: (r: Double, g: Double, b: Double) {
        var r = 0.0, g = 0.0, b = 0.0
        let total = ingredientRatios.values.reduce(0, +)
        guard total > 0 else { return (0.3, 0.3, 0.4) }
        for (id, ratio) in ingredientRatios {
            guard let ingredient = ingredientById(id) else { continue }
            let weight = ratio / total
            r += ingredient.colorRGB.r * weight
            g += ingredient.colorRGB.g * weight
            b += ingredient.colorRGB.b * weight
        }
        return (r, g, b)
    }

    var mixedFlavorProfile: FlavorProfile {
        var sweet = 0.0, sour = 0.0, strong = 0.0, bitter = 0.0, fruity = 0.0
        let total = ingredientRatios.values.reduce(0, +)
        guard total > 0 else { return FlavorProfile(sweet: 0, sour: 0, strong: 0, bitter: 0, fruity: 0) }
        for (id, ratio) in ingredientRatios {
            guard let ingredient = ingredientById(id) else { continue }
            let weight = ratio / total
            sweet  += ingredient.flavorProfile.sweet  * weight
            sour   += ingredient.flavorProfile.sour   * weight
            strong += ingredient.flavorProfile.strong * weight
            bitter += ingredient.flavorProfile.bitter * weight
            fruity += ingredient.flavorProfile.fruity * weight
        }
        return FlavorProfile(sweet: sweet, sour: sour, strong: strong, bitter: bitter, fruity: fruity)
    }

    // MARK: - Pour-based ingredient management
    func pourIngredient(_ ingredient: Ingredient, increment: CGFloat) {
        guard !isFull else { return }
        let actualIncrement = min(increment, 1.0 - totalPoured)

        if !selectedIngredients.contains(ingredient) {
            selectedIngredients.append(ingredient)
        }
        ingredientRatios[ingredient.id, default: 0] += Double(actualIncrement)

        if let lastIdx = pourSegments.lastIndex(where: { $0.ingredientId == ingredient.id }) {
            if pourSegments.last?.ingredientId == ingredient.id {
                pourSegments[lastIdx].amount += actualIncrement
            } else {
                pourSegments.append(PourSegment(ingredientId: ingredient.id, color: ingredient.color, amount: actualIncrement))
            }
        } else {
            pourSegments.append(PourSegment(ingredientId: ingredient.id, color: ingredient.color, amount: actualIncrement))
        }
    }

    // MARK: - Match
    func performMatch() {
        matchResult = MatchingEngine.findBestMatch(
            selectedIngredients: selectedIngredients,
            ratios: ingredientRatios
        )
        guard let result = matchResult else { return }

        // Only add to discovered collection for real cocktail matches —
        // mocktail, tooSimple, empty, and invention verdicts don't count.
        switch result.verdict {
        case .signatureMatch, .signatureConflict, .perfectMatch, .almostMatch, .vibesMatch, .looseMatch:
            discoveredCocktails.insert(result.cocktail.id)
            for alt in result.alternatives {
                discoveredCocktails.insert(alt.cocktail.id)
            }
        default:
            break
        }
    }

    func startChallenge() {
        let available = allCocktails.shuffled()
        challengeTarget = available.first
        resetMix()
    }

    func resetMix() {
        selectedIngredients = []
        ingredientRatios = [:]
        pourSegments = []
        matchResult = nil
        isShaking = false
    }

    func reset() {
        resetMix()
        challengeTarget = nil
    }
}
// MatchResult and MatchVerdict are defined in MatchingEngine.swift
