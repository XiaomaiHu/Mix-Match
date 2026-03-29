import SwiftUI

struct RevealPage: View {
    @EnvironmentObject var gameState: GameState
    var isChallenge: Bool = false

    // 动画状态
    @State private var showTitle = false
    @State private var showContent = false
    @State private var showBottles = false
    @State private var filledBottleCount: Int = 0
    @State private var showScreenshotFeedback = false

    let accentColor = Color(red: 0.58, green: 0.33, blue: 0.18)
    let glowColor = Color(red: 0.58, green: 0.33, blue: 0.18)

    // 布局常量
    let bottleTopY: CGFloat = 0.14
    let bottleBottomY: CGFloat = 0.39
    let shelfY: CGFloat = 0.38
    let shelfHeight: CGFloat = 30
    let shelfWidthRatio: CGFloat = 0.7
    let decoY: CGFloat = 0.4
    let recipeLeftMargin: CGFloat = 0.15
    let recipeTopMargin: CGFloat = 0.2
    let cocktailImageTop: CGFloat = 0.45
    let descriptionAndRadarTop: CGFloat = 0.5
    let middleRowBottom: CGFloat = 0.68
    let descriptionLeftMargin: CGFloat = 0.15
    let radarRightMargin: CGFloat = 0.2
    let bubbleLeftMargin: CGFloat = 0.2
    let matchTagTop: CGFloat = 0.7
    let matchTagBottom: CGFloat = 0.75
    let progressBarPositionY: CGFloat = 0.85
    let titleTopRatio: CGFloat = 0.025
    let titleFontSize: CGFloat = 22
    let cornerButtonSize: CGFloat = 44
    let cornerButtonIconSize: CGFloat = 18
    let cornerButtonRightPadding: CGFloat = 48
    let cornerButtonSpacing: CGFloat = 24
    let recipeTitleFontSize: CGFloat = 20
    let recipeItemFontSize: CGFloat = 15
    let descriptionFontSize: CGFloat = 15
    let funFactFontSize: CGFloat = 15
    let radarTitleFontSize: CGFloat = 15
    let percentageFontSize: CGFloat = 15
    let silhouetteBottleWidth: CGFloat = 40
    let silhouetteBottleHeight: CGFloat = 80
    let silhouetteSpacing: CGFloat = 8

    // MARK: - Verdict-derived layout flags
    private var verdict: MatchVerdict? { gameState.matchResult?.verdict }

    private var hasMatch: Bool {
        switch verdict {
        case .perfectMatch, .almostMatch, .vibesMatch, .looseMatch,
             .signatureMatch, .signatureConflict:
            return true
        default:
            return false
        }
    }

    private var showRecipeAndProgress: Bool {
        switch verdict {
        case .empty: return false
        default: return true
        }
    }

    private var isTooSimple: Bool {
        if case .tooSimple = verdict { return true }
        return false
    }

    private var showBubble: Bool {
        !hasMatch && !isTooSimple
    }

