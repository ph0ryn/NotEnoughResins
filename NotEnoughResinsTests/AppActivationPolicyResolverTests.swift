import AppKit
@testable import NotEnoughResins
import Testing

struct AppActivationPolicyResolverTests {
    @Test
    func defaultsToAccessoryForMenuBarApp() {
        #expect(AppActivationPolicyResolver.policy(for: [:]) == .accessory)
    }

    @Test
    func showsDockIconWhenExplicitlyRequested() {
        #expect(
            AppActivationPolicyResolver.policy(
                for: ["NOT_ENOUGH_RESINS_SHOW_DOCK_ICON": "1"]
            ) == .regular
        )
    }

    @Test
    func showsDockIconForDebugUiTestWindow() {
        #expect(
            AppActivationPolicyResolver.policy(
                for: ["NOT_ENOUGH_RESINS_UI_TEST_WINDOW": "1"]
            ) == .regular
        )
    }
}
