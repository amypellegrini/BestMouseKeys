import Cocoa
import ApplicationServices

final class AccessibilityManager {
    static let shared = AccessibilityManager()

    private init() {}

    var isAccessibilityEnabled: Bool {
        AXIsProcessTrusted()
    }

    /// Requests accessibility access. Returns `true` if already granted.
    /// If not granted, opens the system prompt and returns `false`.
    @discardableResult
    func requestAccessIfNeeded() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
