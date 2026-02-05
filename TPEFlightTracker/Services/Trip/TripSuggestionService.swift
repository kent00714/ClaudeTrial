import Foundation

// MARK: - Protocol

protocol TripSuggestionServiceProtocol {
    func getAllSuggestions() -> [TripSuggestion]
    func getSuggestions(for category: SuggestionCategory) -> [TripSuggestion]
    func getSuggestions(for duration: TripDuration) -> [TripSuggestion]
    func getTrendingSuggestions() -> [TripSuggestion]
    func getRecommendedForFirstTimers() -> [TripSuggestion]
    func searchSuggestions(query: String) -> [TripSuggestion]
}

// MARK: - Service

class TripSuggestionService: TripSuggestionServiceProtocol {

    private let suggestions: [TripSuggestion]

    init() {
        self.suggestions = TripSuggestionService.createCuratedSuggestions()
    }

    func getAllSuggestions() -> [TripSuggestion] {
        suggestions
    }

    func getSuggestions(for category: SuggestionCategory) -> [TripSuggestion] {
        suggestions.filter { $0.category == category }
    }

    func getSuggestions(for duration: TripDuration) -> [TripSuggestion] {
        suggestions.filter { $0.duration == duration }
    }

    func getTrendingSuggestions() -> [TripSuggestion] {
        suggestions.filter { $0.category == .trending || $0.tags.contains("trending") }
    }

    func getRecommendedForFirstTimers() -> [TripSuggestion] {
        suggestions.filter { $0.category == .firstTime || $0.tags.contains("must-see") }
    }

    func searchSuggestions(query: String) -> [TripSuggestion] {
        let lowercased = query.lowercased()
        return suggestions.filter { suggestion in
            suggestion.name.lowercased().contains(lowercased) ||
            suggestion.description.lowercased().contains(lowercased) ||
            suggestion.tags.contains { $0.lowercased().contains(lowercased) } ||
            suggestion.destinations.contains { $0.name.lowercased().contains(lowercased) }
        }
    }

    // MARK: - Curated Suggestions

    private static func createCuratedSuggestions() -> [TripSuggestion] {
        var suggestions: [TripSuggestion] = []

        // First Time Visitors
        suggestions.append(contentsOf: createFirstTimeSuggestions())

        // Cultural
        suggestions.append(contentsOf: createCulturalSuggestions())

        // Foodie
        suggestions.append(contentsOf: createFoodieSuggestions())

        // Nature
        suggestions.append(contentsOf: createNatureSuggestions())

        // Nightlife
        suggestions.append(contentsOf: createNightlifeSuggestions())

        // Trending
        suggestions.append(contentsOf: createTrendingSuggestions())

        // Family
        suggestions.append(contentsOf: createFamilySuggestions())

        return suggestions
    }

    // MARK: - First Time Visitors

