import SwiftUI

struct WelcomePage: View {
    @EnvironmentObject var gameState: GameState

    let accent = Color(red: 0.58, green: 0.33, blue: 0.18)
    
    // ★ 暖黄色发光（酒瓶居中时）
    let warmGlow = Color(red: 253/255, green: 235/255, blue: 189/255)

    // ═══════════════════════════════════════════════════════════
    // ★ 统一布局参数（所有页面保持一致）
    // ═══════════════════════════════════════════════════════════
    
    // 酒瓶区域
    let bottleTopY: CGFloat = 0.14
    let bottleBottomY: CGFloat = 0.39
    
    // 架子
    let shelfY: CGFloat = 0.38
    let shelfHeight: CGFloat = 30
    let shelfWidthRatio: CGFloat = 0.7
    
    // 名称牌
    let nameTagOffsetY: CGFloat = 40
    
    // ★ Shaker 位置（统一为 0.65）
    let shakerCenterY: CGFloat = 0.65
    
    // ★ 墙上装饰画位置（统一为 0.4）
    let decoY: CGFloat = 0.4
    
    // ★ 按钮位置（统一为 0.9）
    let buttonY: CGFloat = 0.9
    
    // ★ 配料介绍文字参数
    let descriptionLeftMargin: CGFloat = 0.16
    let descriptionTopY: CGFloat = 0.45
    let descriptionFontSize: CGFloat = 15
    let descriptionMaxWidth: CGFloat = 0.2
    
    // ═══════════════════════════════════════════════════════════

    let shakerTapDelay: Double = 0.8

    @State private var centeredBottleID: String? = nil
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var selectedCategory: IngredientCategory = .baseSpirit
    @State private var lidRotation: Double = 0
    @State private var isTransitioning: Bool = false
    @State private var glowPulse: Bool = false
    @State private var arrowOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            let bottleH = h * (bottleBottomY - bottleTopY)
            let bottleW = bottleH * 0.5