    // MARK: - Helper Builder
    @ViewBuilder
    private func unifiedRadarComponent<Content: View>(
        title: String,
        size: CGFloat,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 20) { // 统一内部间距
            content()
                .frame(width: size, height: size) // 强制图形区域大小一致
            
            Text(title)
                .font(.system(size: radarTitleFontSize, weight: .bold, design: .monospaced))
                .foregroundColor(accentColor)
                .lineLimit(1)
                .frame(height: 20) // 强制标签高度一致，防止文字差异导致排版偏移
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            let bottleH = h * (bottleBottomY - bottleTopY)
            let bottleW = bottleH * 0.5
            let cocktailImageSize = h * (middleRowBottom - cocktailImageTop)
            let matchTagHeight = h * (matchTagBottom - matchTagTop)
            let radarSize = cocktailImageSize

            // 计算统一的 Y 轴中心位置
            let sharedComponentY = h * descriptionAndRadarTop + (radarSize + 28) / 2

            ZStack {
                Color(red: 253/255, green: 235/255, blue: 189/255)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Image("upperframe").resizable().scaledToFit().frame(width: w)
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)

                Image("walldecoration")
                    .resizable().scaledToFit().frame(width: w)
                    .position(x: w * 0.5, y: h * decoY)

                VStack(spacing: 0) {
                    Spacer()
                    Image("tablewithoutcover").resizable().scaledToFit().frame(width: w)
                }
                .ignoresSafeArea(edges: .bottom)

                if let result = gameState.matchResult {

                    // 1. 顶部提示语 + 按钮
                    VStack(spacing: 0) {
                        HStack(alignment: .center) {
                            HStack(spacing: cornerButtonSpacing) {
                                Color.clear.frame(width: cornerButtonSize, height: cornerButtonSize)
                                Color.clear.frame(width: cornerButtonSize, height: cornerButtonSize)
                            }.padding(.leading, cornerButtonRightPadding)
                            Spacer()
                            titleBanner(result: result)
                            Spacer()
                            HStack(spacing: cornerButtonSpacing) {
                                Button(action: { takeScreenshot() }) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: cornerButtonIconSize, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(width: cornerButtonSize, height: cornerButtonSize)
                                        .background(Circle().fill(Color.white.opacity(0.15)))
                                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                }
                                Button(action: { gameState.reset(); gameState.currentPage = .welcome }) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: cornerButtonIconSize, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(width: cornerButtonSize, height: cornerButtonSize)
                                        .background(Circle().fill(Color.white.opacity(0.15)))
                                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                }
                            }.padding(.trailing, cornerButtonRightPadding)
                        }
                        .padding(.top, h * titleTopRatio)
                        Spacer()
                    }
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : -20)

                    // 2. 酒架
                    if showRecipeAndProgress {
                        recipeBottleShelf(result: result, screenWidth: w, bottleW: bottleW, bottleH: bottleH)
                            .frame(width: w * shelfWidthRatio, height: bottleH)
                            .position(x: w * 0.5, y: h * (bottleTopY + bottleBottomY) / 2)
                            .opacity(showContent ? 1 : 0)
                            .zIndex(2)

                        Image("shelf_wood")
                            .resizable().scaledToFit()
                            .frame(height: shelfHeight)
                            .frame(width: w * shelfWidthRatio)
                            .position(x: w * 0.5, y: h * shelfY + shelfHeight * 0.3)
                            .opacity(showContent ? 1 : 0)
                            .zIndex(1)
                    }

                    // 3. Recipe 文字
                    let ingredientCount = hasMatch ? result.cocktail.ingredients.count : gameState.ingredientRatios.count
                    if ingredientCount <= 6 {
                        recipeText(result: result, width: w)
                            .frame(maxWidth: w * 0.25, alignment: .topLeading)
                            .position(x: w * recipeLeftMargin + w * 0.125, y: h * recipeTopMargin + 50)
                            .opacity(showContent ? 1 : 0)
                    }

                    // 4. 酒介绍
                    if hasMatch {
                        descriptionText(result: result, width: w)
                            .frame(maxWidth: w * 0.2, alignment: .topLeading)
                            .position(x: w * descriptionLeftMargin + w * 0.1, y: h * descriptionAndRadarTop + cocktailImageSize * 0.3)
                            .opacity(showContent ? 1 : 0)
                    }

                    // 5. 鸡尾酒图片 (居中)
                    if hasMatch {
                        cocktailImage(result: result, imageSize: cocktailImageSize)
                            .position(x: w * 0.5, y: h * cocktailImageTop + cocktailImageSize / 2)
                            .opacity(showContent ? 1 : 0)
                    }

                    // 6. 泡泡 (左侧)
                    if showBubble {
                        unifiedRadarComponent(title: "Your Mix Color", size: radarSize) {
                            ZStack {
                                Circle()
                                    .fill(gameState.mixedColor.opacity(0.25))
                                    .frame(width: radarSize + 20, height: radarSize + 20)
                                    .blur(radius: 15)
                                Circle()
                                    .fill(RadialGradient(
                                        colors: [
                                            gameState.mixedColor.opacity(0.9),
                                            gameState.mixedColor.opacity(0.6),
                                            gameState.mixedColor.opacity(0.3)
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: radarSize / 2
                                    ))
                            }
                        }
                        .position(x: w * bubbleLeftMargin + radarSize / 2, y: sharedComponentY)
                        .opacity(showContent ? 1 : 0)
                    }

                    // 7. 雷达图 (右侧)
                    unifiedRadarComponent(title: "Your Mix Taste", size: radarSize) {
                        RadarChartView(profile: gameState.mixedFlavorProfile, size: radarSize)
                    }
                    .position(
                        x: isTooSimple ? w * 0.5 : w * (1.0 - radarRightMargin) - radarSize / 2,
                        y: sharedComponentY
                    )
                    .opacity(showContent ? 1 : 0)

                    // 8. Match 标签
                    if hasMatch {
                        percentageTag(result: result, tagHeight: matchTagHeight)
                            .position(x: w * 0.5, y: h * matchTagTop + matchTagHeight / 2)
                            .opacity(showContent ? 1 : 0)
                    }

                    // 9. 进度条
                    if showRecipeAndProgress {
                        silhouetteProgressBar(percentage: result.matchPercentage, width: w)
                            .position(x: w * 0.5, y: h * progressBarPositionY)
                            .opacity(showBottles ? 1 : 0)
                    }

                    if showScreenshotFeedback {
                        Text("Copied!")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Capsule().fill(accentColor))
                            .transition(.scale.combined(with: .opacity))
                            .position(x: w * 0.5, y: h * 0.5)
                    }

                } else {
                    Text("No match found").foregroundColor(.gray).font(.title2)
                }
            }
            .coordinateSpace(name: "revealScreen")
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) { showTitle = true }
            withAnimation(.easeInOut(duration: 0.5).delay(0.5)) { showContent = true }
            withAnimation(.easeInOut(duration: 0.4).delay(0.8)) { showBottles = true }
            if let result = gameState.matchResult, showRecipeAndProgress {
                let targetCount = min(10, Int(result.matchPercentage / 10))
                for i in 0..<targetCount {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + Double(i) * 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { filledBottleCount = i + 1 }
                    }
                }
            }
        }
    }

    // 出现的文字！
    private func titleBanner(result: MatchResult) -> some View {
        let message: String = {
            switch result.verdict {
            case .empty: return "Nothing in the shaker yet!"
            case .mocktail(let juice): return "You made a mocktail! Tastes like \(juice)!"
            case .tooSimple(let name): return "That's just \(name)! Try mixing it with something!"
            case .signatureMatch(let cocktail, let pct):
                return pct >= 80 ? "Signature detected — that's a \(cocktail.name)!" : "Signature detected — this is a \(cocktail.name) (\(Int(pct))% match)!"
            case .signatureConflict(let cocktail, let pct): return "You mixed signals — closest to a \(cocktail.name) (\(Int(pct))%)!"
            case .perfectMatch(let cocktail, _): return "You nailed it — that's a \(cocktail.name)!"
            case .almostMatch(let cocktail, _): return "Almost! This looks like a \(cocktail.name)!"
            case .vibesMatch(let cocktail, _): return "Close — this is giving \(cocktail.name) vibes!"
            case .looseMatch(let cocktail, _): return "Hmm, loosely resembles a \(cocktail.name)?"
            case .invention: return "You invented something new! We've never seen this before!"
            @unknown default: return "Something went wrong, just try again!"
            }
        }()
        return Text(message)
            .font(.system(size: titleFontSize, weight: .bold, design: .monospaced))
            .foregroundColor(accentColor)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }

    private func recipeBottleShelf(result: MatchResult, screenWidth: CGFloat, bottleW: CGFloat, bottleH: CGFloat) -> some View {
        let items: [(ingredientId: String, ratio: Double)] = hasMatch
            ? result.cocktail.ingredients.map { ($0.ingredientId, $0.ratio) }
            : gameState.ingredientRatios.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }

        return HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if let ingredient = ingredientById(item.ingredientId) {
                    RecipeBottleView(ingredient: ingredient, ratio: item.ratio, bottleW: bottleW, bottleH: bottleH, accentColor: accentColor)
                }
            }
        }
    }

    private func recipeText(result: MatchResult, width: CGFloat) -> some View {
        let items: [(ingredientId: String, ratio: Double)] = hasMatch
            ? result.cocktail.ingredients.map { ($0.ingredientId, $0.ratio) }
            : gameState.ingredientRatios.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
        let totalOz = hasMatch ? result.cocktail.totalOz : 4.0

        return VStack(alignment: .leading, spacing: 6) {
            Text(hasMatch ? "Classic Recipe:" : "Your Recipe:")
                .font(.system(size: recipeTitleFontSize, weight: .bold, design: .monospaced))
                .foregroundColor(accentColor)
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if let ingredient = ingredientById(item.ingredientId) {
                    let total = items.reduce(0.0) { $0 + $1.ratio }
                    let ratio = total > 0 ? item.ratio / total : item.ratio
                    let oz = ratio * totalOz
                    Text("- \(String(format: "%.1f", oz)) oz \(ingredient.name)")
                        .font(.system(size: recipeItemFontSize, weight: .medium, design: .monospaced))
                        .foregroundColor(accentColor.opacity(0.8))
                }
            }
        }
    }

    private func descriptionText(result: MatchResult, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(result.cocktail.description)
                .font(.system(size: descriptionFontSize, weight: .regular, design: .monospaced))
                .foregroundColor(accentColor.opacity(0.85))
                .lineSpacing(4)
            if !result.cocktail.funFact.isEmpty {
                Text(result.cocktail.funFact)
                    .font(.system(size: funFactFontSize, weight: .regular, design: .monospaced))
                    .foregroundColor(accentColor.opacity(0.6))
                    .italic()
                    .lineSpacing(3)
            }
        }
    }

    private func cocktailImage(result: MatchResult, imageSize: CGFloat) -> some View {
        Image("cocktail_\(result.cocktail.id)")
            .resizable()
            .scaledToFit()
            .frame(width: imageSize, height: imageSize)
    }

    private func percentageTag(result: MatchResult, tagHeight: CGFloat) -> some View {
        ZStack {
            Image("percentage_tag")
                .resizable()
                .scaledToFit()
                .frame(height: tagHeight)
            Text("\(Int(result.matchPercentage))% Match!")
                .font(.system(size: percentageFontSize, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    private func silhouetteProgressBar(percentage: Double, width: CGFloat) -> some View {
        HStack(spacing: silhouetteSpacing) {
            ForEach(0..<10, id: \.self) { i in
                let imageName = i % 2 == 0 ? "bottle_silhouette_a" : "bottle_silhouette_b"
                let isFilled = i < filledBottleCount
                ZStack {
                    Image(imageName)
                        .resizable().scaledToFit()
                        .frame(width: silhouetteBottleWidth, height: silhouetteBottleHeight)
                        .opacity(isFilled ? 0 : 0.3)
                    Image(imageName)
                        .resizable().scaledToFit()
                        .frame(width: silhouetteBottleWidth, height: silhouetteBottleHeight)
                        .colorMultiply(glowColor)
                        .shadow(color: glowColor.opacity(0.8), radius: 8)
                        .shadow(color: glowColor.opacity(0.5), radius: 15)
                        .opacity(isFilled ? 1 : 0)
                        .scaleEffect(isFilled ? 1.0 : 0.8)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: filledBottleCount)
            }
        }
    }

//    private func takeScreenshot() {
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let window = windowScene.windows.first else { return }
//        let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
//        let image = renderer.image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
//        withAnimation(.spring(response: 0.3)) { showScreenshotFeedback = true }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//            withAnimation(.easeOut(duration: 0.3)) { showScreenshotFeedback = false }
//        }
//    }
    // 为了防止权限问题改成copy了
    private func takeScreenshot() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
        let image = renderer.image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
        UIPasteboard.general.image = image  // 复制到剪贴板，不需要权限
        withAnimation(.spring(response: 0.3)) { showScreenshotFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) { showScreenshotFeedback = false }
        }
    }
}

// MARK: - RecipeBottleView
struct RecipeBottleView: View {
    let ingredient: Ingredient
    let ratio: Double
    let bottleW: CGFloat
    let bottleH: CGFloat
    let accentColor: Color
    @State private var isTouching = false
    let labelPositionRatio: CGFloat = 0.1

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if UIImage(named: ingredient.id) != nil {
                    Image(ingredient.id).resizable().scaledToFit().frame(width: bottleW, height: bottleH)
                } else {
                    RoundedRectangle(cornerRadius: 6).fill(ingredient.color.opacity(0.5)).frame(width: bottleW, height: bottleH)
                }
            }
            .rotationEffect(.degrees(isTouching ? -15 : 0), anchor: .bottom)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isTouching)
            
            VStack(spacing: 4) {
                Text(ingredient.name.replacingOccurrences(of: " ", with: "\n"))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(accentColor.opacity(0.8))
                    .multilineTextAlignment(.center)
                Text("\(Int(ratio * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
            }
            .opacity(isTouching ? 1 : 0)
            .offset(y: bottleH * labelPositionRatio)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isTouching)
        }
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in if !isTouching { isTouching = true } }
            .onEnded { _ in isTouching = false })
    }
}
