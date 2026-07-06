import SwiftUI
import Carbon.HIToolbox

@main
struct BestMouseKeysApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            ContentView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var secureInputItem: NSMenuItem!
    private var keyboardMonitor: KeyboardMonitor?
    private var permissionPollTimer: Timer?

    /// Polls Secure Event Input state. When a password field is focused macOS
    /// enables Secure Event Input, which withholds keystrokes from every
    /// CGEventTap — so BestMouseKeys is dormant there and the user gets no
    /// numpad-driven mouse control. There's no notification for this; polling
    /// is the only way to detect it. Used purely to surface the state in the
    /// menu bar so the app's silence is explained rather than mysterious.
    private var secureInputPollTimer: Timer?
    private var isSecureInputActive = false

    /// Recovers from Secure Event Input that some other app has leaked and left
    /// stuck on — see `SecureInputWatchdog`. Fed by the same poll below.
    private let secureInputWatchdog = SecureInputWatchdog()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarItem()
        AccessibilityManager.shared.requestAccessIfNeeded()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dragStateChanged),
            name: .mouseDragStateChanged,
            object: nil
        )

        secureInputPollTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0, repeats: true
        ) { [weak self] _ in
            self?.handleSecureInputTick()
        }

        // Defer to the next runloop tick: creating a CGEvent tap inside
        // applicationDidFinishLaunching produces a port that silently drops
        // events until re-created.
        DispatchQueue.main.async { [weak self] in
            self?.startMonitoringWhenPermitted()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        MouseController.releaseDragIfNeeded()
    }

    @objc private func dragStateChanged() {
        updateMenuBarIcon()
    }

    private func updateMenuBarIcon() {
        guard let button = statusItem.button else { return }

        let symbolName = MouseController.isDragging ? "computermouse.fill" : "computermouse"
        button.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "Best Mouse Keys"
        )

        // Drag (red) takes visual priority; a dim icon flags that numpad
        // control is suspended because a password field has Secure Event
        // Input active.
        if MouseController.isDragging {
            button.contentTintColor = .systemRed
        } else if isSecureInputActive && keyboardMonitor != nil {
            button.contentTintColor = .tertiaryLabelColor
        } else {
            button.contentTintColor = nil
        }
    }

    /// Re-reads Secure Event Input state once per second: refreshes the menu bar
    /// when it changes, and feeds the watchdog every tick so it can measure how
    /// long the input has been stuck. A focused password field flips this on and
    /// the app can do nothing until focus leaves — see `secureInputPollTimer` —
    /// but an app that *leaks* it gets recovered by `SecureInputWatchdog`.
    private func handleSecureInputTick() {
        let active = IsSecureEventInputEnabled()
        if active != isSecureInputActive {
            isSecureInputActive = active
            updateSecureInputMenuItem()
            updateMenuBarIcon()
        }
        secureInputWatchdog.tick(seiActive: active, monitoringActive: keyboardMonitor != nil)
    }

    private func updateSecureInputMenuItem() {
        secureInputItem.isHidden = !(isSecureInputActive && keyboardMonitor != nil)
    }

    private func startMonitoringWhenPermitted() {
        if AccessibilityManager.shared.isAccessibilityEnabled {
            startMonitoring()
            return
        }
        permissionPollTimer?.invalidate()
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if AccessibilityManager.shared.isAccessibilityEnabled {
                timer.invalidate()
                self.permissionPollTimer = nil
                self.startMonitoring()
            }
        }
    }

    private func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "computermouse",
                accessibilityDescription: "Best Mouse Keys"
            )
        }

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(title: "Best Mouse Keys v0.1.0", action: nil, keyEquivalent: "")
        )
        menu.addItem(NSMenuItem.separator())

        secureInputItem = NSMenuItem(
            title: "Paused — a password field is focused", action: nil, keyEquivalent: ""
        )
        secureInputItem.isEnabled = false
        secureInputItem.isHidden = true
        menu.addItem(secureInputItem)

        let enabledItem = NSMenuItem(
            title: "Enabled", action: #selector(toggleEnabled(_:)), keyEquivalent: "e"
        )
        enabledItem.state = .on
        menu.addItem(enabledItem)

        let autoRecoverItem = NSMenuItem(
            title: "Auto-recover stuck Secure Input",
            action: #selector(toggleAutoRecover(_:)),
            keyEquivalent: ""
        )
        autoRecoverItem.state = secureInputWatchdog.isEnabled ? .on : .off
        menu.addItem(autoRecoverItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        )

        statusItem.menu = menu
    }

    @objc private func toggleAutoRecover(_ sender: NSMenuItem) {
        secureInputWatchdog.isEnabled.toggle()
        sender.state = secureInputWatchdog.isEnabled ? .on : .off
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        if sender.state == .on {
            sender.state = .off
            stopMonitoring()
        } else {
            sender.state = .on
            startMonitoring()
        }
    }

    private func startMonitoring() {
        guard keyboardMonitor == nil else { return }
        keyboardMonitor = KeyboardMonitor()
        keyboardMonitor?.start()
        updateSecureInputMenuItem()
        updateMenuBarIcon()
    }

    private func stopMonitoring() {
        keyboardMonitor?.stop()
        keyboardMonitor = nil
        updateSecureInputMenuItem()
        updateMenuBarIcon()
    }
}
