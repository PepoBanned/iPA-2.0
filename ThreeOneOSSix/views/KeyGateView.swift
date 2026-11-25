import SwiftUI

/// Full-screen gate shown before anything else in the app (even before
/// onboarding). Totally offline: "Pegar key" reads the clipboard, "Validar"
/// checks the pattern locally — no network, no server round trip.
struct KeyGateView: View {
    @ObservedObject var store: KeyGateStore
    @State private var input = ""
    @FocusState private var fieldFocused: Bool

    private var errorText: String? {
        if case .needsKey(let error) = store.state { return error }
        return nil
    }

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 12)

                AppLogo(size: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(radius: 10)

                VStack(spacing: 6) {
                    Text("Ingresa tu key")
                        .font(.title2.weight(.semibold))
                    Text("Pega o escribe la key que te dieron para desbloquear Xternal B.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 14) {
                    TextField("XB-XXXX-XXXX-XXXX", text: $input)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                        .multilineTextAlignment(.center)
                        .focused($fieldFocused)
                        .submitLabel(.go)
                        .onSubmit(attemptValidate)
                        .padding(.horizontal, 11)
                        .frame(minHeight: 44)
                        .background(
                            Color(uiColor: .secondarySystemFill),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )

                    if let errorText {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 12) {
                        Button(action: pasteFromClipboard) {
                            Label("Pegar key", systemImage: "doc.on.clipboard")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RedPillButtonStyle())

                        Button(action: attemptValidate) {
                            Label("Validar", systemImage: "checkmark.seal.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RedPillButtonStyle())
                        .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(.horizontal, 8)

                Spacer()
            }
            .padding(.horizontal, AppTheme.pageInset)
        }
        .onAppear { fieldFocused = true }
    }

    private func pasteFromClipboard() {
        if let clip = UIPasteboard.general.string, !clip.isEmpty {
            input = clip
        }
    }

    private func attemptValidate() {
        fieldFocused = false
        store.submit(key: input)
    }
}

/// Botón rojo, grande y fácil de tocar — igual para "Pegar key" y "Validar".
private struct RedPillButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .background(
                Color.red.opacity(!isEnabled ? 0.35 : (configuration.isPressed ? 0.75 : 1)),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
    }
}
