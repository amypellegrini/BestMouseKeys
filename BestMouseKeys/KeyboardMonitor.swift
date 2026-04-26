import Cocoa
import CoreGraphics

/// Monitors global numpad key events and translates them into mouse actions.
///
/// Numpad layout (standard mapping):
/// ```
///  7 (↖)  8 (↑)  9 (↗)
///  4 (←)  5 (●)  6 (→)
///  1 (↙)  2 (↓)  3 (↘)
/// ```
/// Numpad Enter toggles the grid overlay; in overlay mode the digits jump
/// the cursor to the chosen cell (recursively), and Enter or Escape cancels.
/// Numpad 0 toggles a synthetic drag (press once to grab, again to drop) —
/// works in both normal and overlay modes.
final class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Points to move per key press.
    private static let step: CGFloat = 20

    func start() {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: KeyboardMonitor.eventCallback,
            userInfo: nil
        ) else {
            print("[BestMouseKeys] Failed to create event tap. Is Accessibility enabled?")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        OverlayController.shared.dismiss()
        MouseController.releaseDragIfNeeded()
    }

    // MARK: - Event tap callback

    private static let eventCallback: CGEventTapCallBack = { _, type, event, _ in
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Numpad 0 — toggles drag (works in both normal and overlay modes).
        if keyCode == 82 {
            DispatchQueue.main.async {
                MouseController.toggleDrag()
            }
            return nil
        }

        // Overlay mode swallows numpad digits and Escape/numpad Enter (cancel).
        if OverlayController.shared.isActive {
            if let digit = numpadDigit(for: keyCode) {
                DispatchQueue.main.async {
                    OverlayController.shared.selectCell(numpadDigit: digit)
                }
                return nil
            }
            if keyCode == 53 || keyCode == 76 { // Escape or numpad Enter
                DispatchQueue.main.async {
                    OverlayController.shared.dismiss()
                }
                return nil
            }
            return Unmanaged.passRetained(event)
        }

        // Numpad Enter enters overlay mode.
        if keyCode == 76 {
            DispatchQueue.main.async {
                OverlayController.shared.show()
            }
            return nil
        }

        // Only intercept numpad keys.
        guard let action = numpadAction(for: keyCode) else {
            return Unmanaged.passRetained(event)
        }

        action()

        // Returning nil swallows the event so it doesn't propagate further.
        return nil
    }

    private static func numpadDigit(for keyCode: Int64) -> Int? {
        switch keyCode {
        case 83: return 1
        case 84: return 2
        case 85: return 3
        case 86: return 4
        case 87: return 5
        case 88: return 6
        case 89: return 7
        case 91: return 8
        case 92: return 9
        default: return nil
        }
    }

    private static func numpadAction(for keyCode: Int64) -> (() -> Void)? {
        let s = step
        switch keyCode {
        case 89: // Numpad 7 — up-left
            return { MouseController.move(dx: -s, dy: -s) }
        case 91: // Numpad 8 — up
            return { MouseController.move(dx: 0, dy: -s) }
        case 92: // Numpad 9 — up-right
            return { MouseController.move(dx: s, dy: -s) }
        case 86: // Numpad 4 — left
            return { MouseController.move(dx: -s, dy: 0) }
        case 87: // Numpad 5 — click
            return { MouseController.click() }
        case 88: // Numpad 6 — right
            return { MouseController.move(dx: s, dy: 0) }
        case 83: // Numpad 1 — down-left
            return { MouseController.move(dx: -s, dy: s) }
        case 84: // Numpad 2 — down
            return { MouseController.move(dx: 0, dy: s) }
        case 85: // Numpad 3 — down-right
            return { MouseController.move(dx: s, dy: s) }
        default:
            return nil
        }
    }
}
