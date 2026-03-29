import SwiftUI

// MARK: - Ingredient Model
struct Ingredient: Identifiable, Equatable {
    let id: String
    let name: String
    let category: IngredientCategory
    let color: Color
    let colorRGB: (r: Double, g: Double, b: Double)
    let flavorProfile: FlavorProfile
    let pourPointRatio: CGFloat
    let description: String
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.id == rhs.id
    }
}

enum IngredientCategory: String, CaseIterable {
    case baseSpirit = "Base Spirits"
    case liqueur = "Liqueurs"
    case bittersFortified = "Bitters & Vermouth"
    case mixer = "Mixers"
    case sweetener = "Sweeteners"
}

struct FlavorProfile {
    let sweet: Double
    let sour: Double
    let strong: Double
    let bitter: Double
    let fruity: Double
}

// MARK: - Cocktail Model
struct Cocktail: Identifiable {
    let id: String
    let name: String
    let ingredients: [(ingredientId: String, ratio: Double)]
    let glassType: GlassType
    let description: String
    let funFact: String
    let colorRGB: (r: Double, g: Double, b: Double)
    let totalOz: Double
}

enum GlassType: String {
    case highball = "Highball"
    case martini = "Martini"
    case rocks = "Rocks"
    case hurricane = "Hurricane"
    case coupe = "Coupe"
}

