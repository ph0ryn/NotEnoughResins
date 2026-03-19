//
//  ContentView.swift
//  NotEnoughResins
//
//  Created by ph0ryn on 2026/03/12.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        let presentation = appState.presentation

        VStack(spacing: 0) {
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

                if let panel = presentation.panel {
                    panelView(panel)
                        .accessibilityIdentifier("content.panel")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 10)

            Divider()

            HStack(spacing: 12) {
                Button {
                    presentSettings()
                } label: {
                    Label("Preferences", systemImage: "gearshape")
                }
                .accessibilityLabel("Preferences")
                .accessibilityIdentifier("content.openPreferences")

                Spacer()

                Button {
                    appState.refreshNow()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Refresh")
                .accessibilityIdentifier("content.refresh")
                .help("Refresh")
                .disabled(appState.canRefreshNow == false)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
                .accessibilityLabel("Quit")
                .accessibilityIdentifier("content.quit")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(
            minWidth: 340,
            idealWidth: 360,
            maxWidth: 380,
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

    private func panelView(_ panel: AppPresentation.Panel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(panel.hero.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text(panel.hero.value)
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                    .accessibilityIdentifier("content.hero.value")

                if let detail = panel.hero.detail {
                    Text(detail)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("content.hero.detail")
                }

                if let accessory = panel.hero.accessory {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(accessory.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(accessory.value)
                            .font(.body.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.red)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(accessory.label): \(accessory.value)")
                    .accessibilityIdentifier("content.hero.waste")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("content.hero")

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(panel.summaryMetrics) { metric in
                    HStack(alignment: .firstTextBaseline) {
                        Text(metric.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("content.metric.\(metric.id)")
                        Spacer(minLength: 24)
                        Text(metric.value)
                            .font(.body.monospacedDigit())
                    }
                }
            }

            if let expeditionSection = panel.expeditionSection {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Expeditions \(expeditionSection.currentCount)/\(expeditionSection.maxCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("content.expeditions.heading")

                    ForEach(expeditionSection.rows) { expedition in
                        HStack(alignment: .center, spacing: 12) {
                            expeditionAvatarView(expedition)
                                .accessibilityIdentifier("content.expedition.\(expedition.id)")
                            Spacer(minLength: 24)
                            Text(expedition.value)
                                .font(.body.monospacedDigit())
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(expedition.isComplete ? .secondary : .primary)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(0.35))
        )
    }

    private func expeditionAvatarView(_ expedition: AppPresentation.ExpeditionRow) -> some View {
        Group {
            if let avatarURL = expedition.avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.tertiary.opacity(0.2))
                            ProgressView()
                                .controlSize(.small)
                        }
                    case .failure:
                        expeditionAvatarPlaceholder()
                    @unknown default:
                        expeditionAvatarPlaceholder()
                    }
                }
            } else {
                expeditionAvatarPlaceholder()
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
        .accessibilityLabel(expedition.characterLabel)
    }

    private func expeditionAvatarPlaceholder() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.tertiary.opacity(0.2))
            Image(systemName: "person.crop.square.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
