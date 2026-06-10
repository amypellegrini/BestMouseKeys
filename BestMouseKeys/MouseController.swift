import CoreGraphics
import Foundation

extension Notification.Name {
    static let mouseDragStateChanged = Notification.Name("BestMouseKeys.mouseDragStateChanged")
}

enum MouseController {
    /// The mouse button currently held for a synthetic drag, or `nil` when no
    /// drag is in progress. Only one button is ever held at a time.
    private(set) static var draggingButton: CGMouseButton?

    /// Convenience: whether any drag (left or right) is active.
    static var isDragging: Bool { draggingButton != nil }

    /// Shared event source. Using one source for the lifetime of the gesture
    /// helps stricter receivers (Finder) treat down/dragged/up as a single
    /// coherent input gesture rather than unrelated events.
    private static let eventSource: CGEventSource? = CGEventSource(stateID: .hidSystemState)

    /// Max step size when interpolating warp motion during a drag. Smaller
    /// steps trade a few extra event posts for reliable drag tracking.
    private static let dragStepSize: CGFloat = 30

    /// 60 Hz timer that re-posts `leftMouseDragged` at the current cursor
    /// position while a drag is active. Keeps drag previews (Chrome tab
    /// ghost, NSDraggingSession image) tracking the cursor smoothly even
    /// when no key is being pressed.
    private static var dragHeartbeat: DispatchSourceTimer?

    private static let doubleClickThreshold: TimeInterval = 0.3
    private static let doubleClickDistance: CGFloat = 5
    private static var lastClickTime: TimeInterval = 0
    private static var lastClickPosition: CGPoint = .zero

    /// Performs a left-click at the current cursor position. Two calls within
    /// `doubleClickThreshold` and `doubleClickDistance` form a double-click
    /// (the second click is posted with `clickState = 2`).
    static func tap() {
        let now = ProcessInfo.processInfo.systemUptime
        let position = currentPosition()

        let dx = position.x - lastClickPosition.x
        let dy = position.y - lastClickPosition.y
        let withinTime = now - lastClickTime < doubleClickThreshold
        let withinDistance = (dx * dx + dy * dy) < doubleClickDistance * doubleClickDistance
        let isDouble = withinTime && withinDistance

        let clickState: Int64 = isDouble ? 2 : 1
        postMouse(.leftMouseDown, at: position, clickState: clickState)
        postMouse(.leftMouseUp, at: position, clickState: clickState)

        if isDouble {
            lastClickTime = 0
        } else {
            lastClickTime = now
            lastClickPosition = position
        }
    }

    /// Performs a right-click at the current cursor position.
    static func rightTap() {
        let position = currentPosition()
        postMouse(.rightMouseDown, at: position, button: .right, clickState: 1)
        postMouse(.rightMouseUp, at: position, button: .right, clickState: 1)
    }

    /// Moves the cursor by the given delta (in points).
    static func move(dx: CGFloat, dy: CGFloat) {
        let current = currentPosition()
        warp(to: CGPoint(x: current.x + dx, y: current.y + dy))
    }

    /// Warps the cursor to an absolute CGEvent (top-left origin) point.
    /// While a drag is active, posts intermediate dragged events (matching the
    /// held button) along the path with small delays so receivers like Finder
    /// track the gesture rather than drop it on a discontinuous teleport.
    static func warp(to point: CGPoint) {
        if isDragging {
            let start = currentPosition()
            let dx = point.x - start.x
            let dy = point.y - start.y
            let distance = (dx * dx + dy * dy).squareRoot()
            let steps = max(1, Int((distance / dragStepSize).rounded(.up)))
            let stepDx = dx / CGFloat(steps)
            let stepDy = dy / CGFloat(steps)
            for i in 1...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let p = CGPoint(x: start.x + dx * t, y: start.y + dy * t)
                postDragged(at: p, deltaX: stepDx, deltaY: stepDy)
                usleep(1500)
            }
        } else {
            postMouse(.mouseMoved, at: point)
        }
    }

    /// Toggles a synthetic button hold for `button` (default left). On press:
    /// posts `<button>MouseDown` then a 12 px kick past the system
    /// drag-distance threshold. On release: posts a zero-delta settle event,
    /// then `<button>MouseUp`.
    ///
    /// Only one button is held at a time. If a drag is already in progress —
    /// with *either* button — this call drops it, regardless of the `button`
    /// argument, so the two drag toggles act as a shared grab/drop pair.
    static func toggleDrag(button: CGMouseButton = .left) {
        let position = currentPosition()

        if let held = draggingButton {
            stopDragHeartbeat()
            postDragged(at: position, deltaX: 0, deltaY: 0)
            usleep(2000)
            postMouse(upType(for: held), at: position, button: held, clickState: 1)
            draggingButton = nil
        } else {
            postMouse(downType(for: button), at: position, button: button, clickState: 1)
            draggingButton = button
            // Single 12 px kick to cross drag-distance thresholds (Finder ~3 px,
            // AppKit ~5 px, Chrome tab tracker ~8-10 px).
            usleep(5000)
            postDragged(
                at: CGPoint(x: position.x + 12, y: position.y),
                deltaX: 12,
                deltaY: 0
            )
            startDragHeartbeat()
        }

        NotificationCenter.default.post(name: .mouseDragStateChanged, object: nil)
    }

    private static func downType(for button: CGMouseButton) -> CGEventType {
        button == .right ? .rightMouseDown : .leftMouseDown
    }

    private static func upType(for button: CGMouseButton) -> CGEventType {
        button == .right ? .rightMouseUp : .leftMouseUp
    }

    private static func startDragHeartbeat() {
        stopDragHeartbeat()
        let timer = DispatchSource.makeTimerSource(
            queue: DispatchQueue.global(qos: .userInteractive)
        )
        timer.schedule(deadline: .now() + .milliseconds(16), repeating: .milliseconds(16))
        timer.setEventHandler {
            guard isDragging else { return }
            postDragged(at: currentPosition(), deltaX: 0, deltaY: 0)
        }
        timer.resume()
        dragHeartbeat = timer
    }

    private static func stopDragHeartbeat() {
        dragHeartbeat?.cancel()
        dragHeartbeat = nil
    }

    /// Releases an active drag if one is in progress. No-op otherwise.
    static func releaseDragIfNeeded() {
        if let button = draggingButton { toggleDrag(button: button) }
    }

    private static func currentPosition() -> CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    private static func postMouse(
        _ type: CGEventType,
        at point: CGPoint,
        button: CGMouseButton = .left,
        clickState: Int64? = nil
    ) {
        guard let event = CGEvent(
            mouseEventSource: eventSource,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: button
        ) else { return }
        if let clickState {
            event.setIntegerValueField(.mouseEventClickState, value: clickState)
        }
        event.post(tap: .cghidEventTap)
    }

    private static func postDragged(at point: CGPoint, deltaX: CGFloat, deltaY: CGFloat) {
        let button = draggingButton ?? .left
        let type: CGEventType = button == .right ? .rightMouseDragged : .leftMouseDragged
        guard let event = CGEvent(
            mouseEventSource: eventSource,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: button
        ) else { return }
        event.setIntegerValueField(.mouseEventClickState, value: 1)
        event.setIntegerValueField(.mouseEventDeltaX, value: Int64(deltaX.rounded()))
        event.setIntegerValueField(.mouseEventDeltaY, value: Int64(deltaY.rounded()))
        event.post(tap: .cghidEventTap)
    }
}
