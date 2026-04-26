import SwiftUI

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
    private var keyboardMonitor: KeyboardMonitor?
    private var permissionPollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarItem()
        AccessibilityManager.shared.requestAccessIfNeeded()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dragStateChanged),
            name: .mouseDragStateChanged,
            object: nil
        )

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
        button.contentTintColor = MouseController.isDragging ? .systemRed : nil
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

        let enabledItem = NSMenuItem(
            title: "Enabled", action: #selector(toggleEnabled(_:)), keyEquivalent: "e"
        )
        enabledItem.state = .on
        menu.addItem(enabledItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        )

        statusItem.menu = menu
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
    }

    private func stopMonitoring() {
        keyboardMonitor?.stop()
        keyboardMonitor = nil
    }
}
