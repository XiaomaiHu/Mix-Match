import SwiftUI

struct LibraryPage: View {
    @EnvironmentObject var gameState: GameState
    @State private var selectedCocktail: Cocktail?
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
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
                
                Text("My Collection")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                // Progress
                Text("\(gameState.discoveredCocktails.count)/\(allCocktails.count)")
                    .font(.callout)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.91, green: 0.27, blue: 0.37))
                        .frame(
                            width: geo.size.width * CGFloat(gameState.discoveredCocktails.count) / CGFloat(allCocktails.count),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(allCocktails) { cocktail in
                        CocktailCard(
                            cocktail: cocktail,
                            isDiscovered: gameState.discoveredCocktails.contains(cocktail.id)
                        )
                        .onTapGesture {
                            if gameState.discoveredCocktails.contains(cocktail.id) {
                                selectedCocktail = cocktail
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .sheet(item: $selectedCocktail) { cocktail in
            CocktailDetailSheet(cocktail: cocktail)
        }
    }
}

// MARK: - Cocktail Card
struct CocktailCard: View {
    let cocktail: Cocktail
    let isDiscovered: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            if isDiscovered {
                // Color swatch
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: cocktail.colorRGB.r, green: cocktail.colorRGB.g, blue: cocktail.colorRGB.b),
                                Color(red: cocktail.colorRGB.r * 0.7, green: cocktail.colorRGB.g * 0.7, blue: cocktail.colorRGB.b * 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                Text(cocktail.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                // Locked
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 80)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                
                Text("???")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.4))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isDiscovered ? 0.05 : 0.02))
        )
    }
}

// MARK: - Detail Sheet
struct CocktailDetailSheet: View {
    let cocktail: Cocktail
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.16)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                
                // Color banner
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: cocktail.colorRGB.r, green: cocktail.colorRGB.g, blue: cocktail.colorRGB.b),
                                Color(red: cocktail.colorRGB.r * 0.6, green: cocktail.colorRGB.g * 0.6, blue: cocktail.colorRGB.b * 0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .padding(.horizontal, 24)
                
                Text(cocktail.name)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(cocktail.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Ingredients
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ingredients")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(cocktail.ingredients, id: \.ingredientId) { item in
                        if let ingredient = ingredientById(item.ingredientId) {
                            HStack {
                                Circle()
                                    .fill(ingredient.color)
                                    .frame(width: 14, height: 14)
                                Text(ingredient.name)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(Int(item.ratio * 100))%")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
                // Fun fact
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text(cocktail.funFact)
                        .font(.callout)
                        .foregroundColor(.gray)
                        .italic()
                }
                .padding(16)
                .background(Color.yellow.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
}