// MARK: - Ingredient Database
let allIngredients: [Ingredient] = [
    // ═══════════════════════════════════════════════════════════
    // Base Spirits
    // ═══════════════════════════════════════════════════════════
    Ingredient(id: "vodka", name: "Vodka", category: .baseSpirit,
               color: Color(red: 0.95, green: 0.95, blue: 0.95),
               colorRGB: (0.95, 0.95, 0.95),
               flavorProfile: FlavorProfile(sweet: 0, sour: 0, strong: 0.8, bitter: 0, fruity: 0),
               pourPointRatio: 0.23,
               description: "A neutral, clean spirit. The perfect blank canvas for any cocktail creation."),
    
    Ingredient(id: "gin", name: "Gin", category: .baseSpirit,
               color: Color(red: 0.90, green: 0.95, blue: 0.90),
               colorRGB: (0.90, 0.95, 0.90),
               flavorProfile: FlavorProfile(sweet: 0, sour: 0, strong: 0.8, bitter: 0.3, fruity: 0.1),
               pourPointRatio: 0.2,
               description: "Botanical and aromatic, infused with juniper. The soul of a classic Martini."),
    
    Ingredient(id: "rum_white", name: "White Rum", category: .baseSpirit,
               color: Color(red: 0.96, green: 0.94, blue: 0.88),
               colorRGB: (0.96, 0.94, 0.88),
               flavorProfile: FlavorProfile(sweet: 0.2, sour: 0, strong: 0.7, bitter: 0, fruity: 0.2),
               pourPointRatio: 0.22,
               description: "Light and subtly sweet from sugarcane. Essential for tropical cocktails."),
    
    Ingredient(id: "rum_dark", name: "Dark Rum", category: .baseSpirit,
               color: Color(red: 0.55, green: 0.27, blue: 0.07),
               colorRGB: (0.55, 0.27, 0.07),
               flavorProfile: FlavorProfile(sweet: 0.3, sour: 0, strong: 0.7, bitter: 0.1, fruity: 0.2),
               pourPointRatio: 0.22,
               description: "Rich and molasses-forward with caramel notes. Aged for deeper flavor."),
    
    Ingredient(id: "tequila", name: "Tequila", category: .baseSpirit,
               color: Color(red: 0.96, green: 0.90, blue: 0.72),
               colorRGB: (0.96, 0.90, 0.72),
               flavorProfile: FlavorProfile(sweet: 0.1, sour: 0, strong: 0.8, bitter: 0.1, fruity: 0),
               pourPointRatio: 0.3,
               description: "Earthy and vegetal from blue agave. The heart of Mexican cocktails."),
    
    Ingredient(id: "whiskey", name: "Whiskey", category: .baseSpirit,
               color: Color(red: 0.76, green: 0.50, blue: 0.18),
               colorRGB: (0.76, 0.50, 0.18),
               flavorProfile: FlavorProfile(sweet: 0.2, sour: 0, strong: 0.9, bitter: 0.2, fruity: 0),
               pourPointRatio: 0.11,
               description: "Bold and oak-aged with warm vanilla notes. A timeless classic spirit."),
    
    // ═══════════════════════════════════════════════════════════
    // Liqueurs
    // ═══════════════════════════════════════════════════════════
    Ingredient(id: "cointreau", name: "Cointreau", category: .liqueur,
               color: Color(red: 0.98, green: 0.85, blue: 0.60),
               colorRGB: (0.98, 0.85, 0.60),
               flavorProfile: FlavorProfile(sweet: 0.5, sour: 0, strong: 0.4, bitter: 0.1, fruity: 0.6),
               pourPointRatio: 0.3,
               description: "Premium orange liqueur with bright citrus. Adds elegance to any mix."),
    
    Ingredient(id: "kahlua", name: "Kahlúa", category: .liqueur,
               color: Color(red: 0.20, green: 0.12, blue: 0.05),
               colorRGB: (0.20, 0.12, 0.05),
               flavorProfile: FlavorProfile(sweet: 0.6, sour: 0, strong: 0.3, bitter: 0.4, fruity: 0),
               pourPointRatio: 0.28,
               description: "Coffee liqueur with rich mocha sweetness. Perfect for dessert cocktails."),
    
    Ingredient(id: "campari", name: "Campari", category: .liqueur,
               color: Color(red: 0.85, green: 0.10, blue: 0.15),
               colorRGB: (0.85, 0.10, 0.15),
               flavorProfile: FlavorProfile(sweet: 0.2, sour: 0, strong: 0.3, bitter: 0.9, fruity: 0.1),
               pourPointRatio: 0.12,
               description: "Intensely bitter Italian aperitivo. Iconic red color, unforgettable taste."),
    
    Ingredient(id: "blue_curacao", name: "Blue Curaçao", category: .liqueur,
               color: Color(red: 0.0, green: 0.40, blue: 0.90),
               colorRGB: (0.0, 0.40, 0.90),
               flavorProfile: FlavorProfile(sweet: 0.5, sour: 0, strong: 0.3, bitter: 0, fruity: 0.5),
               pourPointRatio: 0.2,
               description: "Orange-flavored with stunning blue color. Makes any drink Instagram-worthy."),
    
    // ═══════════════════════════════════════════════════════════
    // Bitters & Vermouth
    // ═══════════════════════════════════════════════════════════
    Ingredient(id: "vermouth_sweet", name: "Sweet Vermouth", category: .bittersFortified,
               color: Color(red: 0.55, green: 0.15, blue: 0.10),
               colorRGB: (0.55, 0.15, 0.10),
               flavorProfile: FlavorProfile(sweet: 0.5, sour: 0, strong: 0.2, bitter: 0.3, fruity: 0.2),
               pourPointRatio: 0.28,
               description: "Herbal fortified wine with caramel notes. Essential for a perfect Negroni."),
    
    Ingredient(id: "vermouth_dry", name: "Dry Vermouth", category: .bittersFortified,
               color: Color(red: 0.92, green: 0.90, blue: 0.78),
               colorRGB: (0.92, 0.90, 0.78),
               flavorProfile: FlavorProfile(sweet: 0.1, sour: 0.1, strong: 0.2, bitter: 0.2, fruity: 0.1),
               pourPointRatio: 0.28,
               description: "Crisp and floral fortified wine. The Martini's sophisticated partner."),
    
    Ingredient(id: "bitters", name: "Angostura Bitters", category: .bittersFortified,
               color: Color(red: 0.50, green: 0.20, blue: 0.10),
               colorRGB: (0.50, 0.20, 0.10),
               flavorProfile: FlavorProfile(sweet: 0, sour: 0, strong: 0.2, bitter: 0.9, fruity: 0.1),
               pourPointRatio: 0.38,
               description: "Concentrated aromatic bitters. Just a few dashes transform everything."),
    
    // ═══════════════════════════════════════════════════════════
    // Mixers
    // ═══════════════════════════════════════════════════════════
    Ingredient(id: "lime_juice", name: "Lime Juice", category: .mixer,
               color: Color(red: 0.68, green: 1.0, blue: 0.18),
               colorRGB: (0.68, 1.0, 0.18),
               flavorProfile: FlavorProfile(sweet: 0, sour: 0.9, strong: 0, bitter: 0, fruity: 0.3),
               pourPointRatio: 0.29,
               description: "Bright and tangy citrus punch. The backbone of sours and tropical drinks."),
    
    Ingredient(id: "lemon_juice", name: "Lemon Juice", category: .mixer,
               color: Color(red: 0.98, green: 0.95, blue: 0.50),
               colorRGB: (0.98, 0.95, 0.50),
               flavorProfile: FlavorProfile(sweet: 0, sour: 0.8, strong: 0, bitter: 0, fruity: 0.2),
               pourPointRatio: 0.29,
               description: "Fresh and zesty with clean acidity. Brightens any cocktail instantly."),
    
    Ingredient(id: "orange_juice", name: "Orange Juice", category: .mixer,
               color: Color(red: 1.0, green: 0.65, blue: 0.0),
               colorRGB: (1.0, 0.65, 0.0),
               flavorProfile: FlavorProfile(sweet: 0.4, sour: 0.3, strong: 0, bitter: 0, fruity: 0.8),
               pourPointRatio: 0.29,
               description: "Sweet and sunny citrus flavor. A brunch cocktail essential."),
    
    Ingredient(id: "cranberry_juice", name: "Cranberry Juice", category: .mixer,
               color: Color(red: 0.80, green: 0.10, blue: 0.20),
               colorRGB: (0.80, 0.10, 0.20),
               flavorProfile: FlavorProfile(sweet: 0.2, sour: 0.5, strong: 0, bitter: 0.1, fruity: 0.7),
               pourPointRatio: 0.21,
               description: "Tart and ruby-red with subtle sweetness. Adds beautiful color and balance."),
    
    Ingredient(id: "pineapple_juice", name: "Pineapple Juice", category: .mixer,
               color: Color(red: 1.0, green: 0.85, blue: 0.30),
               colorRGB: (1.0, 0.85, 0.30),
               flavorProfile: FlavorProfile(sweet: 0.5, sour: 0.3, strong: 0, bitter: 0, fruity: 0.9),
               pourPointRatio: 0.21,
               description: "Tropical sweetness with tangy edge. Instant vacation in a glass."),
    
    Ingredient(id: "soda_water", name: "Soda Water", category: .mixer,
               color: Color(red: 0.92, green: 0.95, blue: 1.0),
               colorRGB: (0.92, 0.95, 1.0),
               flavorProfile: FlavorProfile(sweet: 0, sour: 0, strong: 0, bitter: 0, fruity: 0),
               pourPointRatio: 0.21,
               description: "Pure effervescence with no flavor. Adds lift and sparkle to drinks."),
    
    Ingredient(id: "cola", name: "Cola", category: .mixer,
               color: Color(red: 0.25, green: 0.12, blue: 0.05),
               colorRGB: (0.25, 0.12, 0.05),
               flavorProfile: FlavorProfile(sweet: 0.6, sour: 0.1, strong: 0, bitter: 0.1, fruity: 0),
               pourPointRatio: 0.29,
               description: "Classic caramel-spiced soda. The world's favorite spirit companion."),
    
    Ingredient(id: "ginger_beer", name: "Ginger Beer", category: .mixer,
               color: Color(red: 0.90, green: 0.82, blue: 0.60),
               colorRGB: (0.90, 0.82, 0.60),
               flavorProfile: FlavorProfile(sweet: 0.3, sour: 0.1, strong: 0, bitter: 0.2, fruity: 0),
               pourPointRatio: 0.3,
               description: "Spicy and fiery with ginger kick. Essential for mules and bucks."),
    
    Ingredient(id: "coconut_cream", name: "Coconut Cream", category: .mixer,
               color: Color(red: 0.98, green: 0.97, blue: 0.92),
               colorRGB: (0.98, 0.97, 0.92),
               flavorProfile: FlavorProfile(sweet: 0.5, sour: 0, strong: 0, bitter: 0, fruity: 0.3),
               pourPointRatio: 0.4,
               description: "Rich and creamy tropical indulgence. Makes drinks smooth and luxurious."),
    
    Ingredient(id: "espresso", name: "Espresso", category: .mixer,
               color: Color(red: 0.20, green: 0.10, blue: 0.05),
               colorRGB: (0.20, 0.10, 0.05),
               flavorProfile: FlavorProfile(sweet: 0, sour: 0, strong: 0.1, bitter: 0.7, fruity: 0),
               pourPointRatio: 0.33,
               description: "Intense coffee concentrate with crema. Adds energy and sophistication."),
    
    // ═══════════════════════════════════════════════════════════
    // Sweeteners
    // ═══════════════════════════════════════════════════════════
    Ingredient(id: "simple_syrup", name: "Simple Syrup", category: .sweetener,
               color: Color(red: 0.98, green: 0.95, blue: 0.80),
               colorRGB: (0.98, 0.95, 0.80),
               flavorProfile: FlavorProfile(sweet: 0.9, sour: 0, strong: 0, bitter: 0, fruity: 0),
               pourPointRatio: 0.15,
               description: "Pure liquid sweetness. Balances sour and strong without adding flavor."),
    
    Ingredient(id: "grenadine", name: "Grenadine", category: .sweetener,
               color: Color(red: 0.85, green: 0.05, blue: 0.20),
               colorRGB: (0.85, 0.05, 0.20),
               flavorProfile: FlavorProfile(sweet: 0.8, sour: 0.1, strong: 0, bitter: 0, fruity: 0.4),
               pourPointRatio: 0.15,
               description: "Pomegranate syrup with deep red hue. Creates beautiful layered sunrises."),
]

