import Foundation

// MARK: - Match Verdict
enum MatchVerdict {
    /// No ingredients poured at all
    case empty

    /// Only non-alcoholic ingredients present
    case mocktail(dominantJuice: String)

    /// Only one ingredient poured, or one spirit with nothing meaningful alongside it
    /// (meaningful = any other ingredient with ratio > 15%)
    case tooSimple(ingredientName: String)

    /// One signature ingredient detected — cosine run against that candidate,
    /// percentage reflects actual recipe similarity
    case signatureMatch(cocktail: Cocktail, percentage: Double)

    /// Multiple signature ingredients detected — cosine resolved the conflict,
    /// percentage reflects real similarity score
    case signatureConflict(cocktail: Cocktail, percentage: Double)

    /// Good cosine match (score >= 0.80)
    case perfectMatch(cocktail: Cocktail, percentage: Double)

    /// Decent cosine match (0.65 ..< 0.80)
    case almostMatch(cocktail: Cocktail, percentage: Double)

    /// Weak cosine match (0.45 ..< 0.65)
    case vibesMatch(cocktail: Cocktail, percentage: Double)

    /// Very weak cosine match (0.30 ..< 0.45)
    case looseMatch(cocktail: Cocktail, percentage: Double)

    /// Nothing recognisable (score < 0.30) — user invented something new
    case invention
}

// MARK: - Match Result
struct MatchResult {
    let cocktail: Cocktail
    let matchPercentage: Double
    let alternatives: [(cocktail: Cocktail, percentage: Double)]
    /// Single source of truth for what RevealPage displays
    let verdict: MatchVerdict
}

// MARK: - Matching Engine
struct MatchingEngine {

    // MARK: - Tunable Constants

    /// Ratio smoothing factor (α).
    /// Blends the user's observed ratios toward a uniform distribution:
    ///   smoothed[i] = (1 - α) × observed[i] + α × (1 / n)
    /// where n = number of distinct ingredients poured.
    /// α = 0 → raw ratios; α = 1 → everything uniform.
    private static let smoothingAlpha: Double = 0.2

    /// Minimum ratio share for a non-spirit ingredient to count as "meaningful"
    private static let meaningfulRatioThreshold: Double = 0.15

    // Score thresholds
    private static let scorePerfect: Double = 0.80
    private static let scoreAlmost:  Double = 0.65
    private static let scoreVibes:   Double = 0.45
    private static let scoreLoose:   Double = 0.30

    // Non-alcoholic ingredient IDs — used for the mocktail guardrail
    private static let nonAlcoholicIDs: Set<String> = [
        "lime_juice", "lemon_juice", "orange_juice", "cranberry_juice",
        "pineapple_juice", "soda_water", "cola", "ginger_beer",
        "coconut_cream", "espresso", "simple_syrup", "grenadine"
    ]

    // MARK: - Ingredient Substitution Matrix
    // Cross-ingredient similarity values for the generalized cosine kernel.
    // Pairs not listed are orthogonal (similarity = 0).
    // blue_curacao is intentionally orthogonal to everything — it is a signature ingredient.
    private static let substitutionPairs: [(String, String, Double)] = [
        ("lime_juice",   "lemon_juice",    0.8),   // nearly interchangeable in sours
        ("rum_white",    "rum_dark",       0.6),   // same spirit family, different intensity
        ("vermouth_dry", "vermouth_sweet", 0.5),   // both fortified wines, different profile
        ("simple_syrup", "grenadine",      0.4),   // both sweeteners, grenadine adds fruit
        ("orange_juice", "pineapple_juice",0.3),   // both tropical juices
        ("orange_juice", "cranberry_juice",0.2),   // both juices, quite different
        ("soda_water",   "ginger_beer",    0.2),   // both carbonated diluters
    ]

    /// Precomputed N×N similarity matrix indexed by allIngredients position.
    /// Diagonal = 1.0, substitution pairs set symmetrically, all others 0.0.
    private static let similarityMatrix: [[Double]] = {
        let n = allIngredients.count
        let index: [String: Int] = Dictionary(
            uniqueKeysWithValues: allIngredients.enumerated().map { ($1.id, $0) }
        )
        var S = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        for i in 0..<n { S[i][i] = 1.0 }
        for (a, b, sim) in substitutionPairs {
            if let i = index[a], let j = index[b] {
                S[i][j] = sim
                S[j][i] = sim
            }
        }
        return S
    }()

