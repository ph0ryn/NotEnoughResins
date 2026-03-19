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
                CookieTextEditor(text: $cookieDraft)
                    .frame(minHeight: 160)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor))
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

private struct CookieTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> CookieEditorContainerView {
        let containerView = CookieEditorContainerView()
        containerView.textView.delegate = context.coordinator
        containerView.textView.string = text
        return containerView
    }

    func updateNSView(_ nsView: CookieEditorContainerView, context _: Context) {
        if nsView.textView.string != text {
            nsView.textView.string = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            text.wrappedValue = textView.string
        }
    }
}

private final class CookieEditorContainerView: NSView {
    let textView: NSTextView

    override var isFlipped: Bool {
        true
    }

    override init(frame frameRect: NSRect) {
        textView = NSTextView(frame: .zero)
        super.init(frame: frameRect)
        configureTextView()
        installTextView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        nil
    }

    private func configureTextView() {
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFindBar = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.minSize = .zero
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainerInset = NSSize(width: 0, height: 6)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.font = NSFont.monospacedSystemFont(
            ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize,
            weight: .regular
        )
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
    }

    private func installTextView() {
        addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
