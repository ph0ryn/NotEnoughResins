import AppKit
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
                CookieTextField(
                    text: $cookieDraft,
                    placeholder: "Paste the HoYoLAB cookie"
                )
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

private struct CookieTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(string: text)
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.font = NSFont.monospacedSystemFont(
            ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize,
            weight: .regular
        )
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBezeled = true
        textField.isBordered = true
        textField.focusRingType = .default

        if let cell = textField.cell as? NSTextFieldCell {
            cell.wraps = false
            cell.isScrollable = true
            cell.usesSingleLineMode = true
            cell.lineBreakMode = .byClipping
        }

        textField.setAccessibilityIdentifier("preferences.cookieEditor")
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        context.coordinator.syncExternalText(text, into: nsView)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        private let text: Binding<String>
        private var clickMonitor: Any?
        private weak var monitoredWindow: NSWindow?

        init(text: Binding<String>) {
            self.text = text
        }

        deinit {
            removeClickMonitor()
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }

            text.wrappedValue = textField.stringValue
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }

            scheduleBlurIfStillFocused(afterCurrentEventFor: textField)
        }

        func control(
            _ control: NSControl,
            textView _: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            guard
                commandSelector == #selector(NSResponder.insertNewline(_:)),
                let textField = control as? NSTextField
            else {
                return false
            }

            text.wrappedValue = textField.stringValue
            scheduleBlurIfStillFocused(afterCurrentEventFor: textField)
            return true
        }

        func syncExternalText(_ externalText: String, into textField: NSTextField) {
            installClickMonitor(for: textField)

            guard textField.stringValue != externalText else {
                return
            }

            let selectedRanges = (textField.currentEditor() as? NSTextView)?.selectedRanges
            textField.stringValue = externalText

            if let selectedRanges, let editor = textField.currentEditor() as? NSTextView {
                editor.selectedRanges = selectedRanges
            }
        }

        private func installClickMonitor(for textField: NSTextField) {
            guard let window = textField.window else {
                removeClickMonitor()
                return
            }

            guard monitoredWindow !== window || clickMonitor == nil else {
                return
            }

            removeClickMonitor()
            monitoredWindow = window

            clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) {
                [weak self, weak textField, weak window] event in
                guard let self, let textField, let window, event.window === window else {
                    return event
                }

                guard let contentView = window.contentView else {
                    return event
                }

                let location = contentView.convert(event.locationInWindow, from: nil)
                let hitView = contentView.hitTest(location)

                if let hitView, hitView.isDescendant(of: textField) {
                    return event
                }

                if window.firstResponder === textField.currentEditor() || window.firstResponder === textField {
                    self.scheduleBlurIfStillFocused(afterCurrentEventFor: textField)
                }

                return event
            }
        }

        private func scheduleBlurIfStillFocused(afterCurrentEventFor textField: NSTextField) {
            DispatchQueue.main.async { [weak textField] in
                guard let textField, let window = textField.window else {
                    return
                }

                if window.firstResponder === textField.currentEditor() || window.firstResponder === textField {
                    if let contentView = window.contentView {
                        window.makeFirstResponder(contentView)
                    } else {
                        window.makeFirstResponder(nil)
                    }
                }
            }
        }

        private func removeClickMonitor() {
            if let clickMonitor {
                NSEvent.removeMonitor(clickMonitor)
                self.clickMonitor = nil
            }
            monitoredWindow = nil
        }
    }
}
