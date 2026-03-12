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

    struct PanelField: Equatable, Identifiable {
        let id: String
        let label: String
        let value: String
    }

    let menuBarState: MenuBarState
    let title: String
    let message: String
    let symbolName: String
    let lastRefreshText: String?
    let fields: [PanelField]
}

struct AppPresentationBuilder {
    nonisolated init() {}

    nonisolated
    func makePresentation(
        configurationState: PreferencesStore.ConfigurationState,
        refreshPhase: RefreshCoordinator.Phase,
        resolvedAccount: ResolvedAccount?,
        latestSnapshot: DailyNoteSnapshot?,
        derivedResinState: DerivedResinState?,
        lastSuccessfulFetchAt: Date?
    ) -> AppPresentation {
        let fields = makeFields(
            resolvedAccount: resolvedAccount,
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
                fields: fields
            )

        case .configurationReady:
            switch refreshPhase {
            case .idle:
                if let derivedResinState {
                    let menuBarState = makeReadyMenuBarState(from: derivedResinState)

                    return AppPresentation(
                        menuBarState: menuBarState,
                        title: "Configuration Ready",
                        message: "A HoYoLAB cookie is stored and the latest cached Daily Note snapshot is ready.",
                        symbolName: symbolName(for: menuBarState),
                        lastRefreshText: lastRefreshText,
                        fields: fields
                    )
                }

                return AppPresentation(
                    menuBarState: .loading,
                    title: "Configuration Ready",
                    message: "A HoYoLAB cookie is stored and ready for the first refresh.",
                    symbolName: "gearshape.2.fill",
                    lastRefreshText: lastRefreshText,
                    fields: fields
                )

            case .needsConfiguration, .discoveringAccount:
                return AppPresentation(
                    menuBarState: .loading,
                    title: "Resolving Account",
                    message: "Resolving the configured Genshin account before Daily Note polling starts.",
                    symbolName: "person.crop.circle.badge.clock",
                    lastRefreshText: lastRefreshText,
                    fields: fields
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
                    fields: fields
                )

            case .ready:
                guard let derivedResinState else {
                    return AppPresentation(
                        menuBarState: .loading,
                        title: "Loading Daily Note",
                        message: "Waiting for the first Daily Note snapshot.",
                        symbolName: "arrow.triangle.2.circlepath.circle.fill",
                        lastRefreshText: lastRefreshText,
                        fields: fields
                    )
                }

                let menuBarState = makeReadyMenuBarState(from: derivedResinState)

                return AppPresentation(
                    menuBarState: menuBarState,
                    title: title(for: menuBarState),
                    message: readyMessage(
                        resolvedAccount: resolvedAccount,
                        derivedResinState: derivedResinState
                    ),
                    symbolName: symbolName(for: menuBarState),
                    lastRefreshText: lastRefreshText,
                    fields: fields
                )

            case .authError(let message):
                return AppPresentation(
                    menuBarState: .authError,
                    title: "Authentication Failed",
                    message: message,
                    symbolName: "person.crop.circle.badge.exclamationmark.fill",
                    lastRefreshText: lastRefreshText,
                    fields: fields
                )

            case .requestError(let message):
                return AppPresentation(
                    menuBarState: .requestError,
                    title: "Request Failed",
                    message: message,
                    symbolName: "wifi.exclamationmark",
                    lastRefreshText: lastRefreshText,
                    fields: fields
                )
            }
        }
    }

    nonisolated
    private func makeReadyMenuBarState(from derivedResinState: DerivedResinState) -> AppPresentation.MenuBarState {
        if let wastedResin = derivedResinState.wastedResin {
            return .overflow(wasted: wastedResin)
        }

        return .normal(
            current: derivedResinState.currentResin,
            max: derivedResinState.maxResin
        )
    }

    nonisolated
    private func title(for menuBarState: AppPresentation.MenuBarState) -> String {
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

    nonisolated
    private func symbolName(for menuBarState: AppPresentation.MenuBarState) -> String {
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

    nonisolated
    private func readyMessage(
        resolvedAccount: ResolvedAccount?,
        derivedResinState: DerivedResinState
    ) -> String {
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

        if let wastedResin = derivedResinState.wastedResin {
            return "Natural recovery has overflowed for \(accountSummary). Estimated wasted resin: \(wastedResin)."
        }

        return "Showing the latest resin summary for \(accountSummary)."
    }

    nonisolated
    private func makeFields(
        resolvedAccount: ResolvedAccount?,
        latestSnapshot: DailyNoteSnapshot?,
        derivedResinState: DerivedResinState?
    ) -> [AppPresentation.PanelField] {
        guard let latestSnapshot,
              let derivedResinState else {
            return []
        }

        var fields: [AppPresentation.PanelField] = []

        if let resolvedAccount {
            let accountValue: String

            if let nickname = resolvedAccount.nickname, nickname.isEmpty == false {
                accountValue = "\(nickname) · Lv. \(resolvedAccount.level ?? 0)"
            } else {
                accountValue = "\(resolvedAccount.server) · \(resolvedAccount.roleId)"
            }

            fields.append(
                AppPresentation.PanelField(
                    id: "account",
                    label: "Account",
                    value: accountValue
                )
            )
        }

        fields.append(
            AppPresentation.PanelField(
                id: "resin",
                label: "Resin",
                value: "\(derivedResinState.currentResin) / \(derivedResinState.maxResin)"
            )
        )

        if let wastedResin = derivedResinState.wastedResin {
            fields.append(
                AppPresentation.PanelField(
                    id: "waste",
                    label: "Estimated Waste",
                    value: "\(wastedResin)"
                )
            )
        }

        fields.append(
            AppPresentation.PanelField(
                id: "homeCoin",
                label: "Home Coin",
                value: "\(latestSnapshot.currentHomeCoin) / \(latestSnapshot.maxHomeCoin)"
            )
        )
        fields.append(
            AppPresentation.PanelField(
                id: "commissions",
                label: "Daily Tasks",
                value: "\(latestSnapshot.finishedTaskCount) / \(latestSnapshot.totalTaskCount)"
            )
        )
        fields.append(
            AppPresentation.PanelField(
                id: "reward",
                label: "Bonus Reward",
                value: latestSnapshot.extraTaskRewardReceived ? "Claimed" : "Pending"
            )
        )
        fields.append(
            AppPresentation.PanelField(
                id: "discounts",
                label: "Discount Runs",
                value: "\(latestSnapshot.remainingResinDiscounts) / \(latestSnapshot.resinDiscountLimit)"
            )
        )
        fields.append(
            AppPresentation.PanelField(
                id: "expeditions",
                label: "Expeditions",
                value: "\(latestSnapshot.currentExpeditionCount) / \(latestSnapshot.maxExpeditionCount)"
            )
        )

        return fields
    }
}
