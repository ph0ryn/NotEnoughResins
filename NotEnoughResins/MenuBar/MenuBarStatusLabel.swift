import SwiftUI

struct MenuBarStatusLabel: View {
    let menuBarState: AppPresentation.MenuBarState

    let icon: NSImage = {
        let ratio = $0.size.height / $0.size.width
        $0.size.height = 22
        $0.size.width = 22 / ratio
        return $0
    }(NSImage(named: "MenuBarIcon")!)

    var body: some View {
        HStack(spacing: 6) {
            switch menuBarState {
            case .needsConfiguration:
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Set Up")
            case .loading:
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                Text("Loading")
            case let .normal(current, max):
                Text("\(current) / \(max)")
                Image(nsImage: icon)
            case let .overflow(wasted):
                Image(systemName: "trash.fill")
                Text("\(wasted)")
            case .authError:
                Image(systemName: "person.crop.circle.badge.exclamationmark.fill")
                Text("Auth")
            case .requestError:
                Image(systemName: "wifi.exclamationmark")
                Text("Stale")
            }
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("menuBar.statusLabel")
    }

    private var accessibilityLabel: String {
        switch menuBarState {
        case .needsConfiguration:
            "Set Up"
        case .loading:
            "Loading"
        case let .normal(current, max):
            "\(current) / \(max)"
        case let .overflow(wasted):
            "Waste \(wasted)"
        case .authError:
            "Auth"
        case .requestError:
            "Stale"
        }
    }
}
