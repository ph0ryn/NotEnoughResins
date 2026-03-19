import Foundation
import Security

protocol KeychainStoring {
    func readString(for account: String) throws -> String?
    func upsertString(_ value: String, for account: String) throws
}

struct KeychainStore: KeychainStoring {
    enum StoreError: Error {
        case invalidStoredValue
        case unexpectedStatus(OSStatus)
    }

    let service: String

    func readString(for account: String) throws -> String? {
        var query = baseQuery(for: account)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data,
                  let value = String(data: data, encoding: .utf8)
            else {
                throw StoreError.invalidStoredValue
            }
            return value
        case errSecItemNotFound:
            return nil
        default:
            throw StoreError.unexpectedStatus(status)
        }
    }

    func upsertString(_ value: String, for account: String) throws {
        let data = Data(value.utf8)
        let query = baseQuery(for: account)
        let attributesToUpdate: [CFString: Any] = [
            kSecValueData: data,
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributesToUpdate as CFDictionary
        )

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData] = data
            addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw StoreError.unexpectedStatus(addStatus)
            }
        default:
            throw StoreError.unexpectedStatus(updateStatus)
        }
    }

    private func baseQuery(for account: String) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
    }
}
