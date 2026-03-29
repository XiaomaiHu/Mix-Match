import SwiftUI

struct ChallengePage: View {
    @EnvironmentObject var gameState: GameState
    @State private var showTarget = false
    @State private var targetScale: Double = 0.5

    let accentColor = Color(red: 0.91, green: 0.27, blue: 0.37)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    gameState.currentPage = .welcome
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Challenge Mode")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    gameState.startChallenge()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)

            Spacer()

            if let target = gameState.challengeTarget, showTarget {
                VStack(spacing: 32) {
                    Text("Can you recreate this cocktail?")
                        .font(.title3)
                        .foregroundColor(.gray)

                    HStack(spacing: 60) {
                        VStack(spacing: 16) {
                            Text("TARGET COLOR")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .tracking(2)

                            ZStack {
                                Circle()
                                    .fill(Color(red: target.colorRGB.r, green: target.colorRGB.g, blue: target.colorRGB.b).opacity(0.3))
                                    .frame(width: 180, height: 180)
                                    .blur(radius: 30)

                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: target.colorRGB.r, green: target.colorRGB.g, blue: target.colorRGB.b),
                                                Color(red: target.colorRGB.r * 0.8, green: target.colorRGB.g * 0.8, blue: target.colorRGB.b * 0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 140, height: 140)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                    )
                                    .shadow(color: Color(red: target.colorRGB.r, green: target.colorRGB.g, blue: target.colorRGB.b).opacity(0.4), radius: 20)
                            }
                            .scaleEffect(targetScale)
                        }

                        VStack(spacing: 16) {
                            Text("FLAVOR HINTS")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .tracking(2)

                            let targetFlavor = computeTargetFlavor(target)
                            RadarChartView(profile: targetFlavor, size: 140)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text("CLUES")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .tracking(2)

                            HintRow(icon: "wineglass", text: target.glassType.rawValue + " glass")
                            HintRow(icon: "drop.fill", text: "\(target.ingredients.count) ingredients")

                            if let mainIngredientId = target.ingredients.max(by: { $0.ratio < $1.ratio })?.ingredientId,
                               let mainIngredient = ingredientById(mainIngredientId) {
                                HintRow(icon: "star.fill", text: "Base: \(mainIngredient.category.rawValue)")
                            }
                        }
                    }

                    Button(action: {
                        gameState.resetMix()
                        gameState.currentPage = .selectIngredients
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Accept Challenge")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(accentColor)
                        .cornerRadius(16)
                    }
                    .padding(.top, 16)
                }
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                showTarget = true
                targetScale = 1.0
            }
        }
    }

    func computeTargetFlavor(_ cocktail: Cocktail) -> FlavorProfile {
        var sweet = 0.0, sour = 0.0, strong = 0.0, bitter = 0.0, fruity = 0.0
        for (id, ratio) in cocktail.ingredients {
            guard let ingredient = ingredientById(id) else { continue }
            sweet += ingredient.flavorProfile.sweet * ratio
            sour += ingredient.flavorProfile.sour * ratio
            strong += ingredient.flavorProfile.strong * ratio
            bitter += ingredient.flavorProfile.bitter * ratio
            fruity += ingredient.flavorProfile.fruity * ratio
        }
        return FlavorProfile(sweet: sweet, sour: sour, strong: strong, bitter: bitter, fruity: fruity)
    }
}

struct HintRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color(red: 0.91, green: 0.27, blue: 0.37))
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
