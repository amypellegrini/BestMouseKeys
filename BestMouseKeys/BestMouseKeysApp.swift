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

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarItem()

        if AccessibilityManager.shared.requestAccessIfNeeded() {
            startMonitoring()
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
