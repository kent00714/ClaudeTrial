import Foundation

// MARK: - Protocol

protocol TripSuggestionServiceProtocol {
    func getAllSuggestions() -> [TripSuggestion]
    func getSuggestions(for category: SuggestionCategory) -> [TripSuggestion]
    func getSuggestions(for duration: TripDuration) -> [TripSuggestion]
    func getTrendingSuggestions() -> [TripSuggestion]
    func getHotRightNow() -> [TripSuggestion]
    func getSeasonalSuggestions() -> [TripSuggestion]
    func getRecommendedForFirstTimers() -> [TripSuggestion]
    func searchSuggestions(query: String) -> [TripSuggestion]
    func getUpcomingEvents() -> [SpecialEvent]
    func refreshTrendingData() async
}

// MARK: - Service

class TripSuggestionService: TripSuggestionServiceProtocol {

    private var suggestions: [TripSuggestion]
    private var events: [SpecialEvent]
    private let defaults: UserDefaults
    private let trendingCacheKey = "com.tpeflighttracker.trending_cache"
    private let lastRefreshKey = "com.tpeflighttracker.trending_last_refresh"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.suggestions = []
        self.events = TripSuggestionService.createSpecialEvents()

        // Load base suggestions with trending data
        self.suggestions = TripSuggestionService.createCuratedSuggestions()

