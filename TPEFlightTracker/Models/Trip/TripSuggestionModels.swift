import Foundation
import CoreLocation

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
        suggestedTravelMode: TravelMode = .transit
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
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedEstimatedTime: String {
        let hours = estimatedTimeMinutes / 60
        let mins = estimatedTimeMinutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(mins) min"
        }
    }

    /// Convert to TripDestination for adding to user's trip
    func toTripDestination() -> TripDestination {
        TripDestination(
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            notes: description,
            order: order,
            travelMode: suggestedTravelMode
        )
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
        lastUpdated: Date = Date()
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
    }

    var totalEstimatedTimeMinutes: Int {
        destinations.map(\.estimatedTimeMinutes).reduce(0, +)
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

    /// Convert to Trip for adding to user's trips
    func toTrip(startDate: Date = Date()) -> Trip {
        let endDate = Calendar.current.date(
            byAdding: .day,
            value: duration.days,
            to: startDate
        ) ?? startDate

        return Trip(
            name: name,
            startDate: startDate,
            endDate: endDate,
            destinations: destinations.map { $0.toTripDestination() }
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
