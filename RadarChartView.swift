import SwiftUI

struct RadarChartView: View {
    let profile: FlavorProfile
    let size: CGFloat
    
    let accentColor = Color(red: 0.58, green: 0.33, blue: 0.18)
    
    private let labels = ["Sweet", "Sour", "Strong", "Bitter", "Fruity"]
    private let axes = 5
    
    private var values: [Double] {
        [profile.sweet, profile.sour, profile.strong, profile.bitter, profile.fruity]
    }
    
    var body: some View {
        ZStack {
            // Grid rings（虚线网格）
            ForEach(1...4, id: \.self) { ring in
                RadarGridShape(axes: axes, ringLevel: Double(ring) / 4.0)
                    .stroke(accentColor.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .frame(width: size, height: size)
            }
            
            // Axis lines（轴线）
            ForEach(0..<axes, id: \.self) { i in
                let angle = angleForAxis(i)
                let endpoint = pointOnCircle(angle: angle, radius: size / 2)
                Path { path in
                    path.move(to: CGPoint(x: size / 2, y: size / 2))
                    path.addLine(to: CGPoint(x: size / 2 + endpoint.x, y: size / 2 + endpoint.y))
                }
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                .frame(width: size, height: size)
            }
            
            // Data shape fill（数据填充）
            RadarDataShape(values: values, axes: axes)
                .fill(Color(red: 0.91, green: 0.27, blue: 0.37).opacity(0.25))
                .frame(width: size, height: size)
                .animation(.easeInOut(duration: 0.3), value: values)
            
            // Data shape outline（数据轮廓）
            RadarDataShape(values: values, axes: axes)
                .stroke(Color(red: 0.91, green: 0.27, blue: 0.37), lineWidth: 2)
                .frame(width: size, height: size)
                .animation(.easeInOut(duration: 0.3), value: values)
            
            // Data points（数据点）
            ForEach(0..<axes, id: \.self) { i in
                let angle = angleForAxis(i)
                let radius = size / 2 * values[i]
                let point = pointOnCircle(angle: angle, radius: radius)
                
                Circle()
                    .fill(Color(red: 0.91, green: 0.27, blue: 0.37))
                    .frame(width: 6, height: 6)
                    .offset(x: point.x, y: point.y)
                    .animation(.easeInOut(duration: 0.3), value: values[i])
            }
            
            // Labels（标签 - 棕色 monospace）
            ForEach(0..<axes, id: \.self) { i in
                let angle = angleForAxis(i)
                let labelPos = pointOnCircle(angle: angle, radius: size / 2 + 20)
                
                Text(labels[i])
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(accentColor)
                    .offset(x: labelPos.x, y: labelPos.y)
            }
        }
        .frame(width: size + 60, height: size + 60)
    }
    
    private func angleForAxis(_ index: Int) -> Double {
        let slice = (2 * .pi) / Double(axes)
        return slice * Double(index) - .pi / 2
    }
    
    private func pointOnCircle(angle: Double, radius: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(cos(angle)) * radius,
            y: CGFloat(sin(angle)) * radius
        )
    }
}

// MARK: - Grid Shape
struct RadarGridShape: Shape {
    let axes: Int
    let ringLevel: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * ringLevel
        
        var path = Path()
        for i in 0..<axes {
            let angle = (2 * .pi / Double(axes)) * Double(i) - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Data Shape
struct RadarDataShape: Shape {
    var values: [Double]
    let axes: Int
    
    var animatableData: AnimatableVector {
        get { AnimatableVector(values: values) }
        set { values = newValue.values }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        
        var path = Path()
        for i in 0..<axes {
            let angle = (2 * .pi / Double(axes)) * Double(i) - .pi / 2
            let val = i < values.count ? min(max(values[i], 0), 1) : 0
            let radius = maxRadius * val
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Animatable Vector
struct AnimatableVector: VectorArithmetic {
    var values: [Double]
    
    static var zero: AnimatableVector { AnimatableVector(values: []) }
    
    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let count = max(lhs.values.count, rhs.values.count)
        var result = [Double]()
        for i in 0..<count {
            let l = i < lhs.values.count ? lhs.values[i] : 0
            let r = i < rhs.values.count ? rhs.values[i] : 0
            result.append(l + r)
        }
        return AnimatableVector(values: result)
    }
    
    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let count = max(lhs.values.count, rhs.values.count)
        var result = [Double]()
        for i in 0..<count {
            let l = i < lhs.values.count ? lhs.values[i] : 0
            let r = i < rhs.values.count ? rhs.values[i] : 0
            result.append(l - r)
        }
        return AnimatableVector(values: result)
    }
    
    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }
    
    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }
}