    // MARK: - Public Entry Point
    static func findBestMatch(
        selectedIngredients: [Ingredient],
        ratios: [String: Double]
    ) -> MatchResult {

        // ── Guardrail 1: empty ──────────────────────────────────────────────
        guard !ratios.isEmpty else {
            return syntheticResult(verdict: .empty)
        }

        // ── Guardrail 2: no alcohol → mocktail ─────────────────────────────
        let hasAlcohol = ratios.keys.contains { !nonAlcoholicIDs.contains($0) }
        if !hasAlcohol {
            return syntheticResult(verdict: .mocktail(dominantJuice: dominantName(ratios: ratios)))
        }

        // ── Guardrail 3: too simple ─────────────────────────────────────────
        if ratios.count == 1, let only = selectedIngredients.first {
            return syntheticResult(verdict: .tooSimple(ingredientName: only.name))
        }
        let spiritIDs: Set<String> = ["vodka","gin","rum_white","rum_dark","tequila","whiskey"]
        let spiritsInMix = ratios.keys.filter { spiritIDs.contains($0) }
        let total = ratios.values.reduce(0, +)
        let hasMeaningfulMixer = ratios.contains { key, value in
            !spiritIDs.contains(key) && total > 0 && (value / total) >= meaningfulRatioThreshold
        }
        if spiritsInMix.count == 1 && !hasMeaningfulMixer {
            let name = ingredientById(spiritsInMix[0])?.name ?? "spirit"
            return syntheticResult(verdict: .tooSimple(ingredientName: name))
        }

        // ── Guardrail 4: signature matching ────────────────────────────────
        let sigIDs = triggeredSignatures(ratios: ratios)

        if sigIDs.count >= 1 {
            // Run cosine against signature candidates only — always report real similarity.
            // Single signature: winner is predetermined but percentage reflects actual recipe match.
            // Multiple signatures: cosine resolves the conflict among candidates.
            let candidates = allCocktails.filter { sigIDs.contains($0.id) }
            let scores     = scoredCocktails(ratios: ratios, candidates: candidates)
            let best       = scores[0]
            let pct        = best.score * 100
            let allScores  = scoredCocktails(ratios: ratios, candidates: nil)
            let alts = allScores
                .filter { $0.cocktail.id != best.cocktail.id }
                .prefix(3)
                .map { (cocktail: $0.cocktail, percentage: $0.score * 100) }
            let verdict: MatchVerdict = sigIDs.count == 1
                ? .signatureMatch(cocktail: best.cocktail, percentage: pct)
                : .signatureConflict(cocktail: best.cocktail, percentage: pct)
            return MatchResult(
                cocktail: best.cocktail,
                matchPercentage: pct,
                alternatives: Array(alts),
                verdict: verdict
            )
        }

        // ── Main path: smoothed cosine against all cocktails ────────────────
        let scores = scoredCocktails(ratios: ratios, candidates: nil)
        let best   = scores[0]
        let alts   = Array(scores[1..<min(4, scores.count)])
            .map { (cocktail: $0.cocktail, percentage: $0.score * 100) }

        // ── Guardrail 5: invention (score too low) ──────────────────────────
        guard best.score >= scoreLoose else {
            return MatchResult(
                cocktail: best.cocktail,
                matchPercentage: best.score * 100,
                alternatives: alts,
                verdict: .invention
            )
        }

        // ── Map score → verdict ─────────────────────────────────────────────
        let pct = best.score * 100
        let verdict: MatchVerdict
        switch best.score {
        case scorePerfect...:
            verdict = .perfectMatch(cocktail: best.cocktail, percentage: pct)
        case scoreAlmost..<scorePerfect:
            verdict = .almostMatch(cocktail: best.cocktail, percentage: pct)
        case scoreVibes..<scoreAlmost:
            verdict = .vibesMatch(cocktail: best.cocktail, percentage: pct)
        default:
            verdict = .looseMatch(cocktail: best.cocktail, percentage: pct)
        }

        return MatchResult(
            cocktail: best.cocktail,
            matchPercentage: pct,
            alternatives: alts,
            verdict: verdict
        )
    }

    // MARK: - Triggered Signatures
    // Returns all signature cocktail IDs triggered by the current pour.
    // May return 0, 1, or 2+ IDs — caller handles each case differently.
    private static func triggeredSignatures(ratios: [String: Double]) -> [String] {
        let present = Set(ratios.keys)
        var hits: [String] = []

        if present.contains("campari")       { hits.append("negroni")          }
        if present.contains("espresso")      { hits.append("espresso_martini") }
        if present.contains("coconut_cream") { hits.append("pina_colada")      }
        if present.contains("blue_curacao")  { hits.append("blue_lagoon")      }
        if present.contains("bitters")       { hits.append("old_fashioned")    }

        // Long Island: cola + 2+ base spirits
        let baseSpirits = ["vodka","gin","rum_white","rum_dark","tequila","whiskey"]
        if present.contains("cola") && baseSpirits.filter({ present.contains($0) }).count >= 2 {
            hits.append("long_island")
        }

        return hits
    }

