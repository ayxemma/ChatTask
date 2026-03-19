import Foundation

enum AppError: LocalizedError, Equatable {
    case permissionDenied(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let detail):
            return detail
        case .unknown(let detail):
            return detail
        }
    }
}
