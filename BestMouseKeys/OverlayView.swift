import SwiftUI

/// Draws the 3×3 overlay grid. The grid occupies `gridRect` (in AppKit screen
/// coordinates), while the SwiftUI view itself fills the entire screen window —
/// so we convert the rect into the view's local (top-left origin) space.
struct OverlayView: View {
    let gridRect: CGRect
    let screenFrame: CGRect

    var body: some View {
        Canvas { ctx, _ in
            let viewRect = CGRect(
                x: gridRect.origin.x - screenFrame.origin.x,
                y: screenFrame.maxY - gridRect.maxY,
                width: gridRect.width,
                height: gridRect.height
            )

            ctx.fill(Path(viewRect), with: .color(.black.opacity(0.18)))
            ctx.stroke(Path(viewRect), with: .color(.white.opacity(0.85)), lineWidth: 2)

            let cellW = viewRect.width / 3
            let cellH = viewRect.height / 3

            var lines = Path()
            for i in 1...2 {
                let x = viewRect.minX + CGFloat(i) * cellW
                lines.move(to: CGPoint(x: x, y: viewRect.minY))
                lines.addLine(to: CGPoint(x: x, y: viewRect.maxY))
            }
            for i in 1...2 {
                let y = viewRect.minY + CGFloat(i) * cellH
                lines.move(to: CGPoint(x: viewRect.minX, y: y))
                lines.addLine(to: CGPoint(x: viewRect.maxX, y: y))
            }
            ctx.stroke(lines, with: .color(.white.opacity(0.6)), lineWidth: 1)

            let numerals: [[Int]] = [
                [7, 8, 9],
                [4, 5, 6],
                [1, 2, 3],
            ]
            let fontSize = min(cellW, cellH) * 0.28
            for (row, line) in numerals.enumerated() {
                for (col, n) in line.enumerated() {
                    let cx = viewRect.minX + (CGFloat(col) + 0.5) * cellW
                    let cy = viewRect.minY + (CGFloat(row) + 0.5) * cellH
                    let text = Text("\(n)")
                        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    ctx.draw(text, at: CGPoint(x: cx, y: cy), anchor: .center)
                }
            }
        }
        .ignoresSafeArea()
    }
}
