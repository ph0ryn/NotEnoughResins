import Foundation

#if DEBUG
    struct UITestScenario {
        let configurationState: PreferencesStore.ConfigurationState
        let refreshPhase: RefreshCoordinator.Phase
        let resolvedAccount: ResolvedAccount?
        let latestSnapshot: DailyNoteSnapshot?
        let derivedResinState: DerivedResinState?
        let lastSuccessfulFetchAt: Date?
        let trackingState: ResinTrackingState

        static var current: UITestScenario? {
            guard let rawValue = ProcessInfo.processInfo.environment["NOT_ENOUGH_RESINS_UI_TEST_SCENARIO"] else {
                return nil
            }

            return scenario(named: rawValue)
        }

        private static func scenario(named rawValue: String) -> UITestScenario? {
            let fetchedAt = Date(timeIntervalSince1970: 1_741_800_000)
            let resolvedAccount = ResolvedAccount(
                accountIdV2: "12345",
                server: "os_asia",
                roleId: "987654321",
                nickname: "Traveler",
                level: 60
            )

            switch rawValue {
            case "needsConfiguration":
                return UITestScenario(
                    configurationState: .needsConfiguration,
                    refreshPhase: .needsConfiguration,
                    resolvedAccount: nil,
                    latestSnapshot: nil,
                    derivedResinState: nil,
                    lastSuccessfulFetchAt: nil,
                    trackingState: .empty
                )

            case "normal":
                let snapshot = makeSnapshot(
                    fetchedAt: fetchedAt,
                    currentResin: 160,
                    resinRecoveryTimeSeconds: 19_200
                )

                return UITestScenario(
                    configurationState: .configurationReady,
                    refreshPhase: .ready,
                    resolvedAccount: resolvedAccount,
                    latestSnapshot: snapshot,
                    derivedResinState: DerivedResinState(
                        currentResin: 160,
                        maxResin: 200,
                        wastedResin: nil
                    ),
                    lastSuccessfulFetchAt: fetchedAt,
                    trackingState: ResinTrackingState(
                        lastBelowCapSnapshotAt: fetchedAt,
                        predictedFullAt: fetchedAt.addingTimeInterval(19_200),
                        overflowStartAt: nil,
                        lastKnownWastedResin: nil
                    )
                )

            case "overflow":
                let snapshot = makeSnapshot(
                    fetchedAt: fetchedAt,
                    currentResin: 200,
                    resinRecoveryTimeSeconds: 0
                )

                return UITestScenario(
                    configurationState: .configurationReady,
                    refreshPhase: .ready,
                    resolvedAccount: resolvedAccount,
                    latestSnapshot: snapshot,
                    derivedResinState: DerivedResinState(
                        currentResin: 200,
                        maxResin: 200,
                        wastedResin: 7
                    ),
                    lastSuccessfulFetchAt: fetchedAt,
                    trackingState: ResinTrackingState(
                        lastBelowCapSnapshotAt: fetchedAt.addingTimeInterval(-3_840),
                        predictedFullAt: fetchedAt.addingTimeInterval(-3_360),
                        overflowStartAt: fetchedAt.addingTimeInterval(-3_360),
                        lastKnownWastedResin: 7
                    )
                )

            case "authError":
                let snapshot = makeSnapshot(
                    fetchedAt: fetchedAt,
                    currentResin: 180,
                    resinRecoveryTimeSeconds: 9_600
                )

                return UITestScenario(
                    configurationState: .configurationReady,
                    refreshPhase: .authError(
                        "HoYoLAB rejected the saved cookie. Please sign in again."
                    ),
                    resolvedAccount: resolvedAccount,
                    latestSnapshot: snapshot,
                    derivedResinState: DerivedResinState(
                        currentResin: 181,
                        maxResin: 200,
                        wastedResin: nil
                    ),
                    lastSuccessfulFetchAt: fetchedAt,
                    trackingState: ResinTrackingState(
                        lastBelowCapSnapshotAt: fetchedAt,
                        predictedFullAt: fetchedAt.addingTimeInterval(9_600),
                        overflowStartAt: nil,
                        lastKnownWastedResin: nil
                    )
                )

            case "requestError":
                let snapshot = makeSnapshot(
                    fetchedAt: fetchedAt,
                    currentResin: 175,
                    resinRecoveryTimeSeconds: 12_000
                )

                return UITestScenario(
                    configurationState: .configurationReady,
                    refreshPhase: .requestError(
                        "The latest Daily Note request failed. Try again after checking the connection."
                    ),
                    resolvedAccount: resolvedAccount,
                    latestSnapshot: snapshot,
                    derivedResinState: DerivedResinState(
                        currentResin: 176,
                        maxResin: 200,
                        wastedResin: nil
                    ),
                    lastSuccessfulFetchAt: fetchedAt,
                    trackingState: ResinTrackingState(
                        lastBelowCapSnapshotAt: fetchedAt,
                        predictedFullAt: fetchedAt.addingTimeInterval(12_000),
                        overflowStartAt: nil,
                        lastKnownWastedResin: nil
                    )
                )

            default:
                return nil
            }
        }

        private static func makeSnapshot(
            fetchedAt: Date,
            currentResin: Int,
            resinRecoveryTimeSeconds: Int
        ) -> DailyNoteSnapshot {
            let expeditions = makeExpeditions()

            return DailyNoteSnapshot(
                fetchedAt: fetchedAt,
                currentResin: currentResin,
                maxResin: 200,
                resinRecoveryTimeSeconds: resinRecoveryTimeSeconds,
                currentHomeCoin: 1_200,
                maxHomeCoin: 2_400,
                homeCoinRecoveryTimeSeconds: 3_600,
                finishedTaskCount: 4,
                totalTaskCount: 4,
                extraTaskRewardReceived: true,
                remainingResinDiscounts: 3,
                resinDiscountLimit: 3,
                currentExpeditionCount: expeditions.count,
                maxExpeditionCount: 5,
                expeditions: expeditions
            )
        }

        private static func makeExpeditions() -> [DailyNoteExpedition] {
            [
                DailyNoteExpedition(
                    avatarSideIcon: "https://example.com/Character_A.png",
                    status: "Ongoing",
                    remainedTimeSeconds: 1_080
                ),
                DailyNoteExpedition(
                    avatarSideIcon: "https://example.com/Character_B.png",
                    status: "Ongoing",
                    remainedTimeSeconds: 6_120
                ),
                DailyNoteExpedition(
                    avatarSideIcon: "https://example.com/Character_C.png",
                    status: "Finished",
                    remainedTimeSeconds: 0
                ),
            ]
        }
    }
#endif
