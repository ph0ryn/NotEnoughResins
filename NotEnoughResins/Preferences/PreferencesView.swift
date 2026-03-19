import SwiftUI

struct PreferencesView: View {
    @ObservedObject var store: PreferencesStore

    @State private var cookieDraft: String
    @State private var feedbackMessage: String?
    @FocusState private var isFocused: Bool

    init(store: PreferencesStore) {
        self.store = store
        _cookieDraft = State(initialValue: store.storedCookie)
    }

    var body: some View {
        Form {
            Section("HoYoLAB Cookie") {
                TextField("Paste the HoYoLAB cookie", text: $cookieDraft, prompt: Text("_HYVUUID="))
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onSubmit {
                        isFocused = false
                    }
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
                    Spacer()

                    Button("Save Cookie") {
                        isFocused = false
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
            feedbackMessage = "Successfully saved cookie to Keychain."
        } catch let error as PreferencesStore.SaveError {
            feedbackMessage = error.localizedDescription
        } catch {
            feedbackMessage = "Failed to load saved cookie from Keychain."
        }
    }
}
