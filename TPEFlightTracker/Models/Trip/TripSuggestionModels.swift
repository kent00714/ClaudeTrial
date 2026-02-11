import Foundation
import CoreLocation

private enum AppLanguageState {
    static var isTraditionalChinese: Bool {
        UserDefaults.standard.string(forKey: "app_language") == "zh-TW"
    }
}

// MARK: - Suggestion Category

enum SuggestionCategory: String, Codable, CaseIterable, Identifiable {
    case firstTime = "first_time"
    case cultural = "cultural"
    case foodie = "foodie"
    case nature = "nature"
    case nightlife = "nightlife"
    case shopping = "shopping"
    case familyFriendly = "family"
    case romantic = "romantic"
    case adventure = "adventure"
    case trending = "trending"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .firstTime: return "First Time in Taiwan"
        case .cultural: return "Culture & History"
        case .foodie: return "Food Paradise"
        case .nature: return "Nature Escape"
        case .nightlife: return "Night Markets & Nightlife"
        case .shopping: return "Shopping Spree"
        case .familyFriendly: return "Family Fun"
        case .romantic: return "Romantic Getaway"
        case .adventure: return "Adventure"
        case .trending: return "Trending Now"
        }
    }

    var systemImage: String {
        switch self {
        case .firstTime: return "star.fill"
        case .cultural: return "building.columns.fill"
        case .foodie: return "fork.knife"
        case .nature: return "leaf.fill"
        case .nightlife: return "moon.stars.fill"
        case .shopping: return "bag.fill"
        case .familyFriendly: return "figure.2.and.child.holdinghands"
        case .romantic: return "heart.fill"
        case .adventure: return "figure.hiking"
        case .trending: return "flame.fill"
        }
    }

    var accentColor: String {
        switch self {
        case .firstTime: return "orange"
        case .cultural: return "brown"
        case .foodie: return "red"
        case .nature: return "green"
        case .nightlife: return "purple"
        case .shopping: return "pink"
        case .familyFriendly: return "blue"
        case .romantic: return "red"
        case .adventure: return "orange"
        case .trending: return "orange"
        }
    }

    var welcomeMessage: String {
        switch self {
        case .firstTime:
            return "Welcome to Taiwan! Here are the must-see destinations for first-time visitors."
        case .cultural:
            return "Discover Taiwan's rich history and traditional culture."
        case .foodie:
            return "Taiwan is a food lover's paradise. Prepare your taste buds!"
        case .nature:
            return "Escape the city and explore Taiwan's stunning natural beauty."
        case .nightlife:
            return "Experience Taiwan's famous night markets and vibrant nightlife."
        case .shopping:
            return "From luxury malls to local markets, find your perfect shopping spots."
        case .familyFriendly:
            return "Fun activities and attractions the whole family will enjoy."
        case .romantic:
            return "Beautiful spots perfect for couples and romantic moments."
        case .adventure:
            return "Thrilling activities for the adventurous spirit."
        case .trending:
            return "What's hot right now! Popular spots locals and tourists love."
        }
    }
}

// MARK: - Trip Duration

enum TripDuration: String, Codable, CaseIterable, Identifiable {
    case halfDay = "half_day"
    case fullDay = "full_day"
    case weekend = "weekend"
    case threeDays = "three_days"
    case oneWeek = "one_week"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .halfDay: return "Half Day"
        case .fullDay: return "Full Day"
        case .weekend: return "Weekend"
        case .threeDays: return "3 Days"
        case .oneWeek: return "1 Week"
        }
    }

    var days: Int {
        switch self {
        case .halfDay: return 1
        case .fullDay: return 1
        case .weekend: return 2
        case .threeDays: return 3
        case .oneWeek: return 7
        }
    }

    var hours: Int {
        switch self {
        case .halfDay: return 4
        case .fullDay: return 8
        case .weekend: return 16
        case .threeDays: return 24
        case .oneWeek: return 56
        }
    }
}

// MARK: - Suggested Destination

