//
//  ContentView.swift
//  NotEnoughResins
//
//  Created by ph0ryn on 2026/03/12.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let derivedResinState = appState.derivedResinState()

        VStack(alignment: .leading, spacing: 16) {
            Text("NotEnoughResins")
                .font(.title2.weight(.semibold))

            Label(statusTitle, systemImage: statusIcon)
                .font(.headline)
                .accessibilityIdentifier("content.configurationStatus")

            Text(statusMessage)
                .foregroundStyle(.secondary)

            if let snapshot = appState.latestSnapshot,
               let derivedResinState {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Resin: \(derivedResinState.currentResin) / \(derivedResinState.maxResin)")

                    if let wastedResin = derivedResinState.wastedResin {
                        Text("Estimated Waste: \(wastedResin)")
                    }

                    Text("Last Update: \(snapshot.fetchedAt.formatted(date: .abbreviated, time: .shortened))")
                }
                .font(.callout)
            }

            SettingsLink {
                Label("Open Preferences", systemImage: "gearshape")
            }
            .accessibilityIdentifier("content.openPreferences")
        }
        .frame(minWidth: 360, minHeight: 220, alignment: .topLeading)
        .padding(24)
    }

    private var statusTitle: String {
        switch appState.configurationState {
        case .needsConfiguration:
            "Configuration Needed"
        case .configurationReady:
            switch appState.refreshPhase {
            case .idle, .needsConfiguration:
                "Configuration Ready"
            case .discoveringAccount:
                "Resolving Account"
            case .refreshingDailyNote:
                appState.latestSnapshot == nil ? "Loading Daily Note" : "Refreshing Daily Note"
            case .ready:
                "Daily Note Ready"
            case .authError:
                "Authentication Failed"
            case .requestError:
                "Request Failed"
            }
        }
    }

    private var statusIcon: String {
        switch appState.configurationState {
        case .needsConfiguration:
            "exclamationmark.triangle"
        case .configurationReady:
            switch appState.refreshPhase {
            case .idle, .needsConfiguration:
                "checkmark.seal"
            case .discoveringAccount, .refreshingDailyNote:
                "arrow.triangle.2.circlepath"
            case .ready:
                "bolt.circle"
            case .authError:
                "person.crop.circle.badge.exclamationmark"
            case .requestError:
                "wifi.exclamationmark"
            }
        }
    }

    private var statusMessage: String {
        switch appState.configurationState {
        case .needsConfiguration:
            "Save a HoYoLAB cookie in Preferences before account discovery can start."
        case .configurationReady:
            switch appState.refreshPhase {
            case .idle, .needsConfiguration:
                "A HoYoLAB cookie is stored in Keychain and ready for the next setup step."
            case .discoveringAccount:
                "Resolving the configured Genshin account before Daily Note polling starts."
            case .refreshingDailyNote:
                "Refreshing the latest Daily Note snapshot."
            case .ready:
                if let account = appState.resolvedAccount {
                    "Resolved \(account.server) / role \(account.roleId)."
                } else {
                    "The latest Daily Note snapshot is ready."
                }
            case .authError(let message):
                message
            case .requestError(let message):
                message
            }
        }
    }
}
