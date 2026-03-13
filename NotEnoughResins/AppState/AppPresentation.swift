import Foundation

struct AppPresentation: Equatable {
    enum MenuBarState: Equatable {
        case needsConfiguration
        case loading
        case normal(current: Int, max: Int)
        case overflow(wasted: Int)
        case authError
        case requestError
    }

    struct HeroAccessory: Equatable {
        let label: String
        let value: String
    }

    struct Hero: Equatable {
        let title: String
        let value: String
        let accessory: HeroAccessory?
    }

    struct SummaryMetric: Equatable, Identifiable {
        let id: String
        let label: String
        let value: String
    }

    struct ExpeditionRow: Equatable, Identifiable {
        let id: String
        let avatarURL: URL?
        let characterLabel: String
        let value: String
        let isComplete: Bool
    }

    struct ExpeditionSection: Equatable {
        let currentCount: Int
        let maxCount: Int
        let rows: [ExpeditionRow]
    }

    struct Panel: Equatable {
        let hero: Hero
        let summaryMetrics: [SummaryMetric]
        let expeditionSection: ExpeditionSection?
    }

    let menuBarState: MenuBarState
    let title: String
    let message: String
    let symbolName: String
    let lastRefreshText: String?
    let panel: Panel?
}

struct AppPresentationBuilder {
    nonisolated func makePresentation(
        configurationState: PreferencesStore.ConfigurationState,
        refreshPhase: RefreshCoordinator.Phase,
        resolvedAccount: ResolvedAccount?,
        latestSnapshot: DailyNoteSnapshot?,
        derivedResinState: DerivedResinState?,
        lastSuccessfulFetchAt: Date?
    ) -> AppPresentation {
        let panel = makePanel(
            latestSnapshot: latestSnapshot,
            derivedResinState: derivedResinState
        )

        let lastRefreshText = lastSuccessfulFetchAt?.formatted(
            date: .abbreviated,
            time: .shortened
        )

        switch configurationState {
        case .needsConfiguration:
            return AppPresentation(
                menuBarState: .needsConfiguration,
                title: "Configuration Needed",
                message: "Save a HoYoLAB cookie in Preferences before account discovery can start.",
                symbolName: "exclamationmark.triangle.fill",
                lastRefreshText: lastRefreshText,
                panel: panel
            )

        case .configurationReady:
            switch refreshPhase {
            case .idle:
                if let derivedResinState {
                    let menuBarState = makeReadyMenuBarState(from: derivedResinState)

                    return AppPresentation(
                        menuBarState: menuBarState,
                        title: "Configuration Ready",
                        message: "A HoYoLAB cookie is stored and the latest Daily Note snapshot is ready.",
                        symbolName: symbolName(for: menuBarState),
                        lastRefreshText: lastRefreshText,
                        panel: panel
                    )
                }

                return AppPresentation(
                    menuBarState: .loading,
                    title: "Configuration Ready",
                    message: "A HoYoLAB cookie is stored and ready for the first refresh.",
                    symbolName: "gearshape.2.fill",
                    lastRefreshText: lastRefreshText,
                    panel: panel
                )

            case .needsConfiguration, .discoveringAccount:
                return AppPresentation(
                    menuBarState: .loading,
                    title: "Resolving Account",
                    message: "Resolving the configured Genshin account before Daily Note polling starts.",
                    symbolName: "person.crop.circle.badge.clock",
                    lastRefreshText: lastRefreshText,
                    panel: panel
                )

            case .refreshingDailyNote:
                return AppPresentation(
                    menuBarState: .loading,
                    title: latestSnapshot == nil ? "Loading Daily Note" : "Refreshing Daily Note",
                    message: latestSnapshot == nil
                        ? "Fetching the first Daily Note snapshot."
                        : "Refreshing the latest Daily Note snapshot while keeping the last known data visible.",
                    symbolName: "arrow.triangle.2.circlepath.circle.fill",
                    lastRefreshText: lastRefreshText,
                    panel: panel
                )

            case .ready:
                guard let derivedResinState else {
                    return AppPresentation(
                        menuBarState: .loading,
                        title: "Loading Daily Note",
                        message: "Waiting for the first Daily Note snapshot.",
                        symbolName: "arrow.triangle.2.circlepath.circle.fill",
                        lastRefreshText: lastRefreshText,
                        panel: panel
                    )
                }

                let menuBarState = makeReadyMenuBarState(from: derivedResinState)

                return AppPresentation(
                    menuBarState: menuBarState,
                    title: title(for: menuBarState),
                    message: readyMessage(resolvedAccount: resolvedAccount),
                    symbolName: symbolName(for: menuBarState),
                    lastRefreshText: lastRefreshText,
                    panel: panel
                )

            case let .authError(message):
                return AppPresentation(
                    menuBarState: .authError,
                    title: "Authentication Failed",
                    message: message,
                    symbolName: "person.crop.circle.badge.exclamationmark.fill",
                    lastRefreshText: lastRefreshText,
                    panel: panel
                )

            case let .requestError(message):
                return AppPresentation(
                    menuBarState: .requestError,
                    title: "Request Failed",
                    message: message,
                    symbolName: "wifi.exclamationmark",
                    lastRefreshText: lastRefreshText,
                    panel: panel
                )
            }
        }
    }