struct SuggestedDestination: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let nameLocal: String  // Chinese name
    let address: String
    let latitude: Double
    let longitude: Double
    let description: String
    let tips: [String]
    let estimatedTimeMinutes: Int  // How long to spend here
    let order: Int
    let suggestedTravelMode: TravelMode

    // Attraction links
    let ticketURL: String?          // URL to purchase tickets (KKday, Klook, official site)
    let officialWebsiteURL: String? // Official website of the attraction
    let requiresTicket: Bool        // Whether tickets are required for entry

    init(
        id: UUID = UUID(),
        name: String,
        nameLocal: String = "",
        address: String,
        latitude: Double,
        longitude: Double,
        description: String = "",
        tips: [String] = [],
        estimatedTimeMinutes: Int = 60,
        order: Int = 0,
        suggestedTravelMode: TravelMode = .transit,
        ticketURL: String? = nil,
        officialWebsiteURL: String? = nil,
        requiresTicket: Bool = false
    ) {
        self.id = id
        self.name = name
        self.nameLocal = nameLocal
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
        self.tips = tips
        self.estimatedTimeMinutes = estimatedTimeMinutes
        self.order = order
        self.suggestedTravelMode = suggestedTravelMode
        self.ticketURL = ticketURL
        self.officialWebsiteURL = officialWebsiteURL
        self.requiresTicket = requiresTicket
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var localizedName: String {
        if AppLanguageState.isTraditionalChinese, !nameLocal.isEmpty {
            return nameLocal
        }
        let translated = localized(name)
        if AppLanguageState.isTraditionalChinese && translated == name {
            return "景點 \(order + 1)"
        }
        return translated
    }

    var localizedDescription: String {
        let translated = localized(description)
        if AppLanguageState.isTraditionalChinese && translated == description {
            return "建議停留 \(formattedEstimatedTime)，可依當日行程彈性調整。"
        }
        return translated
    }

    var localizedTips: [String] {
        tips.enumerated().map { index, tip in
            let translated = localized(tip)
            if AppLanguageState.isTraditionalChinese && translated == tip {
                if index == 0 {
                    return "建議提早安排此站，並預留 \(formattedEstimatedTime) 參觀。"
                }
                return "出發前先確認開放時間與現場資訊。"
            }
            return translated
        }
    }

    var formattedEstimatedTime: String {
        let hours = estimatedTimeMinutes / 60
        let mins = estimatedTimeMinutes % 60
        if AppLanguageState.isTraditionalChinese {
            if hours > 0 && mins > 0 {
                return "\(hours) 小時 \(mins) 分"
            } else if hours > 0 {
                return "\(hours) 小時"
            } else {
                return "\(mins) 分鐘"
            }
        }
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(mins) min"
        }
    }

    /// Get the best available link for this destination
    var bestAvailableURL: URL? {
        if requiresTicket, let ticketURLString = ticketURL, let url = URL(string: ticketURLString) {
            return url
        }
        if let websiteURLString = officialWebsiteURL, let url = URL(string: websiteURLString) {
            return url
        }
        return googleMapsURL
    }

    /// Get Google Maps URL for this location
    var googleMapsURL: URL? {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)&query_place_id=\(encodedName)")
    }

    /// Label for the primary action button
    var primaryLinkLabel: String {
        if requiresTicket && ticketURL != nil {
            return "Buy Tickets"
        } else if officialWebsiteURL != nil {
            return "Official Website"
        } else {
            return "View on Map"
        }
    }

    /// Icon for the primary action button
    var primaryLinkIcon: String {
        if requiresTicket && ticketURL != nil {
            return "ticket.fill"
        } else if officialWebsiteURL != nil {
            return "globe"
        } else {
            return "map.fill"
        }
    }

    /// Convert to TripDestination for adding to user's trip
    func toTripDestination() -> TripDestination {
        TripDestination(
            name: localizedName,
            address: address,
            latitude: latitude,
            longitude: longitude,
            notes: localizedDescription,
            order: order,
            estimatedStayMinutes: estimatedTimeMinutes,
            tips: localizedTips,
            travelMode: suggestedTravelMode,
            ticketURL: ticketURL,
            officialWebsiteURL: officialWebsiteURL,
            requiresTicket: requiresTicket
        )
    }

    private func localized(_ value: String) -> String {
        let translated = NSLocalizedString(value, comment: "")
        return translated == value ? value : translated
    }
}

// MARK: - Trip Suggestion

