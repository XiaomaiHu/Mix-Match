import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        ZStack {
            switch gameState.currentPage {
            case .launch:
                LaunchPage()
                    .transition(.opacity)
            case .welcome:
                WelcomePage()
                    .transition(.opacity)
            case .selectIngredients:
                IngredientSelectionPage()
                    .transition(.opacity)
            case .mixing:
                MixingPage()
                    .transition(.opacity)
            case .reveal:
                RevealPage()
                    .transition(.opacity)
            case .challenge:
                WelcomePage()
                    .transition(.opacity)
            case .challengeMixing:
                WelcomePage()
                    .transition(.opacity)
            case .challengeReveal:
                WelcomePage()
                    .transition(.opacity)
            case .library:
                WelcomePage()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: gameState.currentPage)
    }
}
