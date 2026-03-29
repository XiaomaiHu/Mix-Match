import SwiftUI

// MARK: - 用于追踪酒瓶在屏幕上X位置的 PreferenceKey
struct BottleCenterData: Equatable {
    let id: String
    let minX: CGFloat
    let maxX: CGFloat
}

struct BottleCenterPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [BottleCenterData] = []
    static func reduce(value: inout [BottleCenterData], nextValue: () -> [BottleCenterData]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - 倒酒水滴模型
struct PourDrop: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    let color: Color
    let size: CGFloat
}

// MARK: - 水滴形状
struct WaterDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w / 2, y: 0))
        path.addCurve(to: CGPoint(x: w, y: h * 0.65), control1: CGPoint(x: w * 0.9, y: h * 0.2), control2: CGPoint(x: w, y: h * 0.4))
        path.addArc(center: CGPoint(x: w / 2, y: h * 0.65), radius: w / 2, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: true)
        path.addCurve(to: CGPoint(x: w / 2, y: 0), control1: CGPoint(x: 0, y: h * 0.4), control2: CGPoint(x: w * 0.1, y: h * 0.2))
        path.closeSubpath()
        return path
    }
}

// MARK: - 配料碗模型
struct GarnishBowl: Identifiable {
    let id: String
    let name: String
    let bowlImageName: String
    let garnishImageName: String
    let soundName: String
    let positionRatio: (x: CGFloat, y: CGFloat)
    let bowlSize: CGFloat
    let garnishDisplayWidth: CGFloat
    let garnishDisplayHeight: CGFloat
}

let mixPageBowls: [GarnishBowl] = [
    GarnishBowl(id: "ice", name: "Ice Cube", bowlImageName: "bowl_ice", garnishImageName: "garnish_ice", soundName: "ice_clink", positionRatio: (0.2, 0.65), bowlSize: 120, garnishDisplayWidth: 50, garnishDisplayHeight: 50),
]

let shakePageBowls: [GarnishBowl] = [
    GarnishBowl(id: "ice", name: "Ice Cube", bowlImageName: "bowl_ice", garnishImageName: "garnish_ice", soundName: "ice_clink", positionRatio: (0.2, 0.65), bowlSize: 120, garnishDisplayWidth: 50, garnishDisplayHeight: 50),
    GarnishBowl(id: "lemon", name: "Lemon Slice", bowlImageName: "bowl_lemon", garnishImageName: "garnish_lemon", soundName: "splash_soft", positionRatio: (0.3, 0.65), bowlSize: 120, garnishDisplayWidth: 50, garnishDisplayHeight: 50),
    GarnishBowl(id: "cinnamon", name: "Cinnamon Stick", bowlImageName: "bowl_cinnamon", garnishImageName: "garnish_cinnamon", soundName: "splash_soft", positionRatio: (0.7, 0.65), bowlSize: 120, garnishDisplayWidth: 40, garnishDisplayHeight: 100),
    GarnishBowl(id: "mint", name: "Mint Leaf", bowlImageName: "bowl_mint", garnishImageName: "garnish_mint", soundName: "swoosh", positionRatio: (0.8, 0.65), bowlSize: 120, garnishDisplayWidth: 50, garnishDisplayHeight: 50),
]

// MARK: - 主页面
struct IngredientSelectionPage: View {
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
    
    // ═══════════════════════════════════════════════════════════

    // 酒瓶架状态
    @State private var selectedCategory: IngredientCategory = .baseSpirit
    @State private var centeredBottleID: String? = nil
    @State private var scrollProxy: ScrollViewProxy? = nil

    // 拖拽状态
    @State private var draggingIngredient: Ingredient? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var isInPourZone: Bool = false
    @State private var bottleOnLeft: Bool = true

    // 倒酒动画
    @State private var pourDrops: [PourDrop] = []
    @State private var pourTimer: Timer? = nil

    // 盖子旋转
    @State private var lidRotation: Double = 0
    @State private var shakerFrame: CGRect = .zero
    @State private var shakerBodyFrame: CGRect = .zero

    // 布局追踪
    @State private var glassFrame: CGRect = .zero
    @State private var screenSize: CGSize = .zero

    // 配料拖拽状态
    @State private var draggingBowl: GarnishBowl? = nil
    @State private var garnishDragLocation: CGPoint = .zero
    @State private var isGarnishDragging: Bool = false
    @State private var addedGarnishes: [String] = []
    @State private var garnishDropAnimation: Bool = false
    @State private var garnishDropID: String? = nil

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let _ = updateScreenSize(geo.size)
            
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

