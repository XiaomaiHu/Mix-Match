import SwiftUI
import CoreMotion

struct MixingPage: View {
    @EnvironmentObject var gameState: GameState
    var isChallenge: Bool = false

    @State private var shakeDetected = false
    @State private var motionManager = CMMotionManager()
    @State private var shakerRotation: Double = 0
    @State private var pulseScale: Double = 1.0
    @State private var shakeCount: Int = 0
    let requiredShakes = 5

    let accentColor = Color(red: 0.58, green: 0.33, blue: 0.18)

    // ═══════════════════════════════════════════════════════════
    // ★ 统一布局参数（所有页面保持一致）
    // ═══════════════════════════════════════════════════════════
    
    // ★ 墙上装饰画位置（统一为 0.4）
    let decoY: CGFloat = 0.4
    
    // ★ 按钮位置（统一为 0.9）
    let buttonY: CGFloat = 0.9
    
    // ═══════════════════════════════════════════════════════════

    // 配料碗拖拽状态
    @State private var draggingBowl: GarnishBowl? = nil
    @State private var garnishDragLocation: CGPoint = .zero
    @State private var isGarnishDragging: Bool = false
    @State private var addedGarnishes: [String] = []
    @State private var garnishDropAnimation: Bool = false
    @State private var garnishDropID: String? = nil

    // 盖子旋转
    @State private var lidRotation: Double = 0

    // Shaker 位置追踪
    @State private var shakerFrame: CGRect = .zero
    @State private var glassFrame: CGRect = .zero

    private var revealOpacity: Double {
        let base = 0.2
        let full = 1.0
        let progress = min(Double(shakeCount) / Double(requiredShakes), 1.0)
        return base + (full - base) * progress
    }

    private var canReveal: Bool {
        shakeCount >= requiredShakes
    }

    private var bowlsEnabled: Bool {
        canReveal
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

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

                // 顶部标题
                VStack(spacing: 0) {
                    Text("Shake your iPad or click the mixer!")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.top, h * 0.025)
                    Spacer()
                }

