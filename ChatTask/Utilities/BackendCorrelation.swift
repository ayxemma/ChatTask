import Foundation

/// Shared HTTP / JSON keys for correlating client requests with backend logs.
enum BackendCorrelation {
    /// Standard header for tracing a single HTTP request end-to-end.
    static let requestIDHeaderField = "X-Request-ID"

    /// JSON field sent with `POST /parse` so server logs can match the same id as the app.
    static let requestIDJSONKey = "request_id"
}

enum BackendConnectionDiagnostics {
    /// Typical when TCP cannot be established: server down, wrong host/port, or hostname DNS failure.
    static func isLikelyServerUnreachable(_ error: Error) -> Bool {
        let ns = error as NSError
        guard ns.domain == NSURLErrorDomain else { return false }
        switch ns.code {
        case NSURLErrorCannotConnectToHost,
             NSURLErrorCannotFindHost,
             NSURLErrorDNSLookupFailed:
            return true
        default:
            return false
        }
    }
}

/// User-visible strings only — never includes `requestId`, raw errors, or URLs.
enum BackendUserFacingErrorMessages {
    /// Cloud transcription: network error where the server likely was not reached.
    static func transcriptionNetwork(strings: AppStrings, underlying: Error) -> String {
        let unreachable = BackendConnectionDiagnostics.isLikelyServerUnreachable(underlying)
        #if DEBUG
        if unreachable {
            return "Cannot connect to server. Is the backend running?"
        }
        return strings.chatErrorOffline
        #else
        if unreachable {
            return strings.chatErrorSomethingWentWrong
        }
        return strings.chatErrorOffline
        #endif
    }
}
