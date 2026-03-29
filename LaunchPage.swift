import SwiftUI

// MARK: - 固定种子随机数（保证每次启动图案完全一致）
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func nextDouble() -> Double {
        Double(next() & 0x7FFFFFFF) / Double(0x7FFFFFFF)
    }
}

// MARK: - 单个酒瓶数据模型
private struct BottleItem: Identifiable {
    let id: Int
    let imageName: String  // random_1 ~ random_4
    let xRatio: CGFloat    // 相对屏幕宽度 (0~1)
    let yRatio: CGFloat    // 相对屏幕高度 (0~1)
    let tilt: Double       // 倾斜角度（度）
    let scale: CGFloat     // 尺寸微变
    let opacity: Double    // 透明度微变
}

// MARK: - 布局生成（在 View 外执行，只算一次）
private let bottleLayout: [BottleItem] = {
    var rng = SeededRandom(seed: 2025)

    // 可修改：列数 & 行数（控制酒瓶密度）
    let cols = 11
    let rows = 7

    // 可修改：随机扰动幅度（0 = 完全整齐网格，0.2 = 轻微随机偏移）
    let jitter: Double = 0.1

    var items: [BottleItem] = []

    for row in 0..<rows {
        for col in 0..<cols {

            // 蜂窝排列：奇数行向右偏移半格
            let honeycombOffset: CGFloat = row % 2 == 1
                ? (1.0 / CGFloat(cols)) * 0.5
                : 0

            // 格子中心基础坐标
            let baseX = (CGFloat(col) + 0.5) / CGFloat(cols) + honeycombOffset
            let baseY = (CGFloat(row) + 0.5) / CGFloat(rows)

            // 随机扰动（让排列看起来自然，不死板）
            let dx = CGFloat((rng.nextDouble() - 0.5) * jitter / Double(cols))
            let dy = CGFloat((rng.nextDouble() - 0.5) * jitter / Double(rows))

            // 可修改：倾斜范围（当前 ±14 度）
            let tilt = (rng.nextDouble() - 0.5) * 28

            // 可修改：尺寸微变范围（0.8 ~ 1.1 倍）
            let scale = CGFloat(0.8 + rng.nextDouble() * 0.3)

            // 可修改：透明度范围（0.07 ~ 0.16）
            let opacity = 0.07 + rng.nextDouble() * 0.09

            // 循环使用 random_1 ~ random_4
            let imageIndex = (row * cols + col) % 4 + 1

            items.append(BottleItem(
                id: row * cols + col,
                imageName: "random_\(imageIndex)",
                xRatio: min(max(baseX + dx, 0.02), 0.98),
                yRatio: min(max(baseY + dy, 0.02), 0.98),
                tilt: tilt,
                scale: scale,
                opacity: opacity
            ))
        }
    }
    return items
}()

// MARK: - 闪烁点加载动画
struct DotsLoadingView: View {
    // 可修改：每个点的延迟间隔（秒）
    let delay: Double = 0.3
    // 可修改：单个点亮灭时长
    let duration: Double = 0.5

    // 用 Timer 驱动，确保持续循环不停
    @State private var activeIndex: Int = 0
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    // 可修改：点的颜色
                    .fill(Color(red: 0.3, green: 0.15, blue: 0.05)
                        .opacity(activeIndex == index ? 0.75 : 0.2))
                    // 可修改：点的大小
                    .frame(width: 8, height: 8)
                    .scaleEffect(activeIndex == index ? 1.4 : 1.0)
                    .animation(.easeInOut(duration: duration), value: activeIndex)
            }
        }
        .onReceive(timer) { _ in
            activeIndex = (activeIndex + 1) % 3
        }
    }
}

// MARK: - LaunchPage
struct LaunchPage: View {
    @EnvironmentObject var gameState: GameState

    // 可修改：加载页停留时长（秒）
    let displayDuration: Double = 5.0

    // 可修改：酒瓶基础宽度（pt）
    let bottleWidth: CGFloat = 55
    // 可修改：高宽比（和你的图片比例保持一致，200×440 = 2.2）
    let bottleAspect: CGFloat = 2.2

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {


                Color(red: 253/255, green: 235/255, blue: 189/255)
                    .ignoresSafeArea()

//                Image("transpage")
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: w, height: h)
//                    .clipped()
//                    .ignoresSafeArea()

                ForEach(bottleLayout) { item in
                    Image(item.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width:  bottleWidth * item.scale,
                            height: bottleWidth * bottleAspect * item.scale
                        )
                        .rotationEffect(.degrees(item.tilt))
                        .opacity(item.opacity)
                        .position(
                            x: item.xRatio * w,
                            y: item.yRatio * h
                        )
                }

                VStack(spacing: 20) {
                    Text("What will you mix today?")
                        // 可修改：字体大小
                        .font(.system(size: 30, weight: .medium, design: .monospaced))
                        // 可修改：文字颜色
                        .foregroundColor(Color(red: 0.3, green: 0.15, blue: 0.05).opacity(0.85))
                        // 可修改：字间距
                        .tracking(2)

                    DotsLoadingView()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            SoundManager.shared.playBGM("bgm", volume: 0.3)  // 30% 音量
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    gameState.currentPage = .welcome
                }
            }
        }
    }
}