            ZStack {
                // ── 背景色 ──
                Color(red: 211/255, green: 174/255, blue: 125/255)
                    .ignoresSafeArea()

                // ── 顶部框架 ──
                VStack(spacing: 0) {
                    Image("upperframe")
                        .resizable()
                        .scaledToFit()
                        .frame(width: w)
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)

                // ── 墙上装饰画（★ 统一位置 0.4）──
                Image("walldecoration")
                    .resizable()
                    .scaledToFit()
                    .frame(width: w)
                    .position(x: w * 0.5, y: h * decoY)

                // ── 有桌布的桌子 ──
                VStack(spacing: 0) {
                    Spacer()
                    Image("tablewithcover")
                        .resizable()
                        .scaledToFit()
                        .frame(width: w)
                }
                .ignoresSafeArea(edges: .bottom)

                // ── ★ 游戏logo（和桌子完全重叠，在桌子上层）──
                VStack(spacing: 0) {
                    Spacer()
                    Image("gamelogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: w)
                }
                .ignoresSafeArea(edges: .bottom)
                
                // ── 顶部分类栏 ──
                categoryBar(w: w, h: h)
                    .position(x: w * 0.5, y: h * 0.04)

                // ── ★ 酒瓶居中时的暖光效果 ──
                if centeredBottleID != nil {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    warmGlow.opacity(0.6),
                                    warmGlow.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .position(x: w * 0.5, y: h * (bottleTopY + bottleBottomY) / 2)
                        .blur(radius: 20)
                        .allowsHitTesting(false)
                        .zIndex(0)
                }

                // ── 酒瓶架 ──
                bottleShelf(screenWidth: w * 0.68, actualScreenWidth: w, bottleW: bottleW, bottleH: bottleH)
                    .frame(width: w * 0.68, height: bottleH)
                    .position(x: w * 0.5, y: h * (bottleTopY + bottleBottomY) / 2)
                    .zIndex(2)

                // ── 木头架子 ──
                Image("shelf_wood")
                    .resizable()
                    .scaledToFit()
                    .frame(height: shelfHeight)
                    .frame(width: w * shelfWidthRatio)
                    .position(x: w * 0.5, y: h * shelfY + shelfHeight * 0.3)
                    .zIndex(1)

                // ── 名称牌 ──
                bottleNameTag
                    .position(x: w * 0.5, y: h * shelfY + shelfHeight + nameTagOffsetY)
                    .zIndex(3)

                // ── ★ 配料介绍文字（左侧，和名称牌同步显示/隐藏）──
                ingredientDescription(w: w, h: h)
                    .zIndex(3)

                // ── 搅拌杯（★ 统一位置 0.65）──
                shakerArea(w: w, h: h)
                    .position(x: w * 0.5, y: h * shakerCenterY)
            }
            .coordinateSpace(name: "welcomeScreen")
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                arrowOffset = 8
            }
        }
    }
    
    // MARK: - ★ 配料介绍文字
    @ViewBuilder
    private func ingredientDescription(w: CGFloat, h: CGFloat) -> some View {
        if let id = centeredBottleID,
           let ing = allIngredients.first(where: { $0.id == id }) {
            Text(ing.description)
                .font(.system(size: descriptionFontSize, weight: .medium, design: .monospaced))
                .foregroundColor(accent.opacity(0.85))
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .frame(maxWidth: w * descriptionMaxWidth, alignment: .leading)
                .position(x: w * descriptionLeftMargin + w * descriptionMaxWidth / 2, y: h * descriptionTopY)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.15), value: centeredBottleID)
        }
    }
    
    // MARK: - Shaker 区域
    private func shakerArea(w: CGFloat, h: CGFloat) -> some View {
        let shakerBodyH: CGFloat = h * 0.12
        let shakerBodyW: CGFloat = shakerBodyH * 0.8
        let shakerLidH: CGFloat = shakerBodyH * 0.48
        let shakerLidW: CGFloat = shakerBodyW
        
        return ZStack {
            // 发光效果层1
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accent.opacity(glowPulse ? 0.5 : 0.2),
                            accent.opacity(glowPulse ? 0.2 : 0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: glowPulse ? 120 : 100
                    )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 20)
            
            // 发光效果层2
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(glowPulse ? 0.4 : 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
                .blur(radius: 10)
            
            // 搅拌杯本体
            VStack(spacing: 0) {
                Image("shaker_lid")
                    .resizable()
                    .scaledToFit()
                    .frame(width: shakerLidW, height: shakerLidH)
                    .rotationEffect(
                        .degrees(lidRotation),
                        anchor: lidRotation >= 0
                            ? UnitPoint(x: 1.0, y: 1.0)
                            : UnitPoint(x: 0.0, y: 1.0)
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: lidRotation)

                Image("shaker")
                    .resizable()
                    .scaledToFit()
                    .frame(width: shakerBodyW, height: shakerBodyH)
            }
            .shadow(color: accent.opacity(glowPulse ? 0.6 : 0.3), radius: glowPulse ? 20 : 10)
            .onTapGesture {
                guard !isTransitioning else { return }
                isTransitioning = true
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    lidRotation = 45
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + shakerTapDelay) {
                    lidRotation = 0
                    gameState.reset()
                    gameState.currentPage = .selectIngredients
                }
            }
            
            // 提示文字 + 箭头
            HStack(spacing: 12) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(accent)
                    .offset(x: -arrowOffset)
                
                Text("Tap to Start Your Mix")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(accent)
                    .multilineTextAlignment(.leading)
            }
            .offset(x: 200, y: -shakerLidH / 2)
        }
    }

    // MARK: - 顶部分类栏
    private func categoryBar(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(IngredientCategory.allCases, id: \.rawValue) { cat in
                let isActive = selectedCategory == cat
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedCategory = cat
                    }
                    if let first = allIngredients.first(where: { $0.category == cat }) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scrollProxy?.scrollTo(first.id, anchor: .center)
                        }
                    }
                } label: {
                    Text(cat.rawValue)
                        .font(.system(size: 18, weight: isActive ? .bold : .medium, design: .monospaced))
                        .foregroundColor(isActive ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isActive ? accent.opacity(0.9) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 酒瓶名称牌子
    private var bottleNameTag: some View {
        ZStack {
            Image("name_tag")
                .resizable()
                .scaledToFit()
                .frame(height: 50)

            if let id = centeredBottleID,
               let ing = allIngredients.first(where: { $0.id == id }) {
                Text(ing.name)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: centeredBottleID)
    }

    // MARK: - 酒瓶架
    private func bottleShelf(screenWidth: CGFloat, actualScreenWidth: CGFloat, bottleW: CGFloat, bottleH: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    Spacer().frame(width: screenWidth / 2 - bottleW / 2)
                    ForEach(allIngredients) { ingredient in
                        bottleView(ingredient: ingredient, bottleW: bottleW, bottleH: bottleH)
                    }
                    Spacer().frame(width: screenWidth / 2 - bottleW / 2)
                }
            }
            .onPreferenceChange(BottleCenterPreferenceKey.self) { prefs in
                let trueCenter = actualScreenWidth / 2
                let hit = prefs.first(where: { trueCenter >= $0.minX && trueCenter <= $0.maxX })
                let newID = hit?.id
                if centeredBottleID != newID {
                    centeredBottleID = newID
                    if let id = newID,
                       let ing = allIngredients.first(where: { $0.id == id }) {
                        selectedCategory = ing.category
                    }
                }
            }
            .onAppear { scrollProxy = proxy }
        }
    }

    // MARK: - 单个酒瓶
    @ViewBuilder
    private func bottleView(ingredient: Ingredient, bottleW: CGFloat, bottleH: CGFloat) -> some View {
        let isCentered = centeredBottleID == ingredient.id

        ZStack(alignment: .bottom) {
            if UIImage(named: ingredient.id) != nil {
                Image(ingredient.id)
                    .resizable()
                    .scaledToFit()
                    .frame(width: bottleW, height: bottleH)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(ingredient.color.opacity(0.5))
                    .frame(width: bottleW, height: bottleH)
            }
        }
        .scaleEffect(isCentered ? 1.0 : 0.9)
        .animation(.easeOut(duration: 0.1), value: isCentered)
        .id(ingredient.id)
        .background(
            GeometryReader { geo in
                let frame = geo.frame(in: .named("welcomeScreen"))
                Color.clear.preference(
                    key: BottleCenterPreferenceKey.self,
                    value: [BottleCenterData(
                        id: ingredient.id,
                        minX: frame.minX,
                        maxX: frame.maxX
                    )]
                )
            }
        )
    }
}
