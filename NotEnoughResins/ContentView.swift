//
//  ContentView.swift
//  NotEnoughResins
//
//  Created by ph0ryn on 2026/03/12.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        let presentation = appState.presentation

        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: presentation.symbolName)
                            .font(.system(size: 20, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(presentation.title)
                                .font(.title3.weight(.semibold))
                            Text(presentation.message)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("content.statusHeader")

                    if let lastRefreshText = presentation.lastRefreshText {
                        Label("Last Successful Refresh: \(lastRefreshText)", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Last Successful Refresh: \(lastRefreshText)")
                            .accessibilityIdentifier("content.lastRefresh")
                    }

                    if presentation.fields.isEmpty == false {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(presentation.fields) { field in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(field.label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Spacer(minLength: 24)
                                    Text(field.value)
                                        .font(.body.monospacedDigit())
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("\(field.label): \(field.value)")
                                .accessibilityIdentifier("content.field.\(field.id)")
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.quaternary.opacity(0.35))
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .scrollIndicators(.visible)

            Divider()

            HStack(spacing: 12) {
                Button {
                    presentSettings()
                } label: {
                    Label("Preferences", systemImage: "gearshape")
                }
                .accessibilityLabel("Preferences")
                .accessibilityIdentifier("content.openPreferences")
                .buttonStyle(.borderless)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
                .accessibilityLabel("Quit")
                .accessibilityIdentifier("content.quit")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(
            minWidth: 340,
            idealWidth: 360,
            maxWidth: 380,
            minHeight: 260,
            idealHeight: 340,
            maxHeight: 420,
            alignment: .topLeading
        )
    }

    private var accentColor: Color {
        switch appState.presentation.menuBarState {
        case .needsConfiguration:
            .orange
        case .loading:
            .blue
        case .normal:
            .teal
        case .overflow:
            .red
        case .authError, .requestError:
            .yellow
        }
    }

    private func presentSettings() {
        openSettings()
    }
}