        // Apply any cached trending updates
        applyCachedTrendingData()
    }

    // MARK: - Public Methods

    func getAllSuggestions() -> [TripSuggestion] {
        suggestions.sorted { s1, s2 in
            // Sort by trending score (descending), then by name
            let score1 = s1.trendingData?.trendingScore ?? 0
            let score2 = s2.trendingData?.trendingScore ?? 0
            if score1 != score2 {
                return score1 > score2
            }
            return s1.name < s2.name
        }
    }

    func getSuggestions(for category: SuggestionCategory) -> [TripSuggestion] {
        suggestions.filter { $0.category == category }
            .sorted { ($0.trendingData?.trendingScore ?? 0) > ($1.trendingData?.trendingScore ?? 0) }
    }

    func getSuggestions(for duration: TripDuration) -> [TripSuggestion] {
        suggestions.filter { $0.duration == duration }
    }

    func getTrendingSuggestions() -> [TripSuggestion] {
        suggestions.filter { $0.isTrending || $0.category == .trending }
            .sorted { ($0.trendingData?.trendingScore ?? 0) > ($1.trendingData?.trendingScore ?? 0) }
    }

    func getHotRightNow() -> [TripSuggestion] {
        suggestions.filter { $0.trendingData?.isCurrentlyHot == true }
            .sorted { ($0.trendingData?.trendingScore ?? 0) > ($1.trendingData?.trendingScore ?? 0) }
    }

    func getSeasonalSuggestions() -> [TripSuggestion] {
        let currentSeason = Season.current
        return suggestions.filter { $0.isGoodForCurrentSeason }
            .sorted { s1, s2 in
                // Prioritize trips where current season is peak
                let isPeak1 = s1.trendingData?.peakSeason == currentSeason
                let isPeak2 = s2.trendingData?.peakSeason == currentSeason
                if isPeak1 != isPeak2 {
                    return isPeak1
                }
                return (s1.trendingData?.trendingScore ?? 0) > (s2.trendingData?.trendingScore ?? 0)
            }
    }

    func getRecommendedForFirstTimers() -> [TripSuggestion] {
        suggestions.filter { $0.category == .firstTime || $0.tags.contains("must-see") }
    }

    func searchSuggestions(query: String) -> [TripSuggestion] {
        let lowercased = query.lowercased()
        guard !lowercased.isEmpty else { return [] }
        return suggestions.filter { suggestion in
            suggestion.name.lowercased().contains(lowercased) ||
            suggestion.localizedName.lowercased().contains(lowercased) ||
            suggestion.description.lowercased().contains(lowercased) ||
            suggestion.localizedDescription.lowercased().contains(lowercased) ||
            suggestion.tags.contains { $0.lowercased().contains(lowercased) } ||
            suggestion.destinations.contains {
                $0.name.lowercased().contains(lowercased) ||
                $0.nameLocal.lowercased().contains(lowercased) ||
                $0.localizedName.lowercased().contains(lowercased)
            }
        }
    }

    func getUpcomingEvents() -> [SpecialEvent] {
        events.filter { $0.isUpcoming || $0.isHappeningNow }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Refresh trending data (simulated - in production would call API)
    func refreshTrendingData() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Update trending scores based on "current trends"
        let updatedSuggestions = suggestions.map { suggestion -> TripSuggestion in
            var newTrending = suggestion.trendingData ?? TrendingData()

            // Simulate dynamic trending changes
            let adjustment = Int.random(in: -5...10)
            let newScore = max(0, min(100, (newTrending.trendingScore) + adjustment))

            newTrending = TrendingData(
                trendingScore: newScore,
                socialMentions: newTrending.socialMentions + Int.random(in: 0...500),
                trendDirection: adjustment > 3 ? .rising : (adjustment < -3 ? .declining : .stable),
                trendingReason: newTrending.trendingReason,
                lastTrendUpdate: Date(),
                peakSeason: newTrending.peakSeason,
                isCurrentlyHot: newScore >= 85
            )

            return TripSuggestion(
                id: suggestion.id,
                name: suggestion.name,
                subtitle: suggestion.subtitle,
                description: suggestion.description,
                category: suggestion.category,
                duration: suggestion.duration,
                destinations: suggestion.destinations,
                highlights: suggestion.highlights,
                bestTime: suggestion.bestTime,
                budgetLevel: suggestion.budgetLevel,
                difficulty: suggestion.difficulty,
                tags: suggestion.tags,
                seasonalNote: suggestion.seasonalNote,
                lastUpdated: suggestion.lastUpdated,
                trendingData: newTrending,
                bestSeasons: suggestion.bestSeasons,
                relatedEvents: suggestion.relatedEvents
            )
        }

        await MainActor.run {
            self.suggestions = updatedSuggestions
            self.cacheTrendingData()
        }
    }

    // MARK: - Private Methods

    private func cacheTrendingData() {
        defaults.set(Date(), forKey: lastRefreshKey)
    }

    private func applyCachedTrendingData() {
        // In production, load cached trending scores
    }

    // MARK: - Special Events

    private static func createSpecialEvents() -> [SpecialEvent] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())

        return [
            SpecialEvent(
                name: "Lunar New Year",
                nameLocal: "農曆新年",
                description: "Taiwan's biggest holiday with temple visits, fireworks, and family gatherings.",
                startDate: calendar.date(from: DateComponents(year: year, month: 1, day: 29)) ?? Date(),
                endDate: calendar.date(from: DateComponents(year: year, month: 2, day: 12)) ?? Date(),
                location: "Nationwide",
                tags: ["festival", "cultural", "family"]
            ),
            SpecialEvent(
                name: "Lantern Festival",
                nameLocal: "元宵節",
                description: "Spectacular lantern displays across Taiwan, especially in Pingxi for sky lanterns.",
                startDate: calendar.date(from: DateComponents(year: year, month: 2, day: 12)) ?? Date(),
                endDate: calendar.date(from: DateComponents(year: year, month: 2, day: 15)) ?? Date(),
                location: "Pingxi, Taipei",
                tags: ["festival", "lanterns", "romantic"]
            ),
            SpecialEvent(
                name: "Yangmingshan Flower Festival",
                nameLocal: "陽明山花季",
                description: "Cherry blossoms and azaleas bloom across Yangmingshan National Park.",
                startDate: calendar.date(from: DateComponents(year: year, month: 2, day: 15)) ?? Date(),
                endDate: calendar.date(from: DateComponents(year: year, month: 3, day: 31)) ?? Date(),
                location: "Yangmingshan",
                tags: ["nature", "flowers", "spring"]
            ),
            SpecialEvent(
                name: "Dragon Boat Festival",
                nameLocal: "端午節",
                description: "Dragon boat races and zongzi (rice dumplings) across Taiwan.",
                startDate: calendar.date(from: DateComponents(year: year, month: 6, day: 10)) ?? Date(),
                endDate: calendar.date(from: DateComponents(year: year, month: 6, day: 10)) ?? Date(),
                location: "Nationwide",
                tags: ["festival", "cultural", "food"]
            ),
            SpecialEvent(
                name: "Mid-Autumn Festival",
                nameLocal: "中秋節",
                description: "Moon gazing, mooncakes, and BBQ gatherings with family and friends.",
                startDate: calendar.date(from: DateComponents(year: year, month: 9, day: 17)) ?? Date(),
                endDate: calendar.date(from: DateComponents(year: year, month: 9, day: 17)) ?? Date(),
                location: "Nationwide",
                tags: ["festival", "cultural", "food", "family"]
            )
        ]
    }

    // MARK: - Curated Suggestions with Trending Data

    private static func createCuratedSuggestions() -> [TripSuggestion] {
        var suggestions: [TripSuggestion] = []

        suggestions.append(contentsOf: createFirstTimeSuggestions())
        suggestions.append(contentsOf: createCulturalSuggestions())
        suggestions.append(contentsOf: createFoodieSuggestions())
        suggestions.append(contentsOf: createNatureSuggestions())
        suggestions.append(contentsOf: createNightlifeSuggestions())
        suggestions.append(contentsOf: createTrendingSuggestions())
        suggestions.append(contentsOf: createFamilySuggestions())
        suggestions.append(contentsOf: createViralSuggestions())

        suggestions.append(contentsOf: createSocialCombinedSuggestions(from: suggestions))
        return normalizeSuggestionDestinations(suggestions, minimumStops: 4)
    }

    private static func createSocialCombinedSuggestions(from source: [TripSuggestion]) -> [TripSuggestion] {
        let ranked = source
            .sorted { ($0.trendingData?.socialMentions ?? 0) > ($1.trendingData?.socialMentions ?? 0) }

        guard ranked.count >= 4 else { return [] }

        let destinationPool = uniqueDestinationPool(from: ranked)
        guard destinationPool.count >= 6 else { return [] }

        let socialTop = ranked.prefix(4)
        let totalMentions = socialTop.reduce(0) { $0 + ($1.trendingData?.socialMentions ?? 0) }
        let averageScore = socialTop.reduce(0) { $0 + ($1.trendingData?.trendingScore ?? 70) } / max(socialTop.count, 1)

        let socialBuzzStops = Array(destinationPool.prefix(6)).enumerated().map { offset, destination in
            cloneDestination(destination, order: offset)
        }
        let viralClassicStops = Array(destinationPool.dropFirst(2).prefix(6)).enumerated().map { offset, destination in
            cloneDestination(destination, order: offset)
        }

        let socialBuzz = TripSuggestion(
            name: "Social Buzz Taiwan Loop",
            subtitle: "Combined from top social media routes",
            description: "A multi-stop itinerary blended from the most mentioned social-media trips, combining iconic landmarks, food, and trending creator spots.",
            category: .trending,
            duration: .threeDays,
            destinations: socialBuzzStops,
            highlights: buildHighlights(base: ["Top social picks"], destinations: socialBuzzStops),
            bestTime: "Start in the morning and continue into the night markets",
            budgetLevel: .moderate,
            difficulty: .easy,
            tags: ["trending", "social", "multi-trip", "must-see"],
            trendingData: TrendingData(
                trendingScore: min(100, averageScore + 6),
                socialMentions: totalMentions,
                trendDirection: .rising,
                trendingReason: "Combined from viral social media spots",
                peakSeason: .all,
                isCurrentlyHot: true
            ),
            bestSeasons: [.all]
        )

        let viralClassic = TripSuggestion(
            name: "Viral + Classic Taiwan Mix",
            subtitle: "Cross-category route from multiple popular trips",
            description: "A cross-category recommendation that merges classic attractions with viral destinations, designed for travelers who want one complete itinerary.",
            category: .trending,
            duration: .weekend,
            destinations: viralClassicStops,
            highlights: buildHighlights(base: ["Classic + viral blend"], destinations: viralClassicStops),
            bestTime: "Use daytime for landmarks and evenings for food and city views",
            budgetLevel: .moderate,
            difficulty: .easy,
            tags: ["trending", "social", "combined", "weekend"],
            trendingData: TrendingData(
                trendingScore: min(100, averageScore + 4),
                socialMentions: Int(Double(totalMentions) * 0.75),
                trendDirection: .rising,
                trendingReason: "Creator route mixing classic and viral stops",
                peakSeason: .all,
                isCurrentlyHot: true
            ),
            bestSeasons: [.all]
        )

        return [socialBuzz, viralClassic]
    }

    private static func normalizeSuggestionDestinations(_ source: [TripSuggestion], minimumStops: Int) -> [TripSuggestion] {
        guard minimumStops > 1 else { return source }
        let destinationPool = uniqueDestinationPool(from: source)

        return source.map { suggestion in
            var adjusted = suggestion.destinations.enumerated().map { index, destination in
                cloneDestination(destination, order: index)
            }

            if adjusted.count < minimumStops {
                var usedKeys = Set(adjusted.map(normalizedDestinationKey))
                for candidate in destinationPool {
                    let key = normalizedDestinationKey(candidate)
                    guard !usedKeys.contains(key) else { continue }
                    adjusted.append(cloneDestination(candidate, order: adjusted.count))
                    usedKeys.insert(key)
                    if adjusted.count >= minimumStops { break }
                }
            }

            return rebuildSuggestion(
                suggestion,
                destinations: adjusted,
                highlights: buildHighlights(base: suggestion.highlights, destinations: adjusted)
            )
        }
    }

    private static func uniqueDestinationPool(from suggestions: [TripSuggestion]) -> [SuggestedDestination] {
        let rankedDestinations = suggestions
            .sorted { ($0.trendingData?.socialMentions ?? 0) > ($1.trendingData?.socialMentions ?? 0) }
            .flatMap(\.destinations)

        var pool: [SuggestedDestination] = []
        var seen = Set<String>()
        for destination in rankedDestinations {
            let key = normalizedDestinationKey(destination)
            if seen.insert(key).inserted {
                pool.append(destination)
            }
        }
        return pool
    }

    private static func normalizedDestinationKey(_ destination: SuggestedDestination) -> String {
        if !destination.nameLocal.isEmpty {
            return destination.nameLocal.lowercased()
        }
        return destination.name.lowercased()
    }

    private static func cloneDestination(_ destination: SuggestedDestination, order: Int) -> SuggestedDestination {
        SuggestedDestination(
            id: destination.id,
            name: destination.name,
            nameLocal: destination.nameLocal,
            address: destination.address,
            latitude: destination.latitude,
            longitude: destination.longitude,
            description: destination.description,
            tips: destination.tips,
            estimatedTimeMinutes: destination.estimatedTimeMinutes,
            order: order,
            suggestedTravelMode: destination.suggestedTravelMode,
            ticketURL: destination.ticketURL,
            officialWebsiteURL: destination.officialWebsiteURL,
            requiresTicket: destination.requiresTicket
        )
    }

    private static func buildHighlights(base: [String], destinations: [SuggestedDestination]) -> [String] {
        let candidates = base + destinations.map(\.name)
        var unique: [String] = []
        var seen = Set<String>()
        for candidate in candidates {
            let key = candidate.lowercased()
            if seen.insert(key).inserted {
                unique.append(candidate)
            }
            if unique.count == 4 { break }
        }
        return unique
    }

    private static func rebuildSuggestion(
        _ suggestion: TripSuggestion,
        destinations: [SuggestedDestination],
        highlights: [String]
    ) -> TripSuggestion {
        TripSuggestion(
            id: suggestion.id,
            name: suggestion.name,
            subtitle: suggestion.subtitle,
            description: suggestion.description,
            category: suggestion.category,
            duration: suggestion.duration,
            destinations: destinations,
            highlights: highlights,
            bestTime: suggestion.bestTime,
            budgetLevel: suggestion.budgetLevel,
            difficulty: suggestion.difficulty,
            tags: suggestion.tags,
            seasonalNote: suggestion.seasonalNote,
            lastUpdated: suggestion.lastUpdated,
            trendingData: suggestion.trendingData,
            bestSeasons: suggestion.bestSeasons,
            relatedEvents: suggestion.relatedEvents
        )
    }

    // MARK: - First Time Visitors

    private static func createFirstTimeSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Essential Taipei",
                subtitle: "The must-see Taipei experience",
                description: "Perfect introduction to Taipei! Visit the iconic Taipei 101, explore traditional temples, and experience the vibrant night market culture.",
                category: .firstTime,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(
                        name: "Taipei 101",
                        nameLocal: "台北101",
                        address: "No. 7, Section 5, Xinyi Road, Xinyi District",
                        latitude: 25.0339,
                        longitude: 121.5645,
                        description: "Taiwan's most iconic skyscraper with observation deck.",
                        tips: ["Book tickets online to skip the queue", "Visit at sunset for amazing photos"],
                        estimatedTimeMinutes: 120,
                        order: 0,
                        suggestedTravelMode: .transit,
                        ticketURL: "https://www.taipei-101.com.tw/en/observatory-ticket/",
                        officialWebsiteURL: "https://www.taipei-101.com.tw/en/",
                        requiresTicket: true
                    ),
                    SuggestedDestination(
                        name: "Longshan Temple",
                        nameLocal: "龍山寺",
                        address: "No. 211, Guangzhou Street, Wanhua District",
                        latitude: 25.0372,
                        longitude: 121.4999,
                        description: "One of Taiwan's oldest and most famous temples.",
                        tips: ["Free entry", "Visit early morning for peace"],
                        estimatedTimeMinutes: 60,
                        order: 1,
                        suggestedTravelMode: .transit,
                        officialWebsiteURL: "https://www.lungshan.org.tw/"
                    ),
                    SuggestedDestination(
                        name: "Chiang Kai-shek Memorial Hall",
                        nameLocal: "中正紀念堂",
                        address: "No. 21, Zhongshan South Road",
                        latitude: 25.0349,
                        longitude: 121.5219,
                        description: "Grand memorial with hourly changing of the guard.",
                        tips: ["Watch guard changing on the hour", "Free admission"],
                        estimatedTimeMinutes: 90,
                        order: 2,
                        suggestedTravelMode: .transit,
                        officialWebsiteURL: "https://www.cksmh.gov.tw/en/"
                    ),
                    SuggestedDestination(
                        name: "Shilin Night Market",
                        nameLocal: "士林夜市",
                        address: "No. 101, Jihe Road, Shilin District",
                        latitude: 25.0879,
                        longitude: 121.5243,
                        description: "Taiwan's largest and most famous night market.",
                        tips: ["Try oyster omelette and bubble tea", "Best after 6 PM"],
                        estimatedTimeMinutes: 150,
                        order: 3,
                        suggestedTravelMode: .transit,
                        officialWebsiteURL: "https://www.travel.taipei/en/attraction/details/1538"
                    )
                ],
                highlights: ["Taipei 101 Observatory", "Temple Culture", "Night Market"],
                bestTime: "Start at noon, end at night market",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["must-see", "iconic", "first-time", "taipei"],
                trendingData: TrendingData(
                    trendingScore: 95,
                    socialMentions: 125000,
                    trendDirection: .stable,
                    trendingReason: "Timeless classic",
                    peakSeason: .all,
                    isCurrentlyHot: true
                ),
                bestSeasons: [.all]
            ),
            TripSuggestion(
                name: "Taipei in 3 Days",
                subtitle: "Complete Taipei experience for newcomers",
                description: "The ultimate 3-day itinerary covering Taipei's best attractions, from modern landmarks to historic sites, plus day trips.",
                category: .firstTime,
                duration: .threeDays,
                destinations: [
                    SuggestedDestination(name: "Taipei 101", nameLocal: "台北101", address: "Xinyi District", latitude: 25.0339, longitude: 121.5645, description: "Start at the iconic skyscraper.", tips: ["Pre-book tickets"], estimatedTimeMinutes: 120, order: 0, suggestedTravelMode: .transit, ticketURL: "https://www.taipei-101.com.tw/en/observatory-ticket/", officialWebsiteURL: "https://www.taipei-101.com.tw/en/", requiresTicket: true),
                    SuggestedDestination(name: "Elephant Mountain", nameLocal: "象山", address: "Xinyi District", latitude: 25.0273, longitude: 121.5708, description: "Best photo spot of Taipei 101.", tips: ["20-minute climb", "Go for sunset"], estimatedTimeMinutes: 90, order: 1, suggestedTravelMode: .walking, officialWebsiteURL: "https://www.travel.taipei/en/attraction/details/189"),
                    SuggestedDestination(name: "Raohe Night Market", nameLocal: "饒河夜市", address: "Songshan District", latitude: 25.0510, longitude: 121.5775, description: "Famous for pepper pork buns.", tips: ["Try the pork bun at entrance"], estimatedTimeMinutes: 120, order: 2, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.travel.taipei/en/attraction/details/1543"),
                    SuggestedDestination(name: "National Palace Museum", nameLocal: "國立故宮博物院", address: "Shilin District", latitude: 25.1024, longitude: 121.5485, description: "World's largest Chinese art collection.", tips: ["Book online", "Don't miss Jade Cabbage"], estimatedTimeMinutes: 180, order: 3, suggestedTravelMode: .transit, ticketURL: "https://www.npm.gov.tw/en/Article.aspx?sNo=02000025", officialWebsiteURL: "https://www.npm.gov.tw/en/", requiresTicket: true),
                    SuggestedDestination(name: "Beitou Hot Springs", nameLocal: "北投溫泉", address: "Beitou District", latitude: 25.1365, longitude: 121.5068, description: "Famous hot spring area.", tips: ["Visit Thermal Valley (free)"], estimatedTimeMinutes: 150, order: 4, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.travel.taipei/en/attraction/details/40"),
                    SuggestedDestination(name: "Jiufen Old Street", nameLocal: "九份老街", address: "New Taipei City", latitude: 25.1094, longitude: 121.8444, description: "Charming village that inspired Spirited Away.", tips: ["Go early", "Stay for sunset lanterns"], estimatedTimeMinutes: 180, order: 5, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.newtaipei.travel/en/attraction/detail/110305")
                ],
                highlights: ["Taipei 101", "Palace Museum", "Hot Springs", "Jiufen"],
                bestTime: "Start each day in the morning",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["must-see", "comprehensive", "first-time", "day-trip"],
                trendingData: TrendingData(trendingScore: 88, socialMentions: 89000, trendDirection: .stable, peakSeason: .all),
                bestSeasons: [.all]
            )
        ]
    }

    // MARK: - Cultural

    private static func createCulturalSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Temple & History Trail",
                subtitle: "Explore Taiwan's spiritual heritage",
                description: "Discover the rich religious and cultural heritage through significant temples and historic sites.",
                category: .cultural,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(name: "Longshan Temple", nameLocal: "龍山寺", address: "Wanhua District", latitude: 25.0372, longitude: 121.4999, description: "One of Taiwan's oldest temples.", tips: ["Arrive early"], estimatedTimeMinutes: 60, order: 0, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.lungshan.org.tw/"),
                    SuggestedDestination(name: "Bopiliao Historic Block", nameLocal: "剝皮寮", address: "Wanhua District", latitude: 25.0374, longitude: 121.5020, description: "Preserved Qing Dynasty street.", tips: ["Free admission"], estimatedTimeMinutes: 45, order: 1, suggestedTravelMode: .walking, officialWebsiteURL: "https://www.bopiliao.taipei/"),
                    SuggestedDestination(name: "Confucius Temple", nameLocal: "台北孔廟", address: "Datong District", latitude: 25.0727, longitude: 121.5160, description: "Peaceful temple for the philosopher.", tips: ["Beautiful architecture"], estimatedTimeMinutes: 45, order: 2, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.ct.taipei.gov.tw/en/"),
                    SuggestedDestination(name: "Baoan Temple", nameLocal: "保安宮", address: "Datong District", latitude: 25.0731, longitude: 121.5157, description: "UNESCO Heritage Award winner.", tips: ["Adjacent to Confucius Temple"], estimatedTimeMinutes: 45, order: 3, suggestedTravelMode: .walking, officialWebsiteURL: "https://www.baoan.org.tw/en/")
                ],
                highlights: ["Ancient Temples", "Traditional Architecture"],
                bestTime: "Morning to early afternoon",
                budgetLevel: .budget,
                difficulty: .easy,
                tags: ["temples", "history", "culture"],
                trendingData: TrendingData(trendingScore: 72, socialMentions: 34000, trendDirection: .stable, peakSeason: .spring),
                bestSeasons: [.spring, .autumn]
            )
        ]
    }

    // MARK: - Foodie

    private static func createFoodieSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Ultimate Street Food Tour",
                subtitle: "Eat your way through Taipei",
                description: "Taste the best of Taiwan's legendary street food! From soup dumplings to bubble tea.",
                category: .foodie,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(name: "Yongkang Street", nameLocal: "永康街", address: "Da'an District", latitude: 25.0330, longitude: 121.5299, description: "Foodie paradise with Din Tai Fung.", tips: ["Try xiao long bao", "Mango shaved ice at Ice Monster"], estimatedTimeMinutes: 120, order: 0, suggestedTravelMode: .transit),
                    SuggestedDestination(name: "Addiction Aquatic", nameLocal: "上引水產", address: "Zhongshan District", latitude: 25.0632, longitude: 121.5366, description: "Premium seafood market.", tips: ["Standing sushi bar is amazing"], estimatedTimeMinutes: 90, order: 1, suggestedTravelMode: .transit),
                    SuggestedDestination(name: "Ningxia Night Market", nameLocal: "寧夏夜市", address: "Datong District", latitude: 25.0557, longitude: 121.5153, description: "Best for traditional Taiwanese food.", tips: ["Many Michelin-recommended stalls"], estimatedTimeMinutes: 120, order: 2, suggestedTravelMode: .transit)
                ],
                highlights: ["Xiao Long Bao", "Mango Shaved Ice", "Night Market"],
                bestTime: "Start at lunch, end at night market",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["food", "street-food", "night-market"],
                trendingData: TrendingData(trendingScore: 90, socialMentions: 156000, trendDirection: .rising, trendingReason: "Always a foodie favorite", peakSeason: .all, isCurrentlyHot: true),
                bestSeasons: [.all]
            ),
            TripSuggestion(
                name: "Breakfast & Brunch Crawl",
                subtitle: "Traditional morning delights",
                description: "Experience Taiwan's unique breakfast culture with soy milk shops and dan bing.",
                category: .foodie,
                duration: .halfDay,
                destinations: [
                    SuggestedDestination(name: "Fuhang Soy Milk", nameLocal: "阜杭豆漿", address: "Zhongzheng District", latitude: 25.0445, longitude: 121.5264, description: "Most famous breakfast shop since 1958.", tips: ["Long queue but worth it", "Opens at 5:30 AM"], estimatedTimeMinutes: 60, order: 0, suggestedTravelMode: .transit),
                    SuggestedDestination(name: "Yonghe Soy Milk King", nameLocal: "永和豆漿大王", address: "Multiple locations", latitude: 25.0334, longitude: 121.5172, description: "Classic 24-hour breakfast chain.", tips: ["Open 24 hours"], estimatedTimeMinutes: 45, order: 1, suggestedTravelMode: .transit)
                ],
                highlights: ["Thick Soy Milk", "Dan Bing"],
                bestTime: "Early morning (6-9 AM)",
                budgetLevel: .budget,
                difficulty: .easy,
                tags: ["breakfast", "local", "traditional"],
                trendingData: TrendingData(trendingScore: 78, socialMentions: 67000, trendDirection: .stable, peakSeason: .all),
                bestSeasons: [.all]
            )
        ]
    }

    // MARK: - Nature

    private static func createNatureSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Yangmingshan Day Trip",
                subtitle: "Mountain escape from the city",
                description: "Escape the urban heat with hot springs, volcanic landscapes, and hiking trails.",
                category: .nature,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(name: "Xiaoyoukeng", nameLocal: "小油坑", address: "Yangmingshan National Park", latitude: 25.1758, longitude: 121.5443, description: "Volcanic fumaroles.", tips: ["Strong sulfur smell"], estimatedTimeMinutes: 45, order: 0, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.ymsnp.gov.tw/main_en/"),
                    SuggestedDestination(name: "Qingtiangang Grassland", nameLocal: "擎天崗", address: "Yangmingshan", latitude: 25.1699, longitude: 121.5625, description: "Grassland with water buffalo.", tips: ["Keep distance from buffalo"], estimatedTimeMinutes: 90, order: 1, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.ymsnp.gov.tw/main_en/"),
                    SuggestedDestination(name: "Lengshuikeng Hot Spring", nameLocal: "冷水坑溫泉", address: "Yangmingshan", latitude: 25.1679, longitude: 121.5660, description: "Free public foot bath.", tips: ["Bring a towel"], estimatedTimeMinutes: 60, order: 2, suggestedTravelMode: .walking, officialWebsiteURL: "https://www.ymsnp.gov.tw/main_en/")
                ],
                highlights: ["Volcanic Landscape", "Grassland", "Hot Spring"],
                bestTime: "Morning to afternoon",
                budgetLevel: .budget,
                difficulty: .moderate,
                tags: ["nature", "hiking", "hot-spring"],
                seasonalNote: "Cherry blossoms in February-March",
                trendingData: TrendingData(trendingScore: 82, socialMentions: 45000, trendDirection: .rising, trendingReason: "Flower season approaching", peakSeason: .spring),
                bestSeasons: [.spring, .autumn]
            ),
            TripSuggestion(
                name: "Taroko Gorge Adventure",
                subtitle: "Taiwan's most spectacular natural wonder",
                description: "Journey to the stunning Taroko Gorge with marble cliffs and breathtaking scenery.",
                category: .nature,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(name: "Taroko Visitor Center", nameLocal: "太魯閣遊客中心", address: "Hualien", latitude: 24.1588, longitude: 121.6218, description: "Start here for maps.", tips: ["Check trail conditions"], estimatedTimeMinutes: 30, order: 0, suggestedTravelMode: .driving, officialWebsiteURL: "https://www.taroko.gov.tw/en/"),
                    SuggestedDestination(name: "Swallow Grotto", nameLocal: "燕子口", address: "Taroko", latitude: 24.1738, longitude: 121.5048, description: "Trail through marble cliffs.", tips: ["Wear helmet provided"], estimatedTimeMinutes: 60, order: 1, suggestedTravelMode: .driving, officialWebsiteURL: "https://www.taroko.gov.tw/en/"),
                    SuggestedDestination(name: "Eternal Spring Shrine", nameLocal: "長春祠", address: "Taroko", latitude: 24.1683, longitude: 121.6033, description: "Shrine with waterfall.", tips: ["Stunning photo spot"], estimatedTimeMinutes: 45, order: 2, suggestedTravelMode: .driving, officialWebsiteURL: "https://www.taroko.gov.tw/en/"),
                    SuggestedDestination(name: "Shakadang Trail", nameLocal: "砂卡礑步道", address: "Taroko", latitude: 24.1570, longitude: 121.6154, description: "Trail with turquoise water.", tips: ["4km easy trail"], estimatedTimeMinutes: 120, order: 3, suggestedTravelMode: .driving, officialWebsiteURL: "https://www.taroko.gov.tw/en/")
                ],
                highlights: ["Marble Gorge", "Mountain Scenery"],
                bestTime: "Full day, start early",
                budgetLevel: .moderate,
                difficulty: .moderate,
                tags: ["nature", "national-park", "hiking"],
                seasonalNote: "Check for typhoon closures in summer",
                trendingData: TrendingData(trendingScore: 85, socialMentions: 78000, trendDirection: .stable, peakSeason: .autumn),
                bestSeasons: [.spring, .autumn, .winter]
            )
        ]
    }

    // MARK: - Nightlife

    private static func createNightlifeSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Night Market Hopping",
                subtitle: "Taiwan's legendary night market culture",
                description: "Visit multiple markets for the full variety of street food and local culture.",
                category: .nightlife,
                duration: .halfDay,
                destinations: [
                    SuggestedDestination(name: "Shilin Night Market", nameLocal: "士林夜市", address: "Shilin District", latitude: 25.0879, longitude: 121.5243, description: "Taiwan's largest night market.", tips: ["Underground food court", "Try XXL fried chicken"], estimatedTimeMinutes: 120, order: 0, suggestedTravelMode: .transit),
                    SuggestedDestination(name: "Raohe Night Market", nameLocal: "饒河夜市", address: "Songshan District", latitude: 25.0510, longitude: 121.5775, description: "Famous pepper pork bun.", tips: ["More local than Shilin"], estimatedTimeMinutes: 90, order: 1, suggestedTravelMode: .transit)
                ],
                highlights: ["Street Food", "Local Culture"],
                bestTime: "6 PM onwards",
                budgetLevel: .budget,
                difficulty: .easy,
                tags: ["night-market", "food", "nightlife"],
                trendingData: TrendingData(trendingScore: 88, socialMentions: 134000, trendDirection: .stable, peakSeason: .all, isCurrentlyHot: true),
                bestSeasons: [.all]
            )
        ]
    }

    // MARK: - Trending Now

    private static func createTrendingSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Instagram-Worthy Taipei",
                subtitle: "Most photogenic spots trending on social media",
                description: "Capture the perfect shots at Taipei's most photogenic locations!",
                category: .trending,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(name: "Huashan 1914", nameLocal: "華山1914", address: "Zhongzheng District", latitude: 25.0437, longitude: 121.5285, description: "Renovated winery turned creative hub.", tips: ["Great cafes", "Check for events"], estimatedTimeMinutes: 90, order: 0, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.huashan1914.com/w/huashan1914en/"),
                    SuggestedDestination(name: "Songshan Cultural Park", nameLocal: "松山文創園區", address: "Xinyi District", latitude: 25.0436, longitude: 121.5600, description: "Former tobacco factory, now art space.", tips: ["Japanese-era architecture"], estimatedTimeMinutes: 90, order: 1, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.songshanculturalpark.org/en/"),
                    SuggestedDestination(name: "Dadaocheng Wharf", nameLocal: "大稀埕碼頭", address: "Datong District", latitude: 25.0591, longitude: 121.5064, description: "Perfect for sunset photos.", tips: ["Golden hour is magical"], estimatedTimeMinutes: 60, order: 2, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.travel.taipei/en/attraction/details/1537")
                ],
                highlights: ["Photo Spots", "Creative Parks", "Sunset Views"],
                bestTime: "Afternoon for golden hour",
                budgetLevel: .budget,
                difficulty: .easy,
                tags: ["trending", "instagram", "photography"],
                trendingData: TrendingData(trendingScore: 92, socialMentions: 189000, trendDirection: .rising, trendingReason: "Influencers' favorite spots", peakSeason: .all, isCurrentlyHot: true),
                bestSeasons: [.all]
            ),
            TripSuggestion(
                name: "Cafe Hopping in Taipei",
                subtitle: "Trendy cafes locals love",
                description: "Explore the most aesthetic coffee shops trending among locals.",
                category: .trending,
                duration: .halfDay,
                destinations: [
                    SuggestedDestination(name: "Fujin Tree 353", nameLocal: "富錦樹353", address: "Songshan District", latitude: 25.0601, longitude: 121.5540, description: "Iconic white-washed cafe.", tips: ["Beautiful for photos"], estimatedTimeMinutes: 60, order: 0, suggestedTravelMode: .transit),
                    SuggestedDestination(name: "Simple Kaffa", nameLocal: "興波咖啡", address: "Da'an District", latitude: 25.0393, longitude: 121.5435, description: "World champion barista's cafe.", tips: ["Expect a queue"], estimatedTimeMinutes: 45, order: 1, suggestedTravelMode: .transit),
                    SuggestedDestination(name: "Cafe de Gear", nameLocal: "Cafe de Gear", address: "Zhongshan District", latitude: 25.0529, longitude: 121.5228, description: "Industrial-style cafe.", tips: ["Great pour-over"], estimatedTimeMinutes: 45, order: 2, suggestedTravelMode: .transit)
                ],
                highlights: ["Award-Winning Coffee", "Aesthetic Interiors"],
                bestTime: "Afternoon",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["trending", "cafe", "coffee"],
                trendingData: TrendingData(trendingScore: 86, socialMentions: 98000, trendDirection: .rising, trendingReason: "Coffee culture boom", peakSeason: .all, isCurrentlyHot: true),
                bestSeasons: [.all]
            )
        ]
    }

    // MARK: - Currently Viral (New!)

    private static func createViralSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Tamsui Sunset & Street Food",
                subtitle: "Viral TikTok destination",
                description: "The riverside town that's gone viral! Watch the famous sunset, try iron eggs, and explore the old street.",
                category: .trending,
                duration: .halfDay,
                destinations: [
                    SuggestedDestination(name: "Tamsui Old Street", nameLocal: "淡水老街", address: "Tamsui District", latitude: 25.1697, longitude: 121.4387, description: "Historic street with famous snacks.", tips: ["Try A-gei and iron eggs", "Explore Fisherman's Wharf"], estimatedTimeMinutes: 120, order: 0, suggestedTravelMode: .transit),
                    SuggestedDestination(name: "Lover's Bridge", nameLocal: "情人橋", address: "Fisherman's Wharf", latitude: 25.1817, longitude: 121.4098, description: "Iconic bridge for sunset.", tips: ["Perfect for couples", "Stunning sunset views"], estimatedTimeMinutes: 60, order: 1, suggestedTravelMode: .walking)
                ],
                highlights: ["Sunset Views", "Street Food", "Romantic"],
                bestTime: "Late afternoon for sunset",
                budgetLevel: .budget,
                difficulty: .easy,
                tags: ["trending", "viral", "tiktok", "sunset", "romantic"],
                trendingData: TrendingData(trendingScore: 94, socialMentions: 267000, trendDirection: .rising, trendingReason: "Viral TikTok sunset videos", peakSeason: .summer, isCurrentlyHot: true),
                bestSeasons: [.spring, .summer, .autumn]
            ),
            TripSuggestion(
                name: "Jiufen Night Photography",
                subtitle: "Featured in Netflix shows",
                description: "The magical mountain town at night with lantern-lit streets. Recently featured in popular Netflix travel shows!",
                category: .trending,
                duration: .halfDay,
                destinations: [
                    SuggestedDestination(name: "Jiufen Old Street", nameLocal: "九份老街", address: "Ruifang District", latitude: 25.1094, longitude: 121.8444, description: "Spirited Away inspiration.", tips: ["Arrive at 4 PM for golden hour", "Stay until dark for lanterns"], estimatedTimeMinutes: 180, order: 0, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.newtaipei.travel/en/attraction/detail/110305"),
                    SuggestedDestination(name: "A-Mei Tea House", nameLocal: "阿妹茶樓", address: "Jiufen", latitude: 25.1096, longitude: 121.8452, description: "The iconic tea house.", tips: ["Most photographed building", "Book ahead for tea ceremony"], estimatedTimeMinutes: 60, order: 1, suggestedTravelMode: .walking, officialWebsiteURL: "https://www.amei-teahouse.com/")
                ],
                highlights: ["Lantern Streets", "Tea Houses", "Mountain Views"],
                bestTime: "Arrive 4 PM, stay until night",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["trending", "netflix", "photography", "night"],
                trendingData: TrendingData(trendingScore: 96, socialMentions: 345000, trendDirection: .rising, trendingReason: "Featured on Netflix travel show", peakSeason: .autumn, isCurrentlyHot: true),
                bestSeasons: [.autumn, .winter]
            ),
            TripSuggestion(
                name: "Ximen Youth Culture",
                subtitle: "K-pop & anime shopping paradise",
                description: "Taipei's Harajuku! K-pop stores, anime goods, street performers, and the latest youth fashion trends.",
                category: .trending,
                duration: .halfDay,
                destinations: [
                    SuggestedDestination(name: "Ximending", nameLocal: "西門町", address: "Wanhua District", latitude: 25.0421, longitude: 121.5081, description: "Youth culture hub.", tips: ["K-pop stores everywhere", "Street performers on weekends"], estimatedTimeMinutes: 150, order: 0, suggestedTravelMode: .transit, officialWebsiteURL: "https://www.travel.taipei/en/attraction/details/1548"),
                    SuggestedDestination(name: "Red House", nameLocal: "西門紅樓", address: "Wanhua District", latitude: 25.0420, longitude: 121.5066, description: "Historic building with creative market.", tips: ["LGBTQ+ friendly area", "Weekend craft market"], estimatedTimeMinutes: 60, order: 1, suggestedTravelMode: .walking, officialWebsiteURL: "https://www.redhouse.taipei/en/")
                ],
                highlights: ["K-pop Shopping", "Street Fashion", "Youth Culture"],
                bestTime: "Afternoon to evening",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["trending", "kpop", "anime", "youth", "shopping"],
                trendingData: TrendingData(trendingScore: 89, socialMentions: 178000, trendDirection: .rising, trendingReason: "K-pop tourism boom", peakSeason: .all, isCurrentlyHot: true),
                bestSeasons: [.all]
            ),
            TripSuggestion(
                name: "Matsu Blue Tears",
                subtitle: "Bioluminescent wonder (Seasonal)",
                description: "Witness the magical blue glow of bioluminescent algae! This rare phenomenon only happens April-September.",
                category: .nature,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(name: "Matsu Islands", nameLocal: "馬祖列島", address: "Matsu, Lienchiang County", latitude: 26.1604, longitude: 119.9498, description: "Best location for Blue Tears.", tips: ["Fly from Taipei Songshan Airport", "Best viewing: moonless nights"], estimatedTimeMinutes: 480, order: 0, suggestedTravelMode: .transit)
                ],
                highlights: ["Blue Tears", "Island Scenery", "Night Photography"],
                bestTime: "Night, April-September only",
                budgetLevel: .premium,
                difficulty: .moderate,
                tags: ["trending", "nature", "photography", "seasonal", "viral"],
                seasonalNote: "Only visible April to September. Check tide schedules!",
                trendingData: TrendingData(trendingScore: 98, socialMentions: 423000, trendDirection: .rising, trendingReason: "Viral nature phenomenon videos", peakSeason: .summer, isCurrentlyHot: true),
                bestSeasons: [.summer]
            )
        ]
    }

    // MARK: - Family

    private static func createFamilySuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Family Fun Day",
                subtitle: "Activities kids and parents will love",
                description: "A perfect day out for the whole family with kid-friendly attractions!",
                category: .familyFriendly,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(name: "Taipei Zoo", nameLocal: "台北市立動物園", address: "Wenshan District", latitude: 24.9987, longitude: 121.5809, description: "Asia's largest zoo with pandas.", tips: ["See giant pandas", "Take the zoo train"], estimatedTimeMinutes: 180, order: 0, suggestedTravelMode: .transit, ticketURL: "https://www.zoo.gov.taipei/en/", officialWebsiteURL: "https://www.zoo.gov.taipei/en/", requiresTicket: true),
                    SuggestedDestination(name: "Maokong Gondola", nameLocal: "貓空纜車", address: "Wenshan District", latitude: 24.9983, longitude: 121.5762, description: "Scenic cable car ride.", tips: ["Try crystal cabin (glass floor)"], estimatedTimeMinutes: 120, order: 1, suggestedTravelMode: .walking, ticketURL: "https://www.gondola.taipei/en/", officialWebsiteURL: "https://www.gondola.taipei/en/", requiresTicket: true),
                    SuggestedDestination(name: "Children's Amusement Park", nameLocal: "兒童新樂園", address: "Shilin District", latitude: 25.0969, longitude: 121.5165, description: "Modern amusement park.", tips: ["Affordable rides", "Best for ages 3-12"], estimatedTimeMinutes: 180, order: 2, suggestedTravelMode: .transit, ticketURL: "https://www.tcap.taipei/en/", officialWebsiteURL: "https://www.tcap.taipei/en/", requiresTicket: true)
                ],
                highlights: ["Taipei Zoo", "Gondola Ride", "Amusement Park"],
                bestTime: "Start morning, full day",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["family", "kids", "zoo"],
                trendingData: TrendingData(trendingScore: 80, socialMentions: 56000, trendDirection: .stable, peakSeason: .all),
                bestSeasons: [.spring, .autumn]
            )
        ]
    }
}
