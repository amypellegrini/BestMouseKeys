import CoreGraphics

enum MouseController {
    /// Performs a left-click at the current cursor position.
    static func click() {
        let position = currentPosition()

        guard let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: position,
            mouseButton: .left
        ) else { return }

        guard let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: position,
            mouseButton: .left
        ) else { return }

        mouseDown.post(tap: .cghidEventTap)
        mouseUp.post(tap: .cghidEventTap)
    }

    /// Moves the cursor by the given delta (in points).
    static func move(dx: CGFloat, dy: CGFloat) {
        let current = currentPosition()
        let destination = CGPoint(x: current.x + dx, y: current.y + dy)

        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: destination,
            mouseButton: .left
        ) else { return }

        event.post(tap: .cghidEventTap)
    }

    private static func currentPosition() -> CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }
}
