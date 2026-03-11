//
//  ContentView.swift
//  NotEnoughResins
//
//  Created by ph0ryn on 2026/03/12.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var preferencesStore: PreferencesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NotEnoughResins")
                .font(.title2.weight(.semibold))

            Label(statusTitle, systemImage: statusIcon)
                .font(.headline)
                .accessibilityIdentifier("content.configurationStatus")

            Text(statusMessage)
                .foregroundStyle(.secondary)

            SettingsLink {
                Label("Open Preferences", systemImage: "gearshape")
            }
            .accessibilityIdentifier("content.openPreferences")
        }
        .frame(minWidth: 360, minHeight: 220, alignment: .topLeading)
        .padding(24)
    }

    private var statusTitle: String {
        switch preferencesStore.configurationState {
        case .needsConfiguration:
            "Configuration Needed"
        case .configurationReady:
            "Configuration Ready"
        }
    }

    private var statusIcon: String {
        switch preferencesStore.configurationState {
        case .needsConfiguration:
            "exclamationmark.triangle"
        case .configurationReady:
            "checkmark.seal"
        }
    }

    private var statusMessage: String {
        switch preferencesStore.configurationState {
        case .needsConfiguration:
            "Save a HoYoLAB cookie in Preferences before account discovery can start."
        case .configurationReady:
            "A HoYoLAB cookie is stored in Keychain and ready for the next setup step."
        }
    }
}
