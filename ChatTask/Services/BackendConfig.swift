import Foundation

/// Central configuration for the ChatTask HTTP backend.
///
/// **Simulator (DEBUG)**  
/// Use `http://127.0.0.1:<port>` or `http://localhost:<port>` — both reach the Mac that runs the Simulator.
///
/// **Physical device**  
/// `localhost` / `127.0.0.1` refer to the **phone**, not your Mac. Point the app at your Mac’s **LAN IP**
/// (e.g. `http://192.168.1.10:8000`) or a deployed URL. Run the backend bound to all interfaces (`0.0.0.0`)
/// so it accepts connections from the device.
///
/// Override at runtime (highest priority) with the `CHATTASK_BACKEND_URL` environment variable
/// (Xcode → Scheme → Run → Arguments → Environment Variables). Use this when the default port or host differs.
enum BackendConfig {

    /// Default base URL when no override is set.
    /// - DEBUG: local backend (adjust port to match your server; common Python/uvicorn default is 8000).
    /// - RELEASE: replace with your real production API origin before shipping.
    #if DEBUG
    private static let defaultBaseURLString = "http://127.0.0.1:8000"
    #else
    private static let defaultBaseURLString = "https://api.chattask.app"
    #endif

    /// Resolved backend origin (no trailing slash).
    static var baseURL: URL {
        let trimmed = ProcessInfo.processInfo.environment["CHATTASK_BACKEND_URL"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty, let url = URL(string: trimmed) {
            return url
        }
        guard let url = URL(string: defaultBaseURLString) else {
            fatalError("BackendConfig: invalid defaultBaseURLString")
        }
        return url
    }

    /// `POST` multipart audio → JSON `{ "text": "..." }`
    static var transcribeURL: URL {
        baseURL.appendingPathComponent("transcribe")
    }

    /// `POST` JSON body with `text`, `now`, `timezone`, optional `locale` → parsed command JSON
    static var parseURL: URL {
        baseURL.appendingPathComponent("parse")
    }
}
