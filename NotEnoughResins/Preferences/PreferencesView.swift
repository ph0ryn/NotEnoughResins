import SwiftUI

struct PreferencesView: View {
    @ObservedObject var store: PreferencesStore

    @State private var cookieDraft: String
    @State private var feedbackMessage: String?

    init(store: PreferencesStore) {
        self.store = store
        _cookieDraft = State(initialValue: store.storedCookie)
    }

    var body: some View {
        Form {
            Section("HoYoLAB Cookie") {
                TextEditor(text: $cookieDraft)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 160)
                    .accessibilityIdentifier("preferences.cookieEditor")

                Text("The cookie is stored in Keychain and is not written to UserDefaults.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let feedback = feedbackMessage ?? store.lastErrorMessage {
                    Text(feedback)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button("Reload Saved Cookie") {
                        store.reloadFromStorage()
                        cookieDraft = store.storedCookie
                        feedbackMessage = nil
                    }
                    .accessibilityIdentifier("preferences.reloadButton")

                    Spacer()

                    Button("Save Cookie") {
                        saveCookie()
                    }
                    .disabled(cookieDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("preferences.saveButton")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 320)
        .padding(20)
        .onChange(of: store.storedCookie) { _, newValue in
            cookieDraft = newValue
        }
    }

    private func saveCookie() {
        do {
            try store.saveCookie(cookieDraft)
            cookieDraft = store.storedCookie
            feedbackMessage = "Cookie saved to Keychain."
        } catch let error as PreferencesStore.SaveError {
            feedbackMessage = error.localizedDescription
        } catch {
            feedbackMessage = "The HoYoLAB cookie could not be saved."
        }
    }
}
