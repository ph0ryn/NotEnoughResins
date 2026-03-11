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

    init() {
        _preferencesStore = StateObject(wrappedValue: PreferencesStore.live())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferencesStore)
        }

        Settings {
            PreferencesView(store: preferencesStore)
        }
    }
}
