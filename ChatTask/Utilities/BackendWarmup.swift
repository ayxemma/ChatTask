import Foundation

// MARK: - Session warm-up (single flight, one success per process)

/// Coordinates `GET /health` wake-up calls: at most one in-flight request, and no further work
/// after a successful health check for the lifetime of the process (until app restart).
private actor WarmupSessionCoordinator {
    private var hasCompletedHealthCheck2xx = false
    private var inFlight: Task<Void, Never>?

    /// Schedules a best-effort warm-up if the session has not already succeeded and no request is in flight.
    func schedule() {
        if hasCompletedHealthCheck2xx { return }
        if inFlight != nil { return }
        inFlight = Task(priority: .utility) {
            await self.runSingleHealthRequest()
        }
    }

    private func runSingleHealthRequest() async {
        defer { inFlight = nil }

        var request = URLRequest(url: BackendConfig.healthURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        // Warm-up is intentionally NOT routed through `BackendFetchRetry` — a single `GET` only.
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                hasCompletedHealthCheck2xx = true
            }
        } catch {
            // Silent — a later lifecycle or pre-request `schedule` may try again.
        }
    }
}

// MARK: - Public API

/// Fire-and-forget requests to `GET /health` so a cold-hosted backend (e.g. Render) can wake
/// before user-driven API traffic. Session-wide deduplication is enforced; real API calls use
/// ``BackendFetchRetry`` and must never share retry logic with warm-up.
enum BackendWarmup {

    private static let session = WarmupSessionCoordinator()

    /// Use from SwiftUI lifecycle (`.onAppear`, `ScenePhase.active`) and before backend work.
    /// Non-blocking, fire-and-forget; at most one concurrent warm-up; skips after a successful `2xx` health check this process.
    static func scheduleSessionWarmup() {
        Task(priority: .utility) {
            await session.schedule()
        }
    }

    /// Legacy name — forwards to ``scheduleSessionWarmup()``.
    static func warmUpBackendFireAndForget() {
        scheduleSessionWarmup()
    }
}
