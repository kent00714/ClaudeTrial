import SwiftUI

@main
struct TPEFlightTrackerApp: App {
    @StateObject private var languageManager = LanguageManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(languageManager)
                .environment(\.locale, Locale(identifier: languageManager.localeIdentifier))
        }
    }
}

@MainActor
final class LanguageManager: ObservableObject {
    enum Language: String, CaseIterable, Identifiable {
        case en = "en"
        case zhTW = "zh-TW"

        var id: String { rawValue }
    }

    enum Key {
        case tabFlights
        case tabDiscover
        case tabTrips
        case tabTaxi
        case tabHotels
        case tripImportedTitle
        case viewTrip
        case ok
        case importFailed
        case flightsTitle
        case direction
        case updated
        case next
        case searchPrompt
        case error
        case retry
        case language
        case arrivals
        case departures
    }

    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: storageKey)
        }
    }

    private let storageKey = "app_language"

    init() {
        let storedValue = UserDefaults.standard.string(forKey: storageKey) ?? Language.en.rawValue
        currentLanguage = Language(rawValue: storedValue) ?? .en
    }

    func setLanguage(_ language: Language) {
        currentLanguage = language
    }

    var localeIdentifier: String {
        switch currentLanguage {
        case .en:
            return "en"
        case .zhTW:
            return "zh-Hant-TW"
        }
    }

    func displayName(for language: Language) -> String {
        switch language {
        case .en:
            return currentLanguage == .zhTW ? "英文" : "English"
        case .zhTW:
            return currentLanguage == .zhTW ? "繁體中文" : "Chinese (Traditional)"
        }
    }

    func directionText(_ direction: FlightDirection) -> String {
        switch direction {
        case .arrival:
            return t(.arrivals)
        case .departure:
            return t(.departures)
        }
    }

    func tripImportedMessage(_ tripName: String) -> String {
        switch currentLanguage {
        case .en:
            return "'\(tripName)' has been added to your trips."
        case .zhTW:
            return "「\(tripName)」已加入你的行程。"
        }
    }

    func t(_ key: Key) -> String {
        switch currentLanguage {
        case .en:
            switch key {
            case .tabFlights: return "Flights"
            case .tabDiscover: return "Discover"
            case .tabTrips: return "My Trips"
            case .tabTaxi: return "Taxi"
            case .tabHotels: return "Hotels"
            case .tripImportedTitle: return "Trip Imported!"
            case .viewTrip: return "View Trip"
            case .ok: return "OK"
            case .importFailed: return "Import Failed"
            case .flightsTitle: return "TPE Flights"
            case .direction: return "Direction"
            case .updated: return "Updated"
            case .next: return "Next"
            case .searchPrompt: return "Search flights, airlines, cities..."
            case .error: return "Error"
            case .retry: return "Retry"
            case .language: return "Language"
            case .arrivals: return "Arrivals"
            case .departures: return "Departures"
            }
        case .zhTW:
            switch key {
            case .tabFlights: return "航班"
            case .tabDiscover: return "探索"
            case .tabTrips: return "我的行程"
            case .tabTaxi: return "計程車"
            case .tabHotels: return "飯店"
            case .tripImportedTitle: return "行程已匯入"
            case .viewTrip: return "查看行程"
            case .ok: return "確定"
            case .importFailed: return "匯入失敗"
            case .flightsTitle: return "桃園機場航班"
            case .direction: return "方向"
            case .updated: return "更新"
            case .next: return "下一次"
            case .searchPrompt: return "搜尋航班、航空公司、城市..."
            case .error: return "錯誤"
            case .retry: return "重試"
            case .language: return "語言"
            case .arrivals: return "抵達"
            case .departures: return "出發"
            }
        }
    }
}
