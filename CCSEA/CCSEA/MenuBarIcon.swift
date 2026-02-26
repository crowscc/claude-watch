import SwiftUI

struct MenuBarIcon {

    static func render(utilization: Double) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius: CGFloat = 7.0
            let lineWidth: CGFloat = 2.0

            // 背景圆环
            let bgPath = NSBezierPath()
            bgPath.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: 0,
                endAngle: 360
            )
            bgPath.lineWidth = lineWidth
            NSColor.tertiaryLabelColor.setStroke()
            bgPath.stroke()

            // 用量弧形 — 从 12 点方向顺时针
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
                fgPath.lineWidth = lineWidth
                fgPath.lineCapStyle = .round
                NSColor.labelColor.setStroke()
                fgPath.stroke()
            }

            // > 80% 时中心画感叹号
            if utilization > 80 {
                let exclamation = NSBezierPath()
                exclamation.move(to: CGPoint(x: center.x, y: center.y + 3))
                exclamation.line(to: CGPoint(x: center.x, y: center.y - 1))
                exclamation.lineWidth = 1.5
                exclamation.lineCapStyle = .round
                NSColor.labelColor.setStroke()
                exclamation.stroke()
                let dot = NSBezierPath(
                    ovalIn: NSRect(x: center.x - 0.75, y: center.y - 3.5, width: 1.5, height: 1.5)
                )
                NSColor.labelColor.setFill()
                dot.fill()
            }

            return true
        }
        image.isTemplate = true
        return image
    }
}