                // Shaker 居中
                VStack(spacing: 0) {
                    Spacer().frame(height: h * 0.1)

                    VStack(spacing: 0) {
                        Image("shaker_lid")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 60)
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
                            .frame(width: 100, height: 125)
                    }
                    .rotationEffect(.degrees(shakerRotation))
                    .animation(.spring(response: 0.15, dampingFraction: 0.3), value: shakerRotation)
                    .onTapGesture {
                        handleShake()
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                glassFrame = geo.frame(in: .named("shakeScreen"))
                                shakerFrame = geo.frame(in: .named("shakeScreen"))
                            }
                            .onChange(of: geo.frame(in: .named("shakeScreen"))) { newFrame in
                                glassFrame = newFrame
                                shakerFrame = newFrame
                            }
                        }
                    )

                    // 摇晃图标 + 进度点
                    VStack(spacing: 12) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 32))
                            .foregroundColor(accentColor)
                            .scaleEffect(pulseScale)

                        HStack(spacing: 6) {
                            ForEach(0..<requiredShakes, id: \.self) { i in
                                Circle()
                                    .fill(i < shakeCount ? accentColor : Color.white.opacity(0.2))
                                    .frame(width: 12, height: 12)
                                    .animation(.spring(response: 0.3), value: shakeCount)
                            }
                        }
                    }
                    .padding(.top, 24)

                    Spacer().frame(height: h * 0.26)
                }

                // 四个配料碗
                ForEach(shakePageBowls) { bowl in
                    shakeBowlView(bowl: bowl, screenWidth: w, screenHeight: h)
                }

                // 掉落动画
                if let dropID = garnishDropID,
                   let bowl = shakePageBowls.first(where: { $0.id == dropID }) {
                    Image(bowl.garnishImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: bowl.garnishDisplayWidth * 1.5, height: bowl.garnishDisplayHeight * 1.5)
                        .position(
                            x: glassFrame.midX,
                            y: garnishDropAnimation ? glassFrame.midY : glassFrame.minY - 40
                        )
                        .opacity(garnishDropAnimation ? 0 : 1)
                        .scaleEffect(garnishDropAnimation ? 0.3 : 1.0)
                        .animation(.easeIn(duration: 0.35), value: garnishDropAnimation)
                        .allowsHitTesting(false)
                        .zIndex(97)
                }

                // 拖拽时的幽灵配料
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

                // ── 底部按钮（★ 统一位置 0.9）──
                HStack(spacing: 300) {
                    InteractiveButton(
                        fallbackIcon: "arrow.counterclockwise",
                        fallbackLabel: "Back",
                        color: Color.white.opacity(0.15)
                    ) {
                        stopMotionDetection()
                        gameState.currentPage = .selectIngredients
                    }

                    InteractiveButton(
                        fallbackIcon: "wand.and.stars",
                        fallbackLabel: "Reveal!",
                        color: accentColor
                    ) {
                        guard canReveal else { return }
                        triggerReveal()
                    }
                    .opacity(revealOpacity)
                }
                .position(x: w * 0.5, y: h * buttonY)
            }
            .coordinateSpace(name: "shakeScreen")
        }
        .onAppear {
            startMotionDetection()
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
        }
        .onDisappear {
            stopMotionDetection()
        }
    }

    // MARK: - 碗视图
    private func shakeBowlView(bowl: GarnishBowl, screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        ZStack {
            Image(bowl.bowlImageName)
                .resizable()
                .scaledToFit()
                .frame(width: bowl.bowlSize, height: bowl.bowlSize)
                .opacity(bowlsEnabled ? 1.0 : 0.4)
                .animation(.easeInOut(duration: 0.3), value: bowlsEnabled)

            VStack(spacing: 0) {
                Color.clear
                    .frame(width: bowl.bowlSize, height: bowl.bowlSize / 2)
                    .contentShape(Rectangle())
                    .allowsHitTesting(bowlsEnabled)
                    .gesture(
                        bowlsEnabled ?
                        DragGesture(minimumDistance: 4, coordinateSpace: .named("shakeScreen"))
                            .onChanged { value in
                                handleBowlDragChanged(bowl: bowl, location: value.location)
                            }
                            .onEnded { value in
                                handleBowlDragEnded(bowl: bowl, location: value.location)
                            }
                        : nil
                    )
                Color.clear
                    .frame(width: bowl.bowlSize, height: bowl.bowlSize / 2)
                    .allowsHitTesting(false)
            }
        }
        .position(
            x: screenWidth * bowl.positionRatio.x,
            y: screenHeight * bowl.positionRatio.y
        )
    }

    // MARK: - 碗的拖拽处理
    private func handleBowlDragChanged(bowl: GarnishBowl, location: CGPoint) {
        if !isGarnishDragging {
            isGarnishDragging = true
            draggingBowl = bowl
            SoundManager.shared.play("pick_up")
        }
        garnishDragLocation = location

        let pourZone = glassFrame.insetBy(dx: -50, dy: -60)
        if pourZone.contains(location) {
            let shakerCenterX = shakerFrame.midX
            lidRotation = location.x < shakerCenterX ? 90 : -90
        } else {
            lidRotation = 0
        }
    }

    private func handleBowlDragEnded(bowl: GarnishBowl, location: CGPoint) {
        let pourZone = glassFrame.insetBy(dx: -50, dy: -60)
        if pourZone.contains(location) {
            triggerGarnishDrop(bowl: bowl)
        } else {
            SoundManager.shared.play("put_down")
        }
        isGarnishDragging = false
        draggingBowl = nil
        if pourZone.contains(location) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.spring(response: 0.3)) {
                    lidRotation = 0
                }
            }
        } else {
            lidRotation = 0
        }
    }

    private func triggerGarnishDrop(bowl: GarnishBowl) {
        garnishDropID = bowl.id
        garnishDropAnimation = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation {
                garnishDropAnimation = true
            }
        }

        SoundManager.shared.play(bowl.soundName)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            addedGarnishes.append(bowl.id)
            garnishDropID = nil
            garnishDropAnimation = false
        }
    }

    // MARK: - 点击杯子触发 shake
    private func handleShake() {
        guard shakeCount < requiredShakes else { return }
        shakeCount += 1
        shakerRotation = Double.random(in: -10...10)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            shakerRotation = 0
        }
        if shakeCount >= requiredShakes {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                shakerRotation = Double.random(in: -5...5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    shakerRotation = 0
                }
            }
        }
    }

    // MARK: - 摇晃检测
    private func startMotionDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { data, error in
            guard let data = data else { return }
            let magnitude = sqrt(
                data.acceleration.x * data.acceleration.x +
                data.acceleration.y * data.acceleration.y +
                data.acceleration.z * data.acceleration.z
            )
            if magnitude > 2.5 {
                DispatchQueue.main.async {
                    if !shakeDetected {
                        shakeDetected = true
                        handleShake()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            shakeDetected = false
                        }
                    }
                }
            }
        }
    }

    private func stopMotionDetection() {
        motionManager.stopAccelerometerUpdates()
        shakeDetected = false
    }

    private func triggerReveal() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                shakerRotation = Double.random(in: -10...10)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            timer.invalidate()
            shakerRotation = 0
            stopMotionDetection()
            gameState.currentPage = isChallenge ? .challengeReveal : .reveal
        }
    }
}
