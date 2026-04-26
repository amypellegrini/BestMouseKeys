import SwiftUI

struct ContentView: View {
    @State private var accessibilityGranted = AccessibilityManager.shared.isAccessibilityEnabled

    var body: some View {
        VStack(spacing: 16) {
            Text("Best Mouse Keys")
                .font(.title)

            if accessibilityGranted {
                Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Accessibility access required", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Button("Open System Settings") {
                    AccessibilityManager.shared.requestAccessIfNeeded()
                }
            }

            Divider()

            Text("Numpad Controls")
                .font(.headline)

            Grid(alignment: .center, horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    KeyLabel("7", subtitle: "up-left")
                    KeyLabel("8", subtitle: "up")
                    KeyLabel("9", subtitle: "up-right")
                }
                GridRow {
                    KeyLabel("4", subtitle: "left")
                    KeyLabel("5", subtitle: "click")
                    KeyLabel("6", subtitle: "right")
                }
                GridRow {
                    KeyLabel("1", subtitle: "down-left")
                    KeyLabel("2", subtitle: "down")
                    KeyLabel("3", subtitle: "down-right")
                }
            }
        }
        .padding(24)
        .frame(width: 300)
    }
}

private struct KeyLabel: View {
    let key: String
    let subtitle: String

    init(_ key: String, subtitle: String) {
        self.key = key
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(key)
                .font(.system(.title2, design: .monospaced, weight: .bold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 72, height: 56)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