    private nonisolated func makePanel(
        latestSnapshot: DailyNoteSnapshot?,
        derivedResinState: DerivedResinState?
    ) -> AppPresentation.Panel? {
        guard let latestSnapshot,
              let derivedResinState
        else {
            return nil
        }

        let hero = AppPresentation.Hero(
            title: "Resin",
            value: "\(derivedResinState.currentResin) / \(derivedResinState.maxResin)",
            accessory: derivedResinState.wastedResin.map {
                AppPresentation.HeroAccessory(label: "Estimated Waste", value: "\($0)")
            }
        )

        let summaryMetrics: [AppPresentation.SummaryMetric] = [
            .init(
                id: "discounts",
                label: "Discount Runs",
                value: "\(latestSnapshot.remainingResinDiscounts) / \(latestSnapshot.resinDiscountLimit)"
            ),
            .init(
                id: "tasks",
                label: "Daily Tasks",
                value: "\(latestSnapshot.finishedTaskCount) / \(latestSnapshot.totalTaskCount)"
            ),
            .init(
                id: "reward",
                label: "Bonus Reward",
                value: latestSnapshot.extraTaskRewardReceived ? "Claimed" : "Pending"
            ),
            .init(
                id: "homeCoin",
                label: "Home Coin",
                value: "\(latestSnapshot.currentHomeCoin) / \(latestSnapshot.maxHomeCoin)"
            ),
        ]

        let expeditionRows = latestSnapshot.expeditions.enumerated().map { index, expedition in
            AppPresentation.ExpeditionRow(
                id: "character-\(index + 1)",
                avatarURL: URL(string: expedition.avatarSideIcon),
                characterLabel: expeditionCharacterLabel(for: expedition, index: index),
                value: expeditionValue(for: expedition),
                isComplete: expedition.isComplete
            )
        }

        let expeditionSection: AppPresentation.ExpeditionSection? =
            expeditionRows.isEmpty
                ? nil
                : AppPresentation.ExpeditionSection(
                    currentCount: latestSnapshot.currentExpeditionCount,
                    maxCount: latestSnapshot.maxExpeditionCount,
                    rows: expeditionRows
                )

        return AppPresentation.Panel(
            hero: hero,
            summaryMetrics: summaryMetrics,
            expeditionSection: expeditionSection
        )
    }

    private nonisolated func makeReadyMenuBarState(from derivedResinState: DerivedResinState) -> AppPresentation.MenuBarState {
        if let wastedResin = derivedResinState.wastedResin {
            return .overflow(wasted: wastedResin)
        }

        return .normal(
            current: derivedResinState.currentResin,
            max: derivedResinState.maxResin
        )
    }

    private nonisolated func title(for menuBarState: AppPresentation.MenuBarState) -> String {
        switch menuBarState {
        case .needsConfiguration:
            "Configuration Needed"
        case .loading:
            "Loading Daily Note"
        case .normal:
            "Daily Note Ready"
        case .overflow:
            "Overflow Detected"
        case .authError:
            "Authentication Failed"
        case .requestError:
            "Request Failed"
        }
    }

    private nonisolated func symbolName(for menuBarState: AppPresentation.MenuBarState) -> String {
        switch menuBarState {
        case .needsConfiguration:
            "exclamationmark.triangle.fill"
        case .loading:
            "arrow.triangle.2.circlepath.circle.fill"
        case .normal:
            "drop.fill"
        case .overflow:
            "trash.fill"
        case .authError:
            "person.crop.circle.badge.exclamationmark.fill"
        case .requestError:
            "wifi.exclamationmark"
        }
    }

    private nonisolated func readyMessage(resolvedAccount: ResolvedAccount?) -> String {
        let accountSummary: String

        if let resolvedAccount {
            if let nickname = resolvedAccount.nickname, nickname.isEmpty == false {
                accountSummary = "\(nickname) on \(resolvedAccount.server)"
            } else {
                accountSummary = "\(resolvedAccount.server) / role \(resolvedAccount.roleId)"
            }
        } else {
            accountSummary = "the saved account"
        }

        return "Current account: \(accountSummary)"
    }

    private nonisolated func expeditionCharacterLabel(
        for expedition: DailyNoteExpedition,
        index: Int
    ) -> String {
        guard let url = URL(string: expedition.avatarSideIcon) else {
            return "Character \(index + 1)"
        }

        let identifier = url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard identifier.isEmpty == false,
              identifier.rangeOfCharacter(from: .letters) != nil
        else {
            return "Character \(index + 1)"
        }

        return identifier
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private nonisolated func expeditionValue(for expedition: DailyNoteExpedition) -> String {
        if expedition.isComplete {
            return "Completed"
        }

        let totalMinutes = Int(ceil(Double(expedition.remainedTimeSeconds) / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%02d:%02d remaining", hours, minutes)
    }
}
