import SwiftUI

struct GlassView: View {
    let color: Color
    let fillLevel: Double // 0.0 to 1.0
    let glassType: GlassType
    @State private var waveOffset: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Glass shadow / glow
                glassPath(for: glassType, in: geo.size)
                    .fill(color.opacity(0.2))
                    .blur(radius: 20)
                
                // Liquid
                liquidView(width: w, height: h)
                
                // Glass outline
                glassPath(for: glassType, in: geo.size)
                    .stroke(Color.white.opacity(0.35), lineWidth: 2)
                
                // Glass highlight (reflection)
                glassHighlight(for: glassType, in: geo.size)
                    .fill(Color.white.opacity(0.08))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                waveOffset = .pi * 2
            }
        }
    }
    
    @ViewBuilder
    private func liquidView(width: CGFloat, height: CGFloat) -> some View {
        if fillLevel > 0.01 {
            liquidPath(for: glassType, size: CGSize(width: width, height: height), fill: fillLevel)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.95),
                            color.opacity(0.7),
                            color.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .animation(.easeInOut(duration: 0.4), value: fillLevel)
                .animation(.easeInOut(duration: 0.3), value: color.description)
        }
    }
    
    // MARK: - Glass Paths
    private func glassPath(for type: GlassType, in size: CGSize) -> Path {
        let w = size.width
        let h = size.height
        
        switch type {
        case .highball:
            return highballPath(w: w, h: h)
        case .martini:
            return martiniPath(w: w, h: h)
        case .rocks:
            return rocksPath(w: w, h: h)
        case .hurricane:
            return hurricanePath(w: w, h: h)
        case .coupe:
            return coupePath(w: w, h: h)
        }
    }
    
    private func highballPath(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: w * 0.2, y: h * 0.05))
        p.addLine(to: CGPoint(x: w * 0.8, y: h * 0.05))
        p.addLine(to: CGPoint(x: w * 0.75, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.25, y: h * 0.95))
        p.closeSubpath()
        return p
    }
    
    private func martiniPath(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: w * 0.05, y: h * 0.05))
        p.addLine(to: CGPoint(x: w * 0.95, y: h * 0.05))
        p.addLine(to: CGPoint(x: w * 0.54, y: h * 0.55))
        p.addLine(to: CGPoint(x: w * 0.54, y: h * 0.85))
        p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.28, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.46, y: h * 0.85))
        p.addLine(to: CGPoint(x: w * 0.46, y: h * 0.55))
        p.closeSubpath()
        return p
    }
    
    private func rocksPath(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: w * 0.15, y: h * 0.2))
        p.addLine(to: CGPoint(x: w * 0.85, y: h * 0.2))
        p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.22, y: h * 0.95))
        p.closeSubpath()
        return p
    }
    
    private func hurricanePath(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: w * 0.3, y: h * 0.05))
        p.addQuadCurve(to: CGPoint(x: w * 0.2, y: h * 0.45), control: CGPoint(x: w * 0.08, y: h * 0.2))
        p.addQuadCurve(to: CGPoint(x: w * 0.35, y: h * 0.7), control: CGPoint(x: w * 0.25, y: h * 0.6))
        p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.85))
        p.addLine(to: CGPoint(x: w * 0.28, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.85))
        p.addLine(to: CGPoint(x: w * 0.65, y: h * 0.7))
        p.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.45), control: CGPoint(x: w * 0.75, y: h * 0.6))
        p.addQuadCurve(to: CGPoint(x: w * 0.7, y: h * 0.05), control: CGPoint(x: w * 0.92, y: h * 0.2))
        p.closeSubpath()
        return p
    }
    
    private func coupePath(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: w * 0.1, y: h * 0.15))
        p.addQuadCurve(to: CGPoint(x: w * 0.46, y: h * 0.55), control: CGPoint(x: w * 0.15, y: h * 0.5))
        p.addLine(to: CGPoint(x: w * 0.46, y: h * 0.85))
        p.addLine(to: CGPoint(x: w * 0.3, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.54, y: h * 0.85))
        p.addLine(to: CGPoint(x: w * 0.54, y: h * 0.55))
        p.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.15), control: CGPoint(x: w * 0.85, y: h * 0.5))
        p.closeSubpath()
        return p
    }
    
    private func glassHighlight(for type: GlassType, in size: CGSize) -> Path {
        let w = size.width
        let h = size.height
        var p = Path()
        // Simple left-side reflection strip
        p.addRoundedRect(in: CGRect(x: w * 0.28, y: h * 0.15, width: w * 0.06, height: h * 0.4), cornerSize: CGSize(width: 4, height: 4))
        return p
    }
    
    // MARK: - Liquid Path (simplified rectangle within glass)
    private func liquidPath(for type: GlassType, size: CGSize, fill: Double) -> Path {
        let w = size.width
        let h = size.height
        let clampedFill = min(max(fill, 0), 1.0)
        
        switch type {
        case .highball:
            let top = h * (0.95 - 0.85 * clampedFill)
            let topInset = 0.25 + (0.2 - 0.25) * (1 - (top - h * 0.05) / (h * 0.9))
            var p = Path()
            p.move(to: CGPoint(x: w * topInset, y: top))
            p.addLine(to: CGPoint(x: w * (1 - topInset), y: top))
            p.addLine(to: CGPoint(x: w * 0.75, y: h * 0.94))
            p.addLine(to: CGPoint(x: w * 0.25, y: h * 0.94))
            p.closeSubpath()
            return p
            
        case .martini:
            let maxFillH = h * 0.48
            let fillTop = h * 0.55 - maxFillH * clampedFill
            let topRatio = (h * 0.55 - fillTop) / (h * 0.50)
            let leftX = w * 0.50 - (w * 0.45) * topRatio
            let rightX = w * 0.50 + (w * 0.45) * topRatio
            var p = Path()
            p.move(to: CGPoint(x: leftX, y: fillTop))
            p.addLine(to: CGPoint(x: rightX, y: fillTop))
            p.addLine(to: CGPoint(x: w * 0.535, y: h * 0.545))
            p.addLine(to: CGPoint(x: w * 0.465, y: h * 0.545))
            p.closeSubpath()
            return p
            
        case .rocks:
            let top = h * (0.94 - 0.70 * clampedFill)
            let topInset = 0.22 + (0.15 - 0.22) * clampedFill
            var p = Path()
            p.move(to: CGPoint(x: w * topInset, y: top))
            p.addLine(to: CGPoint(x: w * (1 - topInset), y: top))
            p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.94))
            p.addLine(to: CGPoint(x: w * 0.22, y: h * 0.94))
            p.closeSubpath()
            return p
            
        case .hurricane, .coupe:
            // Simplified: use a rectangle approximation
            let top = h * (0.90 - 0.70 * clampedFill)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.25, y: top))
            p.addLine(to: CGPoint(x: w * 0.75, y: top))
            p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.68))
            p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.68))
            p.closeSubpath()
            return p
        }
    }
}