    // MARK: - Score Cocktails
    // If `candidates` is non-nil, only those cocktails are scored.
    // Otherwise the full allCocktails pool is used.
    private static func scoredCocktails(
        ratios: [String: Double],
        candidates: [Cocktail]?
    ) -> [(cocktail: Cocktail, score: Double)] {
        let userVector = buildSmoothedVector(ratios: ratios)
        let pool       = candidates ?? allCocktails

        var scores: [(cocktail: Cocktail, score: Double)] = pool.map { cocktail in
            let cocktailVector = buildCocktailVector(cocktail)
            return (cocktail, cosineSimilarity(userVector, cocktailVector))
        }
        scores.sort { $0.score > $1.score }
        return scores
    }

    // MARK: - Smoothed User Vector
    // 1. Normalize raw ratios to sum to 1.
    // 2. Blend each nonzero dimension toward its uniform share by smoothingAlpha.
    //    Zero dimensions stay zero — we never hallucinate missing ingredients.
    // 3. Map onto the full allIngredients dimension space.
    private static func buildSmoothedVector(ratios: [String: Double]) -> [Double] {
        let total = ratios.values.reduce(0, +)
        guard total > 0 else { return Array(repeating: 0, count: allIngredients.count) }

        let n       = Double(ratios.count)
        let uniform = 1.0 / n
        let alpha   = smoothingAlpha

        return allIngredients.map { ingredient in
            let observed = (ratios[ingredient.id] ?? 0) / total
            guard observed > 0 else { return 0.0 }
            return (1.0 - alpha) * observed + alpha * uniform
        }
    }

    // MARK: - Cocktail Vector
    // Plain normalized ratio vector — no weighting.
    // Cocktail ratios in the database already sum to 1.0.
    private static func buildCocktailVector(_ cocktail: Cocktail) -> [Double] {
        var ratioDict: [String: Double] = [:]
        for (id, ratio) in cocktail.ingredients { ratioDict[id] = ratio }
        return allIngredients.map { ratioDict[$0.id] ?? 0 }
    }

    // MARK: - Generalized Cosine Similarity (kernel)
    // Uses the substitution matrix S so that similar ingredients (e.g. lime/lemon)
    // contribute partial dot-product credit instead of being fully orthogonal.
    // Formula: (u^T S v) / sqrt((u^T S u) * (v^T S v))
    // When S = I this reduces to standard cosine similarity.
    private static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, a.count == similarityMatrix.count else { return 0 }
        let S = similarityMatrix

        // Compute x^T S y efficiently — skip zero entries
        func quadratic(_ x: [Double], _ y: [Double]) -> Double {
            var result = 0.0
            for i in 0..<x.count where x[i] != 0 {
                for j in 0..<y.count where y[j] != 0 {
                    result += x[i] * S[i][j] * y[j]
                }
            }
            return result
        }

        let num   = quadratic(a, b)
        let denom = sqrt(quadratic(a, a)) * sqrt(quadratic(b, b))
        guard denom > 0 else { return 0 }
        // The similarity matrix is positive semi-definite (min eigenvalue = 0.2),
        // so Cauchy-Schwarz guarantees this ratio is mathematically ≤ 1.
        // The clamp is a defensive guard only — it should never fire.
        return min(num / denom, 1.0)
    }

    // MARK: - Helpers

    /// Name of the highest-ratio non-alcoholic ingredient (for mocktail message)
    private static func dominantName(ratios: [String: Double]) -> String {
        let nonAlc = ratios.filter { nonAlcoholicIDs.contains($0.key) }
        guard let top = nonAlc.max(by: { $0.value < $1.value }) else { return "juice" }
        return ingredientById(top.key)?.name ?? "juice"
    }

    /// Placeholder result for guardrail verdicts that have no real cocktail match.
    /// The placeholder cocktail is never displayed — RevealPage switches on verdict first.
    private static func syntheticResult(verdict: MatchVerdict) -> MatchResult {
        MatchResult(
            cocktail: allCocktails[0],
            matchPercentage: 0,
            alternatives: [],
            verdict: verdict
        )
    }
}
