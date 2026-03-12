@testable import NotEnoughResins
import Testing

@MainActor
struct PreferencesStoreTests {
    @Test
    func loadsSavedCookieFromKeychain() {
        let keychain = InMemoryKeychainStore(
            initialValues: [PreferencesStore.cookieStorageAccount: "account_id_v2=123; cookie_token_v2=abc"]
        )

        let store = PreferencesStore(keychain: keychain)

        #expect(store.configurationState == .configurationReady)
        #expect(store.cookie == "account_id_v2=123; cookie_token_v2=abc")
        #expect(store.lastErrorMessage == nil)
    }

    @Test
    func rejectsEmptyCookie() {
        let keychain = InMemoryKeychainStore()
        let store = PreferencesStore(keychain: keychain)

        do {
            try store.saveCookie("   ")
            Issue.record("Expected an empty cookie save to fail.")
        } catch let error as PreferencesStore.SaveError {
            #expect(error == .emptyCookie)
        } catch {
            Issue.record("Unexpected error: \\(error)")
        }

        #expect(store.configurationState == .needsConfiguration)
        #expect(keychain.values.isEmpty)
    }

    @Test
    func savesCookieToKeychainAndMarksConfigurationReady() throws {
        let keychain = InMemoryKeychainStore()
        let store = PreferencesStore(keychain: keychain)

        try store.saveCookie(" account_id_v2=123; cookie_token_v2=abc ")

        #expect(store.configurationState == .configurationReady)
        #expect(store.cookie == "account_id_v2=123; cookie_token_v2=abc")
        #expect(
            keychain.values[PreferencesStore.cookieStorageAccount]
                == "account_id_v2=123; cookie_token_v2=abc"
        )
        #expect(store.lastErrorMessage == nil)
    }

    @Test
    func loadFailureFallsBackToNeedsConfiguration() {
        let keychain = InMemoryKeychainStore(readError: InMemoryKeychainStore.MockError.failedRead)

        let store = PreferencesStore(keychain: keychain)

        #expect(store.configurationState == .needsConfiguration)
        #expect(store.cookie == nil)
        #expect(store.lastErrorMessage == "The saved HoYoLAB cookie could not be loaded.")
    }
}

private final class InMemoryKeychainStore: KeychainStoring {
    enum MockError: Error {
        case failedRead
        case failedWrite
    }

    var values: [String: String]
    var readError: Error?
    var writeError: Error?

    init(
        initialValues: [String: String] = [:],
        readError: Error? = nil,
        writeError: Error? = nil
    ) {
        values = initialValues
        self.readError = readError
        self.writeError = writeError
    }

    func readString(for account: String) throws -> String? {
        if let readError {
            throw readError
        }

        return values[account]
    }

    func upsertString(_ value: String, for account: String) throws {
        if let writeError {
            throw writeError
        }

        values[account] = value
    }
}