struct TripSuggestion: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let subtitle: String
    let description: String
    let category: SuggestionCategory
    let duration: TripDuration
    let destinations: [SuggestedDestination]
    let highlights: [String]
    let bestTime: String  // e.g., "Morning", "Evening", "All day"
    let budgetLevel: BudgetLevel
    let difficulty: DifficultyLevel
    let tags: [String]
    let seasonalNote: String?  // Special notes for certain seasons
    let lastUpdated: Date
    let trendingData: TrendingData?  // Dynamic trending information
    let bestSeasons: [Season]        // When this trip is best
    let relatedEvents: [String]      // IDs of related events/festivals

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String = "",
        description: String,
        category: SuggestionCategory,
        duration: TripDuration,
        destinations: [SuggestedDestination],
        highlights: [String] = [],
        bestTime: String = "All day",
        budgetLevel: BudgetLevel = .moderate,
        difficulty: DifficultyLevel = .easy,
        tags: [String] = [],
        seasonalNote: String? = nil,
        lastUpdated: Date = Date(),
        trendingData: TrendingData? = nil,
        bestSeasons: [Season] = [.all],
        relatedEvents: [String] = []
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.description = description
        self.category = category
        self.duration = duration
        self.destinations = destinations
        self.highlights = highlights
        self.bestTime = bestTime
        self.budgetLevel = budgetLevel
        self.difficulty = difficulty
        self.tags = tags
        self.seasonalNote = seasonalNote
        self.lastUpdated = lastUpdated
        self.trendingData = trendingData
        self.bestSeasons = bestSeasons
        self.relatedEvents = relatedEvents
    }

    var totalEstimatedTimeMinutes: Int {
        destinations.map(\.estimatedTimeMinutes).reduce(0, +)
    }

    var localizedName: String {
        let translated = localized(name)
        if AppLanguageState.isTraditionalChinese && translated == name {
            return "\(localized(category.displayName))行程"
        }
        return translated
    }

    var localizedSubtitle: String {
        let translated = localized(subtitle)
        if AppLanguageState.isTraditionalChinese && translated == subtitle {
            return "\(localized(duration.displayName))・\(localized(category.displayName))推薦"
        }
        return translated
    }

    var localizedDescription: String {
        let translated = localized(description)
        if AppLanguageState.isTraditionalChinese && translated == description {
            return "這個行程包含 \(destinations.count) 個景點，適合 \(localized(duration.displayName)) 安排。"
        }
        return translated
    }

    var localizedBestTime: String {
        let translated = localized(bestTime)
        if AppLanguageState.isTraditionalChinese && translated == bestTime {
            return "建議白天出發，視景點營業時間調整。"
        }
        return translated
    }

    var localizedHighlights: [String] {
        if AppLanguageState.isTraditionalChinese {
            let translated = highlights.map(localized)
            if translated == highlights {
                return destinations.prefix(3).map(\.localizedName)
            }
            return translated
        }
        return highlights.map(localized)
    }

    var localizedDynamicSubtitle: String {
        let translated = localized(dynamicSubtitle)
        if AppLanguageState.isTraditionalChinese && translated == dynamicSubtitle {
            return localizedSubtitle
        }
        return translated
    }

    var formattedTotalTime: String {
        let hours = totalEstimatedTimeMinutes / 60
        let mins = totalEstimatedTimeMinutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours) hours"
        } else {
            return "\(mins) min"
        }
    }

    /// Check if this trip is good for the current season
    var isGoodForCurrentSeason: Bool {
        bestSeasons.contains(.all) || bestSeasons.contains(Season.current)
    }

    /// Check if this trip is currently trending
    var isTrending: Bool {
        guard let trending = trendingData else { return false }
        return trending.trendingScore >= 70 || trending.isCurrentlyHot
    }

    /// Get dynamic subtitle based on trending status
    var dynamicSubtitle: String {
        if let trending = trendingData, trending.isCurrentlyHot, let reason = trending.trendingReason {
            return reason
        }
        return subtitle
    }

    private func localized(_ value: String) -> String {
        let translated = NSLocalizedString(value, comment: "")
        return translated == value ? value : translated
    }

    /// Convert to Trip for adding to user's trips
    func toTrip(startDate: Date = Date()) -> Trip {
        toTrip(name: localizedName, startDate: startDate, notes: localizedDescription, flightNumber: nil)
    }

    /// Convert to Trip with custom name, start date, notes, and optional flight number
    func toTrip(name customName: String, startDate: Date, notes customNotes: String, flightNumber: String? = nil) -> Trip {
        let endDate = Calendar.current.date(
            byAdding: .day,
            value: duration.days,
            to: startDate
        ) ?? startDate

        return Trip(
            name: customName,
            startDate: startDate,
            endDate: endDate,
            destinations: destinations.map { $0.toTripDestination() },
            notes: customNotes,
            sourceSuggestionName: localizedName,
            linkedFlightNumber: flightNumber
        )
    }
}

// MARK: - Budget Level

