import SwiftUI

struct MenuBarIcon {

    static func render(utilization: Double) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius: CGFloat = 6.5
            let bgLineWidth: CGFloat = 1.0
            let fgLineWidth: CGFloat = 3.0

            // 背景：细圆环（低透明度）
            let bgPath = NSBezierPath()
            bgPath.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: 0,
                endAngle: 360
            )
            bgPath.lineWidth = bgLineWidth
            NSColor(white: 0, alpha: 0.25).setStroke()
            bgPath.stroke()

            // 进度：粗弧形（从 12 点顺时针）
            let startAngle: CGFloat = 90
            let sweep = CGFloat(utilization / 100.0) * 360.0
            let endAngle = startAngle - sweep

            if utilization > 0 {
                let fgPath = NSBezierPath()
                fgPath.appendArc(
                    withCenter: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true
                )
                fgPath.lineWidth = fgLineWidth
                fgPath.lineCapStyle = .round
                NSColor(white: 0, alpha: 1.0).setStroke()
                fgPath.stroke()
            }

            // > 80% 时中心画感叹号
            if utilization > 80 {
                let exclamation = NSBezierPath()
                exclamation.move(to: CGPoint(x: center.x, y: center.y + 2.5))
                exclamation.line(to: CGPoint(x: center.x, y: center.y - 0.5))
                exclamation.lineWidth = 1.5
                exclamation.lineCapStyle = .round
                NSColor(white: 0, alpha: 1.0).setStroke()
                exclamation.stroke()
                let dot = NSBezierPath(
                    ovalIn: NSRect(x: center.x - 0.75, y: center.y - 3, width: 1.5, height: 1.5)
                )
                NSColor(white: 0, alpha: 1.0).setFill()
                dot.fill()
            }

            return true
        }
        image.isTemplate = true
        return image
    }
}
