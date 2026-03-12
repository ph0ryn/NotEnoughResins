import Foundation
@testable import NotEnoughResins
import Testing

struct AppPresentationTests {
    private let builder = AppPresentationBuilder()

    @Test
    func needsConfigurationMapsToSetupMenuState() {
        let presentation = builder.makePresentation(
            configurationState: .needsConfiguration,
            refreshPhase: .needsConfiguration,
            resolvedAccount: nil,
            latestSnapshot: nil,
            derivedResinState: nil,
            lastSuccessfulFetchAt: nil
        )

        #expect(presentation.menuBarState == .needsConfiguration)
        #expect(presentation.title == "Configuration Needed")
        #expect(presentation.fields.isEmpty)
    }

    @Test
    func readyBelowCapMapsToNormalMenuState() {
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_741_800_000),
            currentResin: 160,
            resinRecoveryTimeSeconds: 19_200
        )

        let presentation = builder.makePresentation(
            configurationState: .configurationReady,
            refreshPhase: .ready,
            resolvedAccount: ResolvedAccount(
                accountIdV2: "12345",
                server: "os_asia",
                roleId: "987654321",
                nickname: "Traveler",
                level: 60
            ),
            latestSnapshot: snapshot,
            derivedResinState: DerivedResinState(
                currentResin: 161,
                maxResin: 200,
                wastedResin: nil
            ),
            lastSuccessfulFetchAt: snapshot.fetchedAt
        )

        #expect(presentation.menuBarState == .normal(current: 161, max: 200))
        #expect(presentation.title == "Daily Note Ready")
        #expect(presentation.fields.contains(where: { $0.id == "resin" && $0.value == "161 / 200" }))
    }

    @Test
    func knownOverflowMapsToOverflowMenuState() {
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_741_800_000),
            currentResin: 200,
            resinRecoveryTimeSeconds: 0
        )

        let presentation = builder.makePresentation(
            configurationState: .configurationReady,
            refreshPhase: .ready,
            resolvedAccount: nil,
            latestSnapshot: snapshot,
            derivedResinState: DerivedResinState(
                currentResin: 200,
                maxResin: 200,
                wastedResin: 7
            ),
            lastSuccessfulFetchAt: snapshot.fetchedAt
        )

        #expect(presentation.menuBarState == .overflow(wasted: 7))
        #expect(presentation.title == "Overflow Detected")
        #expect(presentation.fields.contains(where: { $0.id == "waste" && $0.value == "7" }))
    }

    @Test
    func authErrorOverridesLastSuccessfulSnapshotState() {
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_741_800_000),
            currentResin: 180,
            resinRecoveryTimeSeconds: 9_600
        )

        let presentation = builder.makePresentation(
            configurationState: .configurationReady,
            refreshPhase: .authError("HoYoLAB rejected the saved cookie. Please sign in again."),
            resolvedAccount: nil,
            latestSnapshot: snapshot,
            derivedResinState: DerivedResinState(
                currentResin: 181,
                maxResin: 200,
                wastedResin: nil
            ),
            lastSuccessfulFetchAt: snapshot.fetchedAt
        )

        #expect(presentation.menuBarState == .authError)
        #expect(presentation.title == "Authentication Failed")
        #expect(presentation.fields.isEmpty == false)
    }

    @Test
    func requestErrorOverridesLastSuccessfulSnapshotState() {
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_741_800_000),
            currentResin: 175,
            resinRecoveryTimeSeconds: 12_000
        )

        let presentation = builder.makePresentation(
            configurationState: .configurationReady,
            refreshPhase: .requestError(
                "The latest Daily Note request failed. Try again after checking the connection."
            ),
            resolvedAccount: nil,
            latestSnapshot: snapshot,
            derivedResinState: DerivedResinState(
                currentResin: 176,
                maxResin: 200,
                wastedResin: nil
            ),
            lastSuccessfulFetchAt: snapshot.fetchedAt
        )

        #expect(presentation.menuBarState == .requestError)
        #expect(presentation.title == "Request Failed")
        #expect(presentation.fields.isEmpty == false)
    }
}