enum BudgetLevel: String, Codable, CaseIterable, Identifiable {
    case budget = "budget"
    case moderate = "moderate"
    case premium = "premium"
    case luxury = "luxury"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .budget: return "Budget-Friendly"
        case .moderate: return "Moderate"
        case .premium: return "Premium"
        case .luxury: return "Luxury"
        }
    }

    var dollarSigns: String {
        switch self {
        case .budget: return "$"
        case .moderate: return "$$"
        case .premium: return "$$$"
        case .luxury: return "$$$$"
        }
    }

    var description: String {
        switch self {
        case .budget: return "Under NT$500/day"
        case .moderate: return "NT$500-1500/day"
        case .premium: return "NT$1500-3000/day"
        case .luxury: return "NT$3000+/day"
        }
    }
}

// MARK: - Difficulty Level

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case easy = "easy"
    case moderate = "moderate"
    case challenging = "challenging"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .challenging: return "Challenging"
        }
    }

    var systemImage: String {
        switch self {
        case .easy: return "figure.walk"
        case .moderate: return "figure.hiking"
        case .challenging: return "figure.climbing"
        }
    }

    var description: String {
        switch self {
        case .easy: return "Suitable for all ages and fitness levels"
        case .moderate: return "Some walking required, comfortable shoes recommended"
        case .challenging: return "Requires good fitness, may involve hiking or climbing"
        }
    }
}

// MARK: - Season

enum Season: String, Codable, CaseIterable {
    case spring
    case summer
    case autumn
    case winter
    case all

    static var current: Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }

    var displayName: String {
        switch self {
        case .spring: return "Spring (Mar-May)"
        case .summer: return "Summer (Jun-Aug)"
        case .autumn: return "Autumn (Sep-Nov)"
        case .winter: return "Winter (Dec-Feb)"
        case .all: return "Year-round"
        }
    }

    var taiwanHighlights: String {
        switch self {
        case .spring: return "Cherry blossoms, Yangmingshan flowers, comfortable weather"
        case .summer: return "Beach trips, water activities, mango season"
        case .autumn: return "Moon Festival, comfortable hiking, fall colors"
        case .winter: return "Hot springs, less crowded, Lunar New Year"
        case .all: return "Great any time of year"
        }
    }
}

// MARK: - Trending Data

struct TrendingData: Codable, Equatable {
    let trendingScore: Int          // 0-100, higher = more trending
    let socialMentions: Int         // Simulated social media mentions
    let trendDirection: TrendDirection
    let trendingReason: String?     // e.g., "Featured on Netflix", "Viral TikTok"
    let lastTrendUpdate: Date
    let peakSeason: Season
    let isCurrentlyHot: Bool        // Is this place trending RIGHT NOW

    init(
        trendingScore: Int = 50,
        socialMentions: Int = 0,
        trendDirection: TrendDirection = .stable,
        trendingReason: String? = nil,
        lastTrendUpdate: Date = Date(),
        peakSeason: Season = .all,
        isCurrentlyHot: Bool = false
    ) {
        self.trendingScore = min(100, max(0, trendingScore))
        self.socialMentions = socialMentions
        self.trendDirection = trendDirection
        self.trendingReason = trendingReason
        self.lastTrendUpdate = lastTrendUpdate
        self.peakSeason = peakSeason
        self.isCurrentlyHot = isCurrentlyHot
    }

    var formattedMentions: String {
        if socialMentions >= 1000000 {
            return String(format: "%.1fM", Double(socialMentions) / 1000000)
        } else if socialMentions >= 1000 {
            return String(format: "%.1fK", Double(socialMentions) / 1000)
        }
        return "\(socialMentions)"
    }

    var trendingBadge: String? {
        if isCurrentlyHot && trendingScore >= 80 {
            return "Hot"
        } else if trendingScore >= 70 {
            return "Popular"
        } else if trendDirection == .rising && trendingScore >= 50 {
            return "Rising"
        }
        return nil
    }
}

enum TrendDirection: String, Codable {
    case rising
    case stable
    case declining

    var systemImage: String {
        switch self {
        case .rising: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

// MARK: - Event/Festival

struct SpecialEvent: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let nameLocal: String
    let description: String
    let startDate: Date
    let endDate: Date
    let location: String
    let tags: [String]

    init(
        id: UUID = UUID(),
        name: String,
        nameLocal: String = "",
        description: String,
        startDate: Date,
        endDate: Date,
        location: String,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.nameLocal = nameLocal
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.tags = tags
    }

    var isHappeningNow: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    var isUpcoming: Bool {
        let now = Date()
        let oneMonthLater = Calendar.current.date(byAdding: .month, value: 1, to: now) ?? now
        return startDate > now && startDate <= oneMonthLater
    }
}