func ingredientById(_ id: String) -> Ingredient? {
    allIngredients.first { $0.id == id }
}

// MARK: - Cocktail Database
let allCocktails: [Cocktail] = [
    Cocktail(id: "margarita", name: "Margarita",
             ingredients: [("tequila", 0.50), ("cointreau", 0.25), ("lime_juice", 0.25)],
             glassType: .coupe, description: "A refreshing citrus cocktail with a perfect balance of sweet, sour, and strong.",
             funFact: "The Margarita is the most popular cocktail in the United States.",
             colorRGB: (0.87, 0.82, 0.50),
             totalOz: 4.5),
    
    Cocktail(id: "mojito", name: "Mojito",
             ingredients: [("rum_white", 0.35), ("lime_juice", 0.20), ("simple_syrup", 0.15), ("soda_water", 0.30)],
             glassType: .highball, description: "A classic Cuban cocktail that's light, refreshing, and minty.",
             funFact: "Ernest Hemingway was a famous Mojito lover at La Bodeguita del Medio in Havana.",
             colorRGB: (0.85, 0.92, 0.65),
             totalOz: 8.0),
    
    Cocktail(id: "martini", name: "Classic Martini",
             ingredients: [("gin", 0.75), ("vermouth_dry", 0.25)],
             glassType: .martini, description: "The quintessential cocktail — elegant, strong, and timeless.",
             funFact: "James Bond's 'shaken, not stirred' is actually considered improper by most bartenders.",
             colorRGB: (0.91, 0.93, 0.85),
             totalOz: 3.5),
    
    Cocktail(id: "old_fashioned", name: "Old Fashioned",
             ingredients: [("whiskey", 0.75), ("simple_syrup", 0.15), ("bitters", 0.10)],
             glassType: .rocks, description: "A timeless whiskey cocktail with depth and warmth.",
             funFact: "The Old Fashioned is considered the original cocktail, dating back to the early 1800s.",
             colorRGB: (0.72, 0.48, 0.18),
             totalOz: 3.5),
    
    Cocktail(id: "cosmopolitan", name: "Cosmopolitan",
             ingredients: [("vodka", 0.40), ("cointreau", 0.20), ("cranberry_juice", 0.25), ("lime_juice", 0.15)],
             glassType: .martini, description: "A glamorous pink cocktail that's fruity and elegant.",
             funFact: "The Cosmopolitan became iconic through Sex and the City in the late 1990s.",
             colorRGB: (0.85, 0.40, 0.35),
             totalOz: 4.0),
    
    Cocktail(id: "negroni", name: "Negroni",
             ingredients: [("gin", 0.33), ("campari", 0.33), ("vermouth_sweet", 0.34)],
             glassType: .rocks, description: "A bold Italian aperitif with a beautiful bitter-sweet balance.",
             funFact: "Count Camillo Negroni asked his bartender to strengthen his Americano with gin instead of soda.",
             colorRGB: (0.70, 0.20, 0.15),
             totalOz: 3.0),
    
    Cocktail(id: "pina_colada", name: "Piña Colada",
             ingredients: [("rum_white", 0.35), ("coconut_cream", 0.35), ("pineapple_juice", 0.30)],
             glassType: .hurricane, description: "A tropical paradise in a glass — creamy, sweet, and fruity.",
             funFact: "The Piña Colada has been the official drink of Puerto Rico since 1978.",
             colorRGB: (0.97, 0.92, 0.70),
             totalOz: 8.0),
    
    Cocktail(id: "daiquiri", name: "Daiquiri",
             ingredients: [("rum_white", 0.50), ("lime_juice", 0.30), ("simple_syrup", 0.20)],
             glassType: .coupe, description: "A perfectly balanced rum sour — simple, elegant, refreshing.",
             funFact: "JFK reportedly loved Daiquiris, and they were a favorite at the White House.",
             colorRGB: (0.88, 0.90, 0.55),
             totalOz: 4.0),
    
    Cocktail(id: "whiskey_sour", name: "Whiskey Sour",
             ingredients: [("whiskey", 0.50), ("lemon_juice", 0.30), ("simple_syrup", 0.20)],
             glassType: .rocks, description: "A smooth and tangy whiskey cocktail with a perfect sweet-sour balance.",
             funFact: "The Whiskey Sour first appeared in print in 1862.",
             colorRGB: (0.82, 0.65, 0.35),
             totalOz: 4.0),
    
    Cocktail(id: "tom_collins", name: "Tom Collins",
             ingredients: [("gin", 0.35), ("lemon_juice", 0.20), ("simple_syrup", 0.15), ("soda_water", 0.30)],
             glassType: .highball, description: "A tall, refreshing gin drink that's perfect for warm days.",
             funFact: "The Tom Collins originated from a practical joke in 1874 New York.",
             colorRGB: (0.90, 0.93, 0.80),
             totalOz: 8.0),
    
    Cocktail(id: "tequila_sunrise", name: "Tequila Sunrise",
             ingredients: [("tequila", 0.35), ("orange_juice", 0.55), ("grenadine", 0.10)],
             glassType: .highball, description: "A stunning layered cocktail that looks like a sunrise in a glass.",
             funFact: "The Rolling Stones popularized this drink during their 1972 American tour.",
             colorRGB: (0.95, 0.60, 0.20),
             totalOz: 6.0),
    
    Cocktail(id: "espresso_martini", name: "Espresso Martini",
             ingredients: [("vodka", 0.40), ("kahlua", 0.30), ("espresso", 0.30)],
             glassType: .martini, description: "A caffeinated cocktail that wakes you up while it winds you down.",
             funFact: "Created in 1983 when a model asked for something to 'wake me up and then mess me up.'",
             colorRGB: (0.30, 0.15, 0.08),
             totalOz: 4.0),
    
    Cocktail(id: "moscow_mule", name: "Moscow Mule",
             ingredients: [("vodka", 0.40), ("lime_juice", 0.15), ("ginger_beer", 0.45)],
             glassType: .highball, description: "A crisp, refreshing cocktail with a spicy ginger kick.",
             funFact: "The Moscow Mule was created in 1941 to help sell both vodka and ginger beer.",
             colorRGB: (0.90, 0.85, 0.55),
             totalOz: 8.0),
    
    Cocktail(id: "long_island", name: "Long Island Iced Tea",
             ingredients: [("vodka", 0.18), ("gin", 0.18), ("rum_white", 0.18), ("tequila", 0.18), ("cointreau", 0.10), ("lemon_juice", 0.10), ("cola", 0.08)],
             glassType: .highball, description: "A potent mix that tastes deceptively like iced tea.",
             funFact: "Despite the name, it contains no tea at all.",
             colorRGB: (0.65, 0.50, 0.30),
             totalOz: 10.0),
    
    Cocktail(id: "cuba_libre", name: "Cuba Libre",
             ingredients: [("rum_white", 0.35), ("cola", 0.55), ("lime_juice", 0.10)],
             glassType: .highball, description: "More than just rum and coke — the lime makes all the difference.",
             funFact: "The drink's name means 'Free Cuba' and was born during the Spanish-American War.",
             colorRGB: (0.40, 0.22, 0.10),
             totalOz: 8.0),
    
    Cocktail(id: "screwdriver", name: "Screwdriver",
             ingredients: [("vodka", 0.35), ("orange_juice", 0.65)],
             glassType: .highball, description: "The simplest brunch cocktail — just vodka and orange juice.",
             funFact: "Supposedly named by oil workers who stirred the drink with a screwdriver.",
             colorRGB: (0.96, 0.70, 0.15),
             totalOz: 7.5),
    
    Cocktail(id: "gimlet", name: "Gimlet",
             ingredients: [("gin", 0.65), ("lime_juice", 0.25), ("simple_syrup", 0.10)],
             glassType: .coupe, description: "A sharp, clean gin cocktail with bright citrus notes.",
             funFact: "British sailors drank gimlets to prevent scurvy on long voyages.",
             colorRGB: (0.82, 0.92, 0.55),
             totalOz: 3.5),
    
    Cocktail(id: "dark_n_stormy", name: "Dark 'n' Stormy",
             ingredients: [("rum_dark", 0.40), ("ginger_beer", 0.55), ("lime_juice", 0.05)],
             glassType: .highball, description: "A bold, spicy cocktail with deep rum flavor and ginger heat.",
             funFact: "This is one of the few trademarked cocktails — legally it must use Gosling's rum.",
             colorRGB: (0.55, 0.35, 0.15),
             totalOz: 8.0),
    
    Cocktail(id: "blue_lagoon", name: "Blue Lagoon",
             ingredients: [("vodka", 0.35), ("blue_curacao", 0.25), ("lemon_juice", 0.15), ("soda_water", 0.25)],
             glassType: .highball, description: "A vibrant electric blue cocktail that's as fun as it looks.",
             funFact: "Created in 1960 at Harry's New York Bar in Paris.",
             colorRGB: (0.30, 0.55, 0.85),
             totalOz: 8.0),
    
    Cocktail(id: "rum_punch", name: "Rum Punch",
             ingredients: [("rum_dark", 0.30), ("orange_juice", 0.25), ("pineapple_juice", 0.25), ("grenadine", 0.10), ("lime_juice", 0.10)],
             glassType: .hurricane, description: "A tropical party in a glass with layers of fruity flavor.",
             funFact: "The classic Caribbean recipe follows: one of sour, two of sweet, three of strong, four of weak.",
             colorRGB: (0.85, 0.45, 0.20),
             totalOz: 8.0),
]
