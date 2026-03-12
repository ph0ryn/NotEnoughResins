import AppKit
import SwiftUI

@MainActor
enum UITestWindowController {
    private static var window: NSWindow?

    static func openIfNeeded(appState: AppState) {
        guard ProcessInfo.processInfo.environment["NOT_ENOUGH_RESINS_UI_TEST_WINDOW"] == "1",
              window == nil
        else {
            return
        }

        let hostingController = NSHostingController(
            rootView: UITestWindowRootView()
                .environmentObject(appState)
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = "NotEnoughResins Debug"
        window.setContentSize(NSSize(width: 420, height: 520))
        window.styleMask.insert(.resizable)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)

        self.window = window
    }
}

private struct UITestWindowRootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MenuBarStatusLabel(menuBarState: appState.presentation.menuBarState)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.quaternary.opacity(0.4))
                )

            Divider()

            ContentView()
        }
        .padding(16)
    }
}