                // ── 顶部分类栏 ──
                categoryBar(w: w, h: h)
                    .position(x: w * 0.5, y: h * 0.04)

                // ── ★ 酒瓶居中时的暖光效果 ──
                if centeredBottleID != nil && !isDragging {
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

                // ── Shaker杯 + 刻度条（★ 统一位置 0.65）──
                glassAndGauge(w: w, h: h)
                    .position(x: w * 0.5, y: h * shakerCenterY)

                // ── 操作按钮（★ 统一位置 0.9）──
                actionButtons
                    .position(x: w * 0.5, y: h * buttonY)

                // ── 冰块碗 ──
                ForEach(mixPageBowls) { bowl in
                    bowlView(bowl: bowl, screenWidth: w, screenHeight: h, enabled: true)
                }

                // ── 掉落动画 ──
                if let dropID = garnishDropID,
                   let bowl = mixPageBowls.first(where: { $0.id == dropID }) {
                    Image(bowl.garnishImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: bowl.garnishDisplayWidth * 1.5, height: bowl.garnishDisplayHeight * 1.5)
                        .position(x: glassFrame.midX, y: garnishDropAnimation ? glassFrame.midY : glassFrame.minY - 40)
                        .opacity(garnishDropAnimation ? 0 : 1)
                        .scaleEffect(garnishDropAnimation ? 0.3 : 1.0)
                        .animation(.easeIn(duration: 0.35), value: garnishDropAnimation)
                        .allowsHitTesting(false)
                        .zIndex(97)
                }

                // ── 倒酒水流 ──
                pourStreamView()
                    .zIndex(98)

                // ── 拖拽幽灵酒瓶 ──
                if let ing = draggingIngredient, isDragging {
                    let ghostH = h * (bottleBottomY - bottleTopY)
                    let ghostX: CGFloat = {
                        if isInPourZone && dragLocation.y < shakerBodyFrame.minY {
                            let mouthOffset = ghostH / 2 - ing.pourPointRatio * ghostH
                            let centerX = shakerBodyFrame.midX
                            return dragLocation.x < glassFrame.midX ? centerX - mouthOffset : centerX + mouthOffset
                        }
                        return dragLocation.x
                    }()
                    
                    dragGhostView(ingredient: ing, ghostH: ghostH)
                        .position(x: ghostX, y: dragLocation.y)
                        .allowsHitTesting(false)
                        .zIndex(100)
                }

                // ── 拖拽幽灵配料 ──
                if let bowl = draggingBowl, isGarnishDragging {
                    Image(bowl.garnishImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: bowl.garnishDisplayWidth * 1.2, height: bowl.garnishDisplayHeight * 1.2)
                        .position(x: garnishDragLocation.x, y: garnishDragLocation.y)
                        .shadow(radius: 8)
                        .allowsHitTesting(false)
                        .zIndex(100)
                }
            }
            .coordinateSpace(name: "screen")
        }
    }

    private func updateScreenSize(_ size: CGSize) -> Bool {
        DispatchQueue.main.async { if screenSize != size { screenSize = size } }
        return true
    }

    // MARK: - 倒酒水流
    @ViewBuilder
    private func pourStreamView() -> some View {
        if isInPourZone,
           let ing = draggingIngredient,
           !gameState.isFull,
           dragLocation.y < shakerBodyFrame.minY {
            
            let streamBottom = shakerBodyFrame.minY
            let streamTop = min(dragLocation.y, streamBottom - 20)
            let streamX = shakerBodyFrame.midX

            Rectangle()
                .fill(LinearGradient(colors: [ing.color.opacity(0.9), ing.color.opacity(0.6), ing.color.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                .frame(width: 12, height: streamBottom - streamTop)
                .position(x: streamX, y: (streamTop + streamBottom) / 2)
                .allowsHitTesting(false)

            ForEach([-1, 1], id: \.self) { side in
                Rectangle()
                    .fill(ing.color.opacity(0.3))
                    .frame(width: 2, height: (streamBottom - streamTop) * 0.7)
                    .position(x: streamX + CGFloat(side) * 5, y: (streamTop + streamBottom) / 2 + 10)
                    .allowsHitTesting(false)
            }

            ForEach(pourDrops) { drop in
                Circle()
                    .fill(ing.color.opacity(drop.opacity * 0.6))
                    .frame(width: drop.size * 0.4, height: drop.size * 0.4)
                    .position(x: streamX + CGFloat.random(in: -10...10), y: streamBottom)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - 顶部分类栏
    private func categoryBar(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(IngredientCategory.allCases, id: \.rawValue) { cat in
                let isActive = selectedCategory == cat
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selectedCategory = cat }
                    if let first = allIngredients.first(where: { $0.category == cat }) {
                        withAnimation(.easeInOut(duration: 0.3)) { scrollProxy?.scrollTo(first.id, anchor: .center) }
                    }
                } label: {
                    Text(cat.rawValue)
                        .font(.system(size: 18, weight: isActive ? .bold : .medium, design: .monospaced))
                        .foregroundColor(isActive ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 5).fill(isActive ? accent.opacity(0.9) : Color.clear))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 酒瓶名称牌子
    private var bottleNameTag: some View {
        ZStack {
            Image("name_tag").resizable().scaledToFit().frame(height: 50)
            if let id = centeredBottleID, let ing = allIngredients.first(where: { $0.id == id }) {
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
                    if let id = newID, let ing = allIngredients.first(where: { $0.id == id }) {
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
        let isBeingDragged = draggingIngredient?.id == ingredient.id && isDragging

        ZStack(alignment: .bottom) {
            if UIImage(named: ingredient.id) != nil {
                Image(ingredient.id).resizable().scaledToFit().frame(width: bottleW, height: bottleH)
            } else {
                RoundedRectangle(cornerRadius: 6).fill(ingredient.color.opacity(0.5)).frame(width: bottleW, height: bottleH)
            }
        }
        .opacity(isBeingDragged ? 0.25 : 1.0)
        .scaleEffect(isCentered || isBeingDragged ? 1.0 : 0.9)
        .animation(.easeOut(duration: 0.1), value: isCentered)
        .id(ingredient.id)
        .background(
            GeometryReader { geo in
                let frame = geo.frame(in: .named("screen"))
                Color.clear.preference(key: BottleCenterPreferenceKey.self, value: [BottleCenterData(id: ingredient.id, minX: frame.minX, maxX: frame.maxX)])
            }
        )
        .allowsHitTesting(isCentered)
        .gesture(
            isCentered ?
            DragGesture(minimumDistance: 6, coordinateSpace: .named("screen"))
                .onChanged { value in handleDragChanged(ingredient: ingredient, location: value.location) }
                .onEnded { _ in handleDragEnded() }
            : nil
        )
    }

    // MARK: - Shaker + 刻度条
    private func glassAndGauge(w: CGFloat, h: CGFloat) -> some View {
        let shakerBodyH: CGFloat = h * 0.12
        let shakerBodyW: CGFloat = shakerBodyH * 0.8
        let shakerLidH: CGFloat = shakerBodyH * 0.48
        let shakerLidW: CGFloat = shakerBodyW
        
        return ZStack {
            // Shaker
            VStack(spacing: 0) {
                Image("shaker_lid")
                    .resizable().scaledToFit()
                    .frame(width: shakerLidW, height: shakerLidH)
                    .rotationEffect(.degrees(lidRotation), anchor: lidRotation >= 0 ? UnitPoint(x: 1.0, y: 1.0) : UnitPoint(x: 0.0, y: 1.0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: lidRotation)

                Image("shaker")
                    .resizable().scaledToFit()
                    .frame(width: shakerBodyW, height: shakerBodyH)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { shakerBodyFrame = geo.frame(in: .named("screen")) }
                                .onChange(of: geo.frame(in: .named("screen"))) { newFrame in shakerBodyFrame = newFrame }
                        }
                    )
            }
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        glassFrame = geo.frame(in: .named("screen"))
                        shakerFrame = geo.frame(in: .named("screen"))
                    }
                    .onChange(of: geo.frame(in: .named("screen"))) { newFrame in
                        glassFrame = newFrame
                        shakerFrame = newFrame
                    }
                }
            )

            // 提示文字 + 箭头
            HStack(spacing: 8) {
                if bottleOnLeft {
                    Image(systemName: "arrow.right").font(.system(size: 18, weight: .bold)).foregroundColor(isInPourZone ? accent : Color.white.opacity(0.5))
                    Text(isInPourZone ? "Pouring..." : "Drag Here!").font(.system(size: 15, weight: .medium, design: .monospaced)).foregroundColor(isInPourZone ? accent : Color.white.opacity(0.5))
                } else {
                    Text(isInPourZone ? "Pouring..." : "Drag Here!").font(.system(size: 15, weight: .medium, design: .monospaced)).foregroundColor(isInPourZone ? accent : Color.white.opacity(0.5))
                    Image(systemName: "arrow.left").font(.system(size: 18, weight: .bold)).foregroundColor(isInPourZone ? accent : Color.white.opacity(0.5))
                }
            }
            .offset(x: bottleOnLeft ? -130 : 130, y: -40)
            .animation(.easeInOut(duration: 0.2), value: bottleOnLeft)
            .animation(.easeInOut(duration: 0.15), value: isInPourZone)

            // 刻度条
            PourGaugeView(segments: gameState.pourSegments, totalPoured: gameState.totalPoured)
                .frame(width: 34, height: 160)
                .offset(x: bottleOnLeft ? 130 : -130)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: bottleOnLeft)
        }
    }

    // MARK: - 操作按钮
    private var actionButtons: some View {
        HStack(spacing: 300) {
            InteractiveButton(fallbackIcon: "arrow.counterclockwise", fallbackLabel: "Restart", color: Color.white.opacity(0.15)) {
                withAnimation(.spring()) { gameState.resetMix(); lidRotation = 0; addedGarnishes = [] }
            }
            InteractiveButton(fallbackIcon: "wand.and.stars", fallbackLabel: "Shake!", color: gameState.totalPoured > 0.05 ? accent : Color.white.opacity(0.08)) {
                guard gameState.totalPoured > 0.05 else { return }
                gameState.performMatch()
                gameState.currentPage = .mixing
            }
            .opacity(gameState.totalPoured > 0.05 ? 1.0 : 0.4)
        }
    }

    // MARK: - 拖拽处理
    private func handleDragChanged(ingredient: Ingredient, location: CGPoint) {
        if !isDragging {
            isDragging = true
            draggingIngredient = ingredient
            SoundManager.shared.play("pick_up")
        }
        dragLocation = location
        
        let screenCenterX = screenSize.width / 2
        bottleOnLeft = location.x < screenCenterX

        let pourZone = glassFrame.insetBy(dx: -50, dy: -60)
        let wasInZone = isInPourZone
        isInPourZone = pourZone.contains(location)
        let canPour = location.y < shakerBodyFrame.minY
        
        if isInPourZone && canPour {
            lidRotation = location.x < shakerFrame.midX ? 90 : -90
        } else {
            lidRotation = 0
        }

        if isInPourZone && canPour && !wasInZone { startPouring(ingredient: ingredient) }
        if (!isInPourZone || !canPour) && wasInZone { stopPouring() }
    }

    private func handleDragEnded() {
        stopPouring()
        SoundManager.shared.play("put_down")
        withAnimation(.spring(response: 0.25)) {
            isDragging = false
            draggingIngredient = nil
            isInPourZone = false
            lidRotation = 0
            bottleOnLeft = true
        }
    }

    // MARK: - 幽灵酒瓶
    private func dragGhostView(ingredient: Ingredient, ghostH: CGFloat) -> some View {
        let ghostW = ghostH * 0.5
        let tiltAngle: Double = {
            if isInPourZone && dragLocation.y < shakerBodyFrame.minY {
                return dragLocation.x < glassFrame.midX ? 90 : -90
            }
            return dragLocation.x < screenSize.width / 2 ? 30 : -30
        }()

        return Group {
            if UIImage(named: ingredient.id) != nil {
                Image(ingredient.id).resizable().scaledToFit().frame(width: ghostW, height: ghostH)
            } else {
                RoundedRectangle(cornerRadius: 10).fill(ingredient.color.opacity(0.7)).frame(width: ghostW * 0.45, height: ghostH)
            }
        }
        .rotationEffect(.degrees(tiltAngle), anchor: .center)
        .shadow(color: ingredient.color.opacity(0.4), radius: 12)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isInPourZone)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: tiltAngle)
    }

    // MARK: - 倒酒逻辑
    private func startPouring(ingredient: Ingredient) {
        guard !gameState.isFull else { return }
        SoundManager.shared.playLoop("pouring")
        pourTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async { [self] in
                guard !gameState.isFull, dragLocation.y < shakerBodyFrame.minY else {
                    pourTimer?.invalidate()
                    pourTimer = nil
                    SoundManager.shared.stopLoop("pouring")
                    return
                }
                withAnimation(.easeInOut(duration: 0.1)) {
                    gameState.pourIngredient(ingredient, increment: 0.008)
                }
                let drop = PourDrop(
                    x: glassFrame.midX + CGFloat.random(in: -8...8),
                    y: shakerBodyFrame.minY + CGFloat.random(in: -5...5),
                    opacity: Double.random(in: 0.4...0.8),
                    color: ingredient.color,
                    size: CGFloat.random(in: 6...12)
                )
                pourDrops.append(drop)
                let dropID = drop.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    pourDrops.removeAll { $0.id == dropID }
                }
            }
        }
    }
    private func stopPouring() {
        pourTimer?.invalidate()
        pourTimer = nil
        SoundManager.shared.stopLoop("pouring")
    }

    // MARK: - 碗视图
    private func bowlView(bowl: GarnishBowl, screenWidth: CGFloat, screenHeight: CGFloat, enabled: Bool) -> some View {
        Image(bowl.bowlImageName)
            .resizable().scaledToFit()
            .frame(width: bowl.bowlSize, height: bowl.bowlSize)
            .position(x: screenWidth * bowl.positionRatio.x, y: screenHeight * bowl.positionRatio.y)
            .opacity(enabled ? 1.0 : 0.4)
            .overlay(
                VStack(spacing: 0) {
                    Color.clear.frame(width: bowl.bowlSize, height: bowl.bowlSize / 2).contentShape(Rectangle())
                        .gesture(enabled ? DragGesture(minimumDistance: 4, coordinateSpace: .named("screen"))
                            .onChanged { handleBowlDragChanged(bowl: bowl, location: $0.location) }
                            .onEnded { handleBowlDragEnded(bowl: bowl, location: $0.location) } : nil)
                    Color.clear.frame(width: bowl.bowlSize, height: bowl.bowlSize / 2).allowsHitTesting(false)
                }.position(x: screenWidth * bowl.positionRatio.x, y: screenHeight * bowl.positionRatio.y)
            )
    }

    private func handleBowlDragChanged(bowl: GarnishBowl, location: CGPoint) {
        if !isGarnishDragging { isGarnishDragging = true; draggingBowl = bowl; SoundManager.shared.play("pick_up") }
        garnishDragLocation = location
        let pourZone = glassFrame.insetBy(dx: -50, dy: -60)
        lidRotation = pourZone.contains(location) ? (location.x < shakerFrame.midX ? 90 : -90) : 0
    }

    private func handleBowlDragEnded(bowl: GarnishBowl, location: CGPoint) {
        let pourZone = glassFrame.insetBy(dx: -50, dy: -60)
        if pourZone.contains(location) { triggerGarnishDrop(bowl: bowl) } else { SoundManager.shared.play("put_down") }
        isGarnishDragging = false; draggingBowl = nil
        if pourZone.contains(location) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { withAnimation(.spring(response: 0.3)) { lidRotation = 0 } }
        } else { lidRotation = 0 }
    }

    private func triggerGarnishDrop(bowl: GarnishBowl) {
        garnishDropID = bowl.id; garnishDropAnimation = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { withAnimation { garnishDropAnimation = true } }
        SoundManager.shared.play(bowl.soundName)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { addedGarnishes.append(bowl.id); garnishDropID = nil; garnishDropAnimation = false }
    }
}