    private static func createFirstTimeSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Essential Taipei",
                subtitle: "The must-see Taipei experience",
                description: "Perfect introduction to Taipei! Visit the iconic Taipei 101, explore traditional temples, and experience the vibrant night market culture. This itinerary covers all the highlights that make Taipei special.",
                category: .firstTime,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(
                        name: "Taipei 101",
                        nameLocal: "台北101",
                        address: "No. 7, Section 5, Xinyi Road, Xinyi District",
                        latitude: 25.0339,
                        longitude: 121.5645,
                        description: "Taiwan's most iconic skyscraper with observation deck offering stunning city views.",
                        tips: ["Book observation deck tickets online to skip the queue", "Visit at sunset for amazing photos", "The food court in the basement has great options"],
                        estimatedTimeMinutes: 120,
                        order: 0,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Longshan Temple",
                        nameLocal: "龍山寺",
                        address: "No. 211, Guangzhou Street, Wanhua District",
                        latitude: 25.0372,
                        longitude: 121.4999,
                        description: "One of Taiwan's oldest and most famous temples, built in 1738.",
                        tips: ["Free entry, donations welcome", "Visit early morning for a peaceful experience", "Respect worshippers and dress modestly"],
                        estimatedTimeMinutes: 60,
                        order: 1,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Chiang Kai-shek Memorial Hall",
                        nameLocal: "中正紀念堂",
                        address: "No. 21, Zhongshan South Road, Zhongzheng District",
                        latitude: 25.0349,
                        longitude: 121.5219,
                        description: "Grand memorial with beautiful gardens and hourly changing of the guard ceremony.",
                        tips: ["Watch the guard changing ceremony on the hour", "The Liberty Square is beautiful at sunset", "Free admission"],
                        estimatedTimeMinutes: 90,
                        order: 2,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Shilin Night Market",
                        nameLocal: "士林夜市",
                        address: "No. 101, Jihe Road, Shilin District",
                        latitude: 25.0879,
                        longitude: 121.5243,
                        description: "Taiwan's largest and most famous night market with endless food and shopping.",
                        tips: ["Come hungry! Try oyster omelette, stinky tofu, and bubble tea", "Bargaining is expected at clothing stalls", "Best visited after 6 PM"],
                        estimatedTimeMinutes: 150,
                        order: 3,
                        suggestedTravelMode: .transit
                    )
                ],
                highlights: ["Taipei 101 Observatory", "Traditional Temple Culture", "Night Market Experience"],
                bestTime: "Start at noon, end at night market",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["must-see", "iconic", "first-time", "taipei"]
            ),

            TripSuggestion(
                name: "Taipei in 3 Days",
                subtitle: "Complete Taipei experience for newcomers",
                description: "The ultimate 3-day itinerary covering Taipei's best attractions, from modern landmarks to historic sites, plus day trips to nearby attractions. Perfect for first-time visitors who want to see it all!",
                category: .firstTime,
                duration: .threeDays,
                destinations: [
                    // Day 1: City Center
                    SuggestedDestination(
                        name: "Taipei 101",
                        nameLocal: "台北101",
                        address: "No. 7, Section 5, Xinyi Road, Xinyi District",
                        latitude: 25.0339,
                        longitude: 121.5645,
                        description: "Start your Taiwan journey at the iconic skyscraper.",
                        tips: ["Pre-book tickets for the observation deck"],
                        estimatedTimeMinutes: 120,
                        order: 0,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Elephant Mountain",
                        nameLocal: "象山",
                        address: "Xinyi District",
                        latitude: 25.0273,
                        longitude: 121.5708,
                        description: "Short hike for the best photos of Taipei 101 and the city skyline.",
                        tips: ["About 20-minute climb", "Go before sunset for the best photos"],
                        estimatedTimeMinutes: 90,
                        order: 1,
                        suggestedTravelMode: .walking
                    ),
                    SuggestedDestination(
                        name: "Raohe Night Market",
                        nameLocal: "饒河夜市",
                        address: "Raohe Street, Songshan District",
                        latitude: 25.0510,
                        longitude: 121.5775,
                        description: "One of Taipei's oldest night markets with amazing local food.",
                        tips: ["Try the famous pepper pork bun at the entrance", "Less crowded than Shilin"],
                        estimatedTimeMinutes: 120,
                        order: 2,
                        suggestedTravelMode: .transit
                    ),
                    // Day 2: Culture & History
                    SuggestedDestination(
                        name: "National Palace Museum",
                        nameLocal: "國立故宮博物院",
                        address: "No. 221, Section 2, Zhishan Road, Shilin District",
                        latitude: 25.1024,
                        longitude: 121.5485,
                        description: "World's largest collection of Chinese art and artifacts.",
                        tips: ["Book tickets online", "Don't miss the Jade Cabbage", "Audio guide available in many languages"],
                        estimatedTimeMinutes: 180,
                        order: 3,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Beitou Hot Springs",
                        nameLocal: "北投溫泉",
                        address: "Beitou District",
                        latitude: 25.1365,
                        longitude: 121.5068,
                        description: "Famous hot spring area with public and private baths.",
                        tips: ["Visit Thermal Valley (free)", "Many hotels offer day-use hot spring packages"],
                        estimatedTimeMinutes: 150,
                        order: 4,
                        suggestedTravelMode: .transit
                    ),
                    // Day 3: Day Trip
                    SuggestedDestination(
                        name: "Jiufen Old Street",
                        nameLocal: "九份老街",
                        address: "Jiufen, Ruifang District, New Taipei City",
                        latitude: 25.1094,
                        longitude: 121.8444,
                        description: "Charming mountain village that inspired Spirited Away.",
                        tips: ["Go early to avoid crowds", "Try taro balls and fish ball soup", "Stay for sunset and lantern lighting"],
                        estimatedTimeMinutes: 180,
                        order: 5,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Shifen Waterfall",
                        nameLocal: "十分瀑布",
                        address: "Shifen, Pingxi District, New Taipei City",
                        latitude: 25.0464,
                        longitude: 121.7785,
                        description: "Taiwan's widest waterfall, known as 'Little Niagara'.",
                        tips: ["Release a sky lantern at Shifen Old Street", "Combine with Jiufen for a full day trip"],
                        estimatedTimeMinutes: 90,
                        order: 6,
                        suggestedTravelMode: .transit
                    )
                ],
                highlights: ["Taipei 101", "Palace Museum", "Hot Springs", "Jiufen Village", "Shifen Waterfall"],
                bestTime: "Start each day in the morning",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["must-see", "comprehensive", "first-time", "day-trip"]
            )
        ]
    }

    // MARK: - Cultural Suggestions

    private static func createCulturalSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Temple & History Trail",
                subtitle: "Explore Taiwan's spiritual heritage",
                description: "Discover the rich religious and cultural heritage of Taiwan through its most significant temples and historic sites. A peaceful journey through centuries of tradition.",
                category: .cultural,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(
                        name: "Longshan Temple",
                        nameLocal: "龍山寺",
                        address: "No. 211, Guangzhou Street, Wanhua District",
                        latitude: 25.0372,
                        longitude: 121.4999,
                        description: "One of Taiwan's oldest and most revered temples.",
                        tips: ["Arrive early for morning prayers", "Free fortune sticks available"],
                        estimatedTimeMinutes: 60,
                        order: 0,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Bopiliao Historic Block",
                        nameLocal: "剝皮寮歷史街區",
                        address: "No. 173, Kangding Road, Wanhua District",
                        latitude: 25.0374,
                        longitude: 121.5020,
                        description: "Preserved Qing Dynasty street with traditional architecture.",
                        tips: ["Free admission", "Great for photography"],
                        estimatedTimeMinutes: 45,
                        order: 1,
                        suggestedTravelMode: .walking
                    ),
                    SuggestedDestination(
                        name: "Confucius Temple",
                        nameLocal: "台北孔廟",
                        address: "No. 275, Dalong Street, Datong District",
                        latitude: 25.0727,
                        longitude: 121.5160,
                        description: "Peaceful temple dedicated to the great philosopher.",
                        tips: ["Free admission", "Beautiful traditional architecture"],
                        estimatedTimeMinutes: 45,
                        order: 2,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Dalongdong Baoan Temple",
                        nameLocal: "大龍峒保安宮",
                        address: "No. 61, Hami Street, Datong District",
                        latitude: 25.0731,
                        longitude: 121.5157,
                        description: "UNESCO Asia-Pacific Heritage Award winning temple.",
                        tips: ["Impressive traditional craftsmanship", "Adjacent to Confucius Temple"],
                        estimatedTimeMinutes: 45,
                        order: 3,
                        suggestedTravelMode: .walking
                    )
                ],
                highlights: ["Ancient Temples", "Traditional Architecture", "Spiritual Experience"],
                bestTime: "Morning to early afternoon",
                budgetLevel: .budget,
                difficulty: .easy,
                tags: ["temples", "history", "culture", "peaceful"]
            )
        ]
    }

    // MARK: - Foodie Suggestions

    private static func createFoodieSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Ultimate Street Food Tour",
                subtitle: "Eat your way through Taipei",
                description: "Taste the best of Taiwan's legendary street food scene! From soup dumplings to bubble tea, this tour takes you to the most delicious spots in the city.",
                category: .foodie,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(
                        name: "Yongkang Street",
                        nameLocal: "永康街",
                        address: "Yongkang Street, Da'an District",
                        latitude: 25.0330,
                        longitude: 121.5299,
                        description: "Foodie paradise with Din Tai Fung and famous mango shaved ice.",
                        tips: ["Try xiao long bao at Din Tai Fung", "Smoothie House has amazing mango shaved ice", "Ice Monster for snow ice"],
                        estimatedTimeMinutes: 120,
                        order: 0,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Addiction Aquatic Development",
                        nameLocal: "上引水產",
                        address: "No. 18, Alley 2, Lane 410, Minzu East Road",
                        latitude: 25.0632,
                        longitude: 121.5366,
                        description: "Premium seafood market with standing sushi bars and fresh catches.",
                        tips: ["Come for lunch, standing sushi bar is popular", "Fresh sashimi at market prices"],
                        estimatedTimeMinutes: 90,
                        order: 1,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Ningxia Night Market",
                        nameLocal: "寧夏夜市",
                        address: "Ningxia Road, Datong District",
                        latitude: 25.0557,
                        longitude: 121.5153,
                        description: "Best night market for traditional Taiwanese food.",
                        tips: ["Try oyster omelette, taro balls, and lu rou fan", "Smaller and more local than Shilin", "Many Michelin-recommended stalls"],
                        estimatedTimeMinutes: 120,
                        order: 2,
                        suggestedTravelMode: .transit
                    )
                ],
                highlights: ["Xiao Long Bao", "Mango Shaved Ice", "Night Market Delicacies"],
                bestTime: "Start at lunch, end at night market",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["food", "street-food", "night-market", "must-try"]
            ),

            TripSuggestion(
                name: "Breakfast & Brunch Crawl",
                subtitle: "Traditional morning delights",
                description: "Start your day like a local! Experience Taiwan's unique breakfast culture with soy milk shops, dan bing (egg crepes), and traditional rice rolls.",
                category: .foodie,
                duration: .halfDay,
                destinations: [
                    SuggestedDestination(
                        name: "Fuhang Soy Milk",
                        nameLocal: "阜杭豆漿",
                        address: "No. 108, Section 1, Zhongxiao East Road",
                        latitude: 25.0445,
                        longitude: 121.5264,
                        description: "Taipei's most famous traditional breakfast shop since 1958.",
                        tips: ["Long queue but worth it", "Try thick soy milk and shao bing you tiao", "Opens at 5:30 AM"],
                        estimatedTimeMinutes: 60,
                        order: 0,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Yonghe Soy Milk King",
                        nameLocal: "永和豆漿大王",
                        address: "Multiple locations",
                        latitude: 25.0334,
                        longitude: 121.5172,
                        description: "Classic 24-hour breakfast chain for dan bing and rice rolls.",
                        tips: ["Open 24 hours", "Perfect for late-night breakfast cravings"],
                        estimatedTimeMinutes: 45,
                        order: 1,
                        suggestedTravelMode: .transit
                    )
                ],
                highlights: ["Thick Soy Milk", "Dan Bing", "Shao Bing You Tiao"],
                bestTime: "Early morning (6-9 AM)",
                budgetLevel: .budget,
                difficulty: .easy,
                tags: ["breakfast", "local", "traditional", "early-bird"]
            )
        ]
    }

    // MARK: - Nature Suggestions

    private static func createNatureSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Yangmingshan Day Trip",
                subtitle: "Mountain escape from the city",
                description: "Escape the urban heat and explore Taipei's backyard mountain! Hot springs, volcanic landscapes, and beautiful hiking trails await.",
                category: .nature,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(
                        name: "Xiaoyoukeng",
                        nameLocal: "小油坑",
                        address: "Yangmingshan National Park",
                        latitude: 25.1758,
                        longitude: 121.5443,
                        description: "Dramatic volcanic fumaroles with sulfur vents.",
                        tips: ["Free admission", "Strong sulfur smell - avoid if sensitive", "Great photo opportunity"],
                        estimatedTimeMinutes: 45,
                        order: 0,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Qingtiangang Grassland",
                        nameLocal: "擎天崗草原",
                        address: "Yangmingshan National Park",
                        latitude: 25.1699,
                        longitude: 121.5625,
                        description: "Beautiful grassland with roaming water buffalo.",
                        tips: ["Easy flat walk", "Keep distance from buffalo", "Bring a picnic"],
                        estimatedTimeMinutes: 90,
                        order: 1,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Lengshuikeng Hot Spring",
                        nameLocal: "冷水坑溫泉",
                        address: "Yangmingshan National Park",
                        latitude: 25.1679,
                        longitude: 121.5660,
                        description: "Free public hot spring foot bath.",
                        tips: ["Bring a towel", "Free foot bath", "Milk pond nearby"],
                        estimatedTimeMinutes: 60,
                        order: 2,
                        suggestedTravelMode: .walking
                    )
                ],
                highlights: ["Volcanic Landscape", "Grassland Hiking", "Free Hot Spring"],
                bestTime: "Morning to afternoon",
                budgetLevel: .budget,
                difficulty: .moderate,
                tags: ["nature", "hiking", "hot-spring", "day-trip"]
            ),

            TripSuggestion(
                name: "Taroko Gorge Adventure",
                subtitle: "Taiwan's most spectacular natural wonder",
                description: "Journey to the stunning Taroko Gorge on Taiwan's east coast. Marble cliffs, suspension bridges, and breathtaking mountain scenery await.",
                category: .nature,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(
                        name: "Taroko Visitor Center",
                        nameLocal: "太魯閣遊客中心",
                        address: "Taroko National Park, Hualien",
                        latitude: 24.1588,
                        longitude: 121.6218,
                        description: "Start here for maps and trail information.",
                        tips: ["Get trail permits if needed", "Check trail conditions"],
                        estimatedTimeMinutes: 30,
                        order: 0,
                        suggestedTravelMode: .driving
                    ),
                    SuggestedDestination(
                        name: "Swallow Grotto Trail",
                        nameLocal: "燕子口步道",
                        address: "Taroko National Park",
                        latitude: 24.1738,
                        longitude: 121.5048,
                        description: "Stunning trail through marble cliffs with cave formations.",
                        tips: ["Wear a helmet (provided)", "Watch for falling rocks", "Best marble gorge views"],
                        estimatedTimeMinutes: 60,
                        order: 1,
                        suggestedTravelMode: .driving
                    ),
                    SuggestedDestination(
                        name: "Eternal Spring Shrine",
                        nameLocal: "長春祠",
                        address: "Taroko National Park",
                        latitude: 24.1683,
                        longitude: 121.6033,
                        description: "Beautiful shrine with waterfall, memorial to highway builders.",
                        tips: ["Easy walk from parking", "Stunning photo spot", "Learn about highway history"],
                        estimatedTimeMinutes: 45,
                        order: 2,
                        suggestedTravelMode: .driving
                    ),
                    SuggestedDestination(
                        name: "Shakadang Trail",
                        nameLocal: "砂卡礑步道",
                        address: "Taroko National Park",
                        latitude: 24.1570,
                        longitude: 121.6154,
                        description: "Riverside trail with crystal-clear turquoise water.",
                        tips: ["4km easy trail", "Swimming not allowed but beautiful", "Best for photography"],
                        estimatedTimeMinutes: 120,
                        order: 3,
                        suggestedTravelMode: .driving
                    )
                ],
                highlights: ["Marble Gorge", "Suspension Bridges", "Mountain Scenery"],
                bestTime: "Full day, start early",
                budgetLevel: .moderate,
                difficulty: .moderate,
                tags: ["nature", "national-park", "hiking", "scenic"],
                seasonalNote: "Check for typhoon closures during summer months"
            )
        ]
    }

    // MARK: - Nightlife Suggestions

    private static func createNightlifeSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Night Market Hopping",
                subtitle: "Experience Taiwan's night market culture",
                description: "Taiwan's night markets are legendary! Visit multiple markets in one evening to experience the full variety of street food, games, and local culture.",
                category: .nightlife,
                duration: .halfDay,
                destinations: [
                    SuggestedDestination(
                        name: "Shilin Night Market",
                        nameLocal: "士林夜市",
                        address: "No. 101, Jihe Road, Shilin District",
                        latitude: 25.0879,
                        longitude: 121.5243,
                        description: "Taiwan's largest and most famous night market.",
                        tips: ["Underground food court for local favorites", "Bargain at clothing stalls", "Try XXL fried chicken"],
                        estimatedTimeMinutes: 120,
                        order: 0,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Raohe Night Market",
                        nameLocal: "饒河夜市",
                        address: "Raohe Street, Songshan District",
                        latitude: 25.0510,
                        longitude: 121.5775,
                        description: "Historic night market with famous pepper pork bun.",
                        tips: ["Pepper pork bun at entrance is must-try", "More local feel than Shilin"],
                        estimatedTimeMinutes: 90,
                        order: 1,
                        suggestedTravelMode: .transit
                    )
                ],
                highlights: ["Street Food", "Local Culture", "Shopping"],
                bestTime: "6 PM onwards",
                budgetLevel: .budget,
                difficulty: .easy,
                tags: ["night-market", "food", "shopping", "nightlife"]
            )
        ]
    }

    // MARK: - Trending Suggestions

    private static func createTrendingSuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Instagram-Worthy Taipei",
                subtitle: "Most photogenic spots in the city",
                description: "Discover Taipei's most photogenic locations that are trending on social media. From colorful streets to modern architecture, capture the perfect shots!",
                category: .trending,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(
                        name: "Rainbow Village",
                        nameLocal: "彩虹眷村",
                        address: "No. 56, Chun'an Road, Nantun District, Taichung",
                        latitude: 24.1340,
                        longitude: 120.6080,
                        description: "Colorful painted village created by a 97-year-old veteran.",
                        tips: ["Best photos in morning light", "Small area, 30 min is enough", "Support the artist's story"],
                        estimatedTimeMinutes: 45,
                        order: 0,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Huashan 1914 Creative Park",
                        nameLocal: "華山1914文化創意產業園區",
                        address: "No. 1, Section 1, Bade Road, Zhongzheng District",
                        latitude: 25.0437,
                        longitude: 121.5285,
                        description: "Renovated winery turned creative arts hub.",
                        tips: ["Great cafes and art exhibitions", "Check for special events", "Night time has nice atmosphere"],
                        estimatedTimeMinutes: 90,
                        order: 1,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Songshan Cultural Park",
                        nameLocal: "松山文創園區",
                        address: "No. 133, Guangfu South Road, Xinyi District",
                        latitude: 25.0436,
                        longitude: 121.5600,
                        description: "Former tobacco factory now a design and art space.",
                        tips: ["Beautiful Japanese-era architecture", "Design shops and exhibitions", "Next to Eslite bookstore"],
                        estimatedTimeMinutes: 90,
                        order: 2,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Dadaocheng Wharf",
                        nameLocal: "大稻埕碼頭",
                        address: "Dadaocheng Wharf, Datong District",
                        latitude: 25.0591,
                        longitude: 121.5064,
                        description: "Riverside promenade perfect for sunset photos.",
                        tips: ["Golden hour is magical", "Rent a YouBike to ride along river", "Night view of city skyline"],
                        estimatedTimeMinutes: 60,
                        order: 3,
                        suggestedTravelMode: .transit
                    )
                ],
                highlights: ["Photo Spots", "Creative Parks", "Sunset Views"],
                bestTime: "Start afternoon for golden hour at wharf",
                budgetLevel: .budget,
                difficulty: .easy,
                tags: ["trending", "instagram", "photography", "creative"]
            ),

            TripSuggestion(
                name: "Cafe Hopping in Taipei",
                subtitle: "Trendy cafes locals love",
                description: "Taipei's cafe scene is booming! Explore the most aesthetic and delicious coffee shops that are trending among locals and visitors alike.",
                category: .trending,
                duration: .halfDay,
                destinations: [
                    SuggestedDestination(
                        name: "Fujin Tree 353 Cafe",
                        nameLocal: "富錦樹353咖啡",
                        address: "No. 353, Fujin Street, Songshan District",
                        latitude: 25.0601,
                        longitude: 121.5540,
                        description: "Iconic white-washed cafe in the trendy Fujin Street area.",
                        tips: ["Beautiful for photos", "Try their brunch menu", "Explore nearby boutiques"],
                        estimatedTimeMinutes: 60,
                        order: 0,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Simple Kaffa",
                        nameLocal: "興波咖啡",
                        address: "No. 36, Lane 223, Section 1, Fuxing South Road",
                        latitude: 25.0393,
                        longitude: 121.5435,
                        description: "World champion barista's flagship cafe.",
                        tips: ["Expect a queue", "Award-winning coffee", "Try their signature drinks"],
                        estimatedTimeMinutes: 45,
                        order: 1,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Cafe de Gear",
                        nameLocal: "Cafe de Gear",
                        address: "No. 3, Lane 27, Section 2, Zhongshan North Road",
                        latitude: 25.0529,
                        longitude: 121.5228,
                        description: "Industrial-style cafe popular with coffee enthusiasts.",
                        tips: ["Great pour-over coffee", "Motorcycle theme interior", "Local favorite"],
                        estimatedTimeMinutes: 45,
                        order: 2,
                        suggestedTravelMode: .transit
                    )
                ],
                highlights: ["Award-Winning Coffee", "Aesthetic Interiors", "Local Favorites"],
                bestTime: "Afternoon",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["trending", "cafe", "coffee", "instagram"]
            )
        ]
    }

    // MARK: - Family Suggestions

    private static func createFamilySuggestions() -> [TripSuggestion] {
        [
            TripSuggestion(
                name: "Family Fun Day",
                subtitle: "Activities kids and parents will love",
                description: "A perfect day out for the whole family! Kid-friendly attractions, interactive experiences, and delicious food everyone can enjoy.",
                category: .familyFriendly,
                duration: .fullDay,
                destinations: [
                    SuggestedDestination(
                        name: "Taipei Zoo",
                        nameLocal: "台北市立動物園",
                        address: "No. 30, Section 2, Xinguang Road, Wenshan District",
                        latitude: 24.9987,
                        longitude: 121.5809,
                        description: "Asia's largest zoo with pandas, koalas, and more.",
                        tips: ["See giant pandas at Panda House", "Take the zoo train", "Combine with Maokong Gondola"],
                        estimatedTimeMinutes: 180,
                        order: 0,
                        suggestedTravelMode: .transit
                    ),
                    SuggestedDestination(
                        name: "Maokong Gondola",
                        nameLocal: "貓空纜車",
                        address: "No. 8, Lane 115, Section 3, Xinguang Road",
                        latitude: 24.9983,
                        longitude: 121.5762,
                        description: "Scenic cable car ride to tea plantation mountain.",
                        tips: ["Crystal cabin for brave kids (glass floor)", "Tea houses at the top", "Beautiful city views"],
                        estimatedTimeMinutes: 120,
                        order: 1,
                        suggestedTravelMode: .walking
                    ),
                    SuggestedDestination(
                        name: "Taipei Children's Amusement Park",
                        nameLocal: "台北市立兒童新樂園",
                        address: "No. 55, Section 5, Chengde Road, Shilin District",
                        latitude: 25.0969,
                        longitude: 121.5165,
                        description: "Modern amusement park designed for children.",
                        tips: ["Affordable rides", "Best for ages 3-12", "Indoor and outdoor attractions"],
                        estimatedTimeMinutes: 180,
                        order: 2,
                        suggestedTravelMode: .transit
                    )
                ],
                highlights: ["Taipei Zoo", "Gondola Ride", "Amusement Park"],
                bestTime: "Start morning, full day",
                budgetLevel: .moderate,
                difficulty: .easy,
                tags: ["family", "kids", "zoo", "fun"]
            )
        ]
    }
}
