//
//  NotEnoughResinsApp.swift
//  NotEnoughResins
//
//  Created by ph0ryn on 2026/03/12.
//

import SwiftUI

@main
struct NotEnoughResinsApp: App {
    @StateObject private var preferencesStore: PreferencesStore
    @StateObject private var appState: AppState

    init() {
        let preferencesStore = PreferencesStore.live()
        _preferencesStore = StateObject(wrappedValue: preferencesStore)
        _appState = StateObject(
            wrappedValue: AppState(
                preferencesStore: preferencesStore,
                refreshCoordinator: RefreshCoordinator.live()
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }

        Settings {
            PreferencesView(store: preferencesStore)
        }
    }
}