// MARK: - 量杯刻度条
struct PourGaugeView: View {
    let segments: [GameState.PourSegment]
    let totalPoured: CGFloat
    var gaugeHeight: CGFloat = 160
    let gaugeWidth: CGFloat = 28

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)).frame(width: gaugeWidth, height: gaugeHeight)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.5), lineWidth: 3))
            VStack(spacing: 0) {
                ForEach(segments.reversed()) { segment in
                    Rectangle().fill(segment.color.opacity(0.85)).frame(width: gaugeWidth - 4, height: max(0, (gaugeHeight - 4) * segment.amount))
                }
            }
            .frame(width: gaugeWidth - 4, alignment: .bottom).clipShape(RoundedRectangle(cornerRadius: 5)).padding(.bottom, 2)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: totalPoured)
            VStack(spacing: 0) { ForEach(0..<8, id: \.self) { _ in Spacer(); Rectangle().fill(Color.white.opacity(0.3)).frame(width: gaugeWidth + 4, height: 3) } }.frame(height: gaugeHeight)
        }
        .frame(width: gaugeWidth + 20, height: gaugeHeight)
        .overlay(alignment: .bottomTrailing) {
            Triangle().fill(Color(red: 0.58, green: 0.33, blue: 0.18)).frame(width: 16, height: 10).rotationEffect(.degrees(-90))
                .offset(x: 8, y: -gaugeHeight * totalPoured + 5).animation(.spring(response: 0.3, dampingFraction: 0.7), value: totalPoured)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct InteractiveButton: View {
    let fallbackIcon: String; let fallbackLabel: String; let color: Color; let action: () -> Void
    @State private var isPressed = false
    var body: some View {
        Image("button").resizable().scaledToFit().frame(height: 50)
            .overlay(HStack(spacing: 6) { Image(systemName: fallbackIcon).font(.system(size: 15, weight: .bold)); Text(fallbackLabel).font(.system(size: 20, weight: .bold, design: .monospaced)) }.foregroundColor(.white))
            .scaleEffect(isPressed ? 1.15 : 1.0).animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, pressing: { isPressed = $0 }, perform: action)
    }
}
