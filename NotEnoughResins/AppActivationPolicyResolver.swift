import AppKit

enum AppActivationPolicyResolver {
    static func policy(for environment: [String: String]) -> NSApplication.ActivationPolicy {
        if environment["NOT_ENOUGH_RESINS_SHOW_DOCK_ICON"] == "1"
            || environment["NOT_ENOUGH_RESINS_UI_TEST_WINDOW"] == "1"
        {
            return .regular
        }

        return .accessory
    }
}
