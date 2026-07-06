import Cocoa

/// Detects *stuck* Secure Event Input and recovers from it by restarting the
/// app that leaked it.
///
/// macOS turns on Secure Event Input (SEI) whenever a password field is focused;
/// while it's on, keystrokes are withheld from every event tap, so BestMouseKeys
/// goes dormant (see `KeyboardMonitor`). That's expected and brief. The real
/// problem is apps that *leak* SEI: 1Password in particular sometimes re-enables
/// it on wake-from-sleep / unlock and never turns it back off, leaving the numpad
/// permanently dead with no password field anywhere in sight.
///
/// Only the process that enabled SEI can disable it — no entitlement lets another
/// process clear it — so the one reliable recovery is to restart the offender.
/// This watchdog watches for SEI that has been continuously on far longer than
/// any genuine password entry and, when the known leaker is running in the
/// background, quits it (releasing the input) and relaunches it unfocused so the
/// user keeps their password manager.
final class SecureInputWatchdog {
    /// Bundle id of the app known to leak Secure Event Input.
    private static let leakerBundleID = "com.1password.1password"

    /// SEI must be continuously on at least this long before we treat it as stuck
    /// rather than a genuine, in-progress password entry.
    private static let stuckThreshold: TimeInterval = 15

    /// Minimum gap between recovery attempts. A legitimately-held SEI (e.g. a web
    /// password field in a browser) won't be cleared by restarting 1Password, so
    /// the cooldown stops us from bouncing it on a loop in that case.
    private static let cooldown: TimeInterval = 120

    /// User toggle (menu item). When off, state is still tracked but no app is
    /// ever restarted.
    var isEnabled = true

    private var seiOnSince: Date?
    private var lastRecoveryAttempt: Date?

    /// Called once per second with the current SEI state and whether the numpad
    /// monitor is supposed to be running.
    func tick(seiActive: Bool, monitoringActive: Bool) {
        guard seiActive else {
            seiOnSince = nil
            return
        }

        let now = Date()
        let onSince = seiOnSince ?? now
        seiOnSince = onSince

        guard isEnabled, monitoringActive else { return }
        guard now.timeIntervalSince(onSince) >= Self.stuckThreshold else { return }
        if let last = lastRecoveryAttempt, now.timeIntervalSince(last) < Self.cooldown { return }

        // Don't disturb the leaker while the user is actually in it — they may be
        // typing the master password, which is a legitimate SEI we must not break.
        guard let leaker = runningLeaker(), !leaker.isActive else { return }

        lastRecoveryAttempt = now
        restart(leaker)
    }

    private func runningLeaker() -> NSRunningApplication? {
        NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.leakerBundleID)
            .first
    }

    /// Quit the leaker (releasing its Secure Event Input) and relaunch it in the
    /// background so the user keeps their password manager available.
    private func restart(_ app: NSRunningApplication) {
        let bundleURL = app.bundleURL
        let name = app.localizedName ?? Self.leakerBundleID
        print("[BestMouseKeys] Secure Input stuck \(Int(Self.stuckThreshold))s+ — restarting \(name) to release it.")

        app.terminate()

        // Give it a moment to quit and drop SEI, then relaunch unfocused.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard let url = bundleURL else { return }
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            config.addsToRecentItems = false
            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, error in
                if let error {
                    print("[BestMouseKeys] Failed to relaunch \(name): \(error)")
                }
            }
        }
    }
}
