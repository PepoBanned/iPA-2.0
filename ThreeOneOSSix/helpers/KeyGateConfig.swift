import Foundation

/// Validación OFFLINE de la key de desbloqueo — sin conexión, sin servidor.
///
/// La app reconoce una key como válida si tiene el mismo "checksum"
/// criptográfico que genera el bot de Telegram al crearla (ambos usan el
/// mismo secreto compartido). No hay ninguna llamada de red involucrada.
///
/// EDITA ESTO: `sharedSecret` debe ser EXACTAMENTE igual al valor de
/// `APP_KEY_SHARED_SECRET` en el `config.py` de tu bot. Si no coinciden,
/// ninguna key generada por el bot será aceptada por la app.
enum KeyGateConfig {
    static let sharedSecret = "47ba0a92cbe7bf2aca5b23127f5355bdf20f0f26e02933abddabdcf8995d4676"
}
