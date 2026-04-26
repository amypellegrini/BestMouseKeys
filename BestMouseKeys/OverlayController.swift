import AppKit
import SwiftUI
import CoreGraphics

/// Shows a transparent grid overlay that lets the user warp the cursor by pressing
/// numpad digits. Each press subdivides the grid into another 3×3 over the chosen
/// cell, up to `maxLevel` levels of recursion.
final class OverlayController {
    static let shared = OverlayController()

    private var window: NSWindow?
    private var state: GridState?

    /// Number of subdivisions allowed (level 1 → 2 → 3, then dismiss).
    private static let maxLevel = 3

    var isActive: Bool { window != nil }

    private init() {}

    func show() {
        guard window == nil else { return }
        let screen = currentScreen()
        let frame = screen.frame
        state = GridState(rect: frame, level: 1, screen: screen)

        let w = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.level = .screenSaver
        w.ignoresMouseEvents = true
        w.hasShadow = false
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window = w

        renderOverlay()
        w.orderFront(nil)
    }

    /// Selects a cell by its numpad digit (1-9), warps the cursor to its center,
    /// and either subdivides or dismisses depending on current depth.
    func selectCell(numpadDigit digit: Int) {
        guard let s = state else { return }
        let cell = s.cellRect(forKeypadDigit: digit)
        warpCursor(toScreenPoint: CGPoint(x: cell.midX, y: cell.midY))

        if s.level >= Self.maxLevel {
            dismiss()
        } else {
            state = GridState(rect: cell, level: s.level + 1, screen: s.screen)
            renderOverlay()
        }
    }

    func dismiss() {
        window?.orderOut(nil)
        window = nil
        state = nil
    }

    private func renderOverlay() {
        guard let w = window, let s = state else { return }
        let view = OverlayView(gridRect: s.rect, screenFrame: s.screen.frame)
        w.contentView = NSHostingView(rootView: view)
    }

    private func currentScreen() -> NSScreen {
        let loc = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(loc) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    /// Warps the cursor to a point in AppKit screen coordinates (bottom-left origin).
    /// CGEvent uses top-left origin of the primary display, so we flip Y.
    private func warpCursor(toScreenPoint p: CGPoint) {
        let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
        let cg = CGPoint(x: p.x, y: primary.frame.maxY - p.y)
        CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: cg,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }
}

private struct GridState {
    /// Rect in AppKit screen coordinates (bottom-left origin).
    let rect: CGRect
    let level: Int
    let screen: NSScreen

    func cellRect(forKeypadDigit digit: Int) -> CGRect {
        // Numpad layout:
        //   7 8 9   (top)
        //   4 5 6
        //   1 2 3   (bottom)
        let col: Int
        let rowFromBottom: Int
        switch digit {
        case 7: col = 0; rowFromBottom = 2
        case 8: col = 1; rowFromBottom = 2
        case 9: col = 2; rowFromBottom = 2
        case 4: col = 0; rowFromBottom = 1
        case 5: col = 1; rowFromBottom = 1
        case 6: col = 2; rowFromBottom = 1
        case 1: col = 0; rowFromBottom = 0
        case 2: col = 1; rowFromBottom = 0
        case 3: col = 2; rowFromBottom = 0
        default: return rect
        }
        let cw = rect.width / 3
        let ch = rect.height / 3
        return CGRect(
            x: rect.origin.x + CGFloat(col) * cw,
            y: rect.origin.y + CGFloat(rowFromBottom) * ch,
            width: cw,
            height: ch
        )
    }
}
