import Combine
import Foundation

@MainActor
final class PreferencesStore: ObservableObject {
    enum ConfigurationState: Equatable {
        case needsConfiguration
        case configurationReady
    }

    enum SaveError: Error, Equatable, LocalizedError {
        case emptyCookie
        case persistenceFailed

        var errorDescription: String? {
            switch self {
            case .emptyCookie:
                "The HoYoLAB cookie cannot be empty."
            case .persistenceFailed:
                "The HoYoLAB cookie could not be saved to Keychain."
            }
        }
    }

    static let cookieStorageAccount = "hoyolab-cookie"

    @Published private(set) var storedCookie: String = ""
    @Published private(set) var configurationState: ConfigurationState = .needsConfiguration
    @Published private(set) var lastErrorMessage: String?

    private let keychain: KeychainStoring

    init(keychain: KeychainStoring) {
        self.keychain = keychain
        reloadFromStorage()
    }

    var cookie: String? {
        let normalized = storedCookie.normalizedCookie
        return normalized.isEmpty ? nil : normalized
    }

    static func live() -> PreferencesStore {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "NotEnoughResins"
        let serviceSuffix = ProcessInfo.processInfo.environment["NOT_ENOUGH_RESINS_KEYCHAIN_SERVICE_SUFFIX"]
        let service = [bundleIdentifier, serviceSuffix]
            .compactMap { $0 }
            .joined(separator: ".")

        return PreferencesStore(
            keychain: KeychainStore(
                service: service
            )
        )
    }

    @discardableResult
    func saveCookie(_ cookie: String) throws -> ConfigurationState {
        let normalized = cookie.normalizedCookie
        guard normalized.isEmpty == false else {
            lastErrorMessage = SaveError.emptyCookie.localizedDescription
            throw SaveError.emptyCookie
        }

        do {
            try keychain.upsertString(normalized, for: Self.cookieStorageAccount)
            storedCookie = normalized
            configurationState = .configurationReady
            lastErrorMessage = nil
            return configurationState
        } catch {
            lastErrorMessage = SaveError.persistenceFailed.localizedDescription
            throw SaveError.persistenceFailed
        }
    }

    func reloadFromStorage() {
        do {
            storedCookie = try keychain.readString(for: Self.cookieStorageAccount) ?? ""
            configurationState = storedCookie.normalizedCookie.isEmpty
                ? .needsConfiguration
                : .configurationReady
            lastErrorMessage = nil
        } catch {
            storedCookie = ""
            configurationState = .needsConfiguration
            lastErrorMessage = "The saved HoYoLAB cookie could not be loaded."
        }
    }
}

private extension String {
    var normalizedCookie: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
