import Foundation
import CryptoKit

/// Valida una key de Xternal B completamente offline: sin red, sin
/// servidor. El mismo algoritmo (HMAC-SHA256 con un secreto compartido)
/// vive también en el bot de Telegram (`main.py`, función `_checksum`) —
/// si cambias algo aquí, cambia lo mismo ahí o dejan de coincidir.
enum OfflineKeyValidator {
    /// 32 caracteres, sin 0/O/1/I para que no se confundan al leerlas.
    /// DEBE coincidir exacto con KEY_ALPHABET en main.py.
    static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func isValid(_ raw: String) -> Bool {
        let compact = raw.uppercased().filter { $0.isLetter || $0.isNumber }
        guard compact.hasPrefix("XB") else { return false }
        let rest = Array(compact.dropFirst(2))
        guard rest.count == 12 else { return false }
        guard rest.allSatisfy({ alphabet.contains($0) }) else { return false }
        let body = String(rest.prefix(8))
        let checksum = String(rest.suffix(4))
        return checksum == computeChecksum(body: body)
    }

    private static func computeChecksum(body: String) -> String {
        let key = SymmetricKey(data: Data(KeyGateConfig.sharedSecret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(body.utf8), using: key)
        let bytes = Array(mac)
        let value24 = (UInt32(bytes[0]) << 16) | (UInt32(bytes[1]) << 8) | UInt32(bytes[2])
        var out = ""
        for i in 0..<4 {
            let shift = UInt32(20 - 5 * i)
            let idx = Int((value24 >> shift) & 0x1F)
            out.append(alphabet[idx])
        }
        return out
    }
}

/// Drives the "enter your key" gate shown before anything else in the app.
/// Completely offline: a key either matches the pattern or it doesn't —
/// there is nothing to retry, no network, no periodic re-check.
@MainActor
final class KeyGateStore: ObservableObject {
    enum State: Equatable {
        case needsKey(error: String?)
        case unlocked
    }

    @Published private(set) var state: State = .needsKey(error: nil)

    private let defaults = UserDefaults.standard
    private let keyDefaultsKey = "xb.licenseKey"

    /// Call once at app launch: if a previously-accepted key is stored,
    /// skip straight to unlocked (still fast/offline — just re-checks the
    /// same local pattern, no reason to make the person retype it).
    func bootstrap() {
        if let saved = defaults.string(forKey: keyDefaultsKey), OfflineKeyValidator.isValid(saved) {
            state = .unlocked
        } else {
            state = .needsKey(error: nil)
        }
    }

    /// Call when the user taps "Validar".
    func submit(key rawKey: String) {
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .needsKey(error: "Escribe o pega una key primero.")
            return
        }
        guard OfflineKeyValidator.isValid(trimmed) else {
            state = .needsKey(error: "Esa key no es válida. Revisa que esté completa y bien escrita.")
            return
        }
        defaults.set(trimmed.uppercased(), forKey: keyDefaultsKey)
        state = .unlocked
    }

    func reset() {
        defaults.removeObject(forKey: keyDefaultsKey)
        state = .needsKey(error: nil)
    }
}
