import Foundation

@MainActor
@Observable
final class AppSettings {
    private static let languageKey = "appLanguage"

    var language: AppLanguage {
        didSet {
            guard language != oldValue else { return }
            UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey)
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.languageKey),
           let parsed = AppLanguage(rawValue: raw) {
            language = parsed
        } else {
            language = AppLanguage.defaultForDevice()
        }
    }
}
