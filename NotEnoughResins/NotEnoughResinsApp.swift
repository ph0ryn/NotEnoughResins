//
//  NotEnoughResinsApp.swift
//  NotEnoughResins
//
//  Created by ph0ryn on 2026/03/12.
//

import AppKit
import SwiftUI

@main
struct NotEnoughResinsApp: App {
    @StateObject private var preferencesStore: PreferencesStore
    @StateObject private var appState: AppState

    init() {
        let environment = ProcessInfo.processInfo.environment
        _ = NSApplication.shared.setActivationPolicy(
            AppActivationPolicyResolver.policy(for: environment)
        )

        let preferencesStore = PreferencesStore.live()
        #if DEBUG
            let uiTestScenario = UITestScenario.current
            let refreshEnabled = uiTestScenario == nil
                && environment["NOT_ENOUGH_RESINS_DISABLE_REFRESH"] != "1"
        #else
            let refreshEnabled = environment["NOT_ENOUGH_RESINS_DISABLE_REFRESH"] != "1"
        #endif
        let appState = AppState(
            preferencesStore: preferencesStore,
            refreshCoordinator: RefreshCoordinator.live(),
            refreshEnabled: refreshEnabled
        )
        #if DEBUG
            if let uiTestScenario {
                appState.applyDebugState(
                    configurationState: uiTestScenario.configurationState,
                    refreshPhase: uiTestScenario.refreshPhase,
                    resolvedAccount: uiTestScenario.resolvedAccount,
                    latestSnapshot: uiTestScenario.latestSnapshot,
                    derivedResinState: uiTestScenario.derivedResinState,
                    lastSuccessfulFetchAt: uiTestScenario.lastSuccessfulFetchAt,
                    trackingState: uiTestScenario.trackingState
                )
            }
        #endif
        _preferencesStore = StateObject(wrappedValue: preferencesStore)
        _appState = StateObject(wrappedValue: appState)

        Task { @MainActor in
            UITestWindowController.openIfNeeded(appState: appState)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(appState)
        } label: {
            MenuBarStatusLabel(menuBarState: appState.presentation.menuBarState)
        }
        .menuBarExtraStyle(.window)
        .windowResizability(.contentSize)

        Settings {
            PreferencesView(store: preferencesStore)
        }
    }
}
