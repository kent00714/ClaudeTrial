import Foundation
import CoreLocation

// MARK: - Hotel Search Service Protocol

protocol HotelSearchServiceProtocol {
    func searchHotels(request: HotelSearchRequest) async throws -> [HotelSearchResult]
    func getHotelDetails(hotelId: String) async throws -> Hotel
    func getPrices(hotelId: String, checkIn: Date, checkOut: Date, guests: Int) async throws -> [HotelPrice]
    func getNearbyHotels(coordinate: CLLocationCoordinate2D, radiusKm: Double) async throws -> [Hotel]
}

// MARK: - Hotel API Configuration

class HotelAPIConfig {
    static let shared = HotelAPIConfig()

    private let defaults = UserDefaults.standard
    private let apiKeyKey = "hotel_api_key"
    private let apiSecretKey = "hotel_api_secret"
    private let providerKey = "hotel_api_provider"

    var apiKey: String? {
        get { defaults.string(forKey: apiKeyKey) }
        set { defaults.set(newValue, forKey: apiKeyKey) }
    }

    var apiSecret: String? {
        get { defaults.string(forKey: apiSecretKey) }
        set { defaults.set(newValue, forKey: apiSecretKey) }
    }

    var provider: HotelAPIProvider {
        get {
            if let raw = defaults.string(forKey: providerKey),
               let provider = HotelAPIProvider(rawValue: raw) {
                return provider
            }
            return .mock
        }
        set { defaults.set(newValue.rawValue, forKey: providerKey) }
    }

    func configure(provider: HotelAPIProvider, apiKey: String, apiSecret: String? = nil) {
        self.provider = provider
        self.apiKey = apiKey
        self.apiSecret = apiSecret
    }
}

enum HotelAPIProvider: String, CaseIterable {
    case mock = "mock"
    case amadeus = "amadeus"  // Free tier: 2,000 calls/month
    case rapidapi = "rapidapi"  // Various hotel APIs

    var displayName: String {
        switch self {
        case .mock: return "Demo Mode"
        case .amadeus: return "Amadeus API"
        case .rapidapi: return "RapidAPI"
        }
    }

    var baseURL: String {
        switch self {
        case .mock: return ""
        case .amadeus: return "https://api.amadeus.com/v1"
        case .rapidapi: return "https://hotels4.p.rapidapi.com"
        }
    }
}

// MARK: - Hotel Search Service (Mock Implementation)

class HotelSearchService: HotelSearchServiceProtocol {

    static let shared = HotelSearchService()

    private let config = HotelAPIConfig.shared

    func searchHotels(request: HotelSearchRequest) async throws -> [HotelSearchResult] {
        // Use real API if configured, otherwise use mock
        switch config.provider {
        case .mock:
            return try await searchHotelsMock(request: request)
        case .amadeus:
            return try await searchHotelsAmadeus(request: request)
        case .rapidapi:
            return try await searchHotelsRapidAPI(request: request)
        }
    }

    func getHotelDetails(hotelId: String) async throws -> Hotel {
        // Mock implementation - return from mock data
        try await Task.sleep(nanoseconds: 300_000_000)

        if let result = mockTaipeiHotels.first(where: { $0.hotel.id == hotelId }) {
            return result.hotel
        }
        throw HotelSearchError.hotelNotFound
    }

    func getPrices(hotelId: String, checkIn: Date, checkOut: Date, guests: Int) async throws -> [HotelPrice] {
        try await Task.sleep(nanoseconds: 500_000_000)

        if let result = mockTaipeiHotels.first(where: { $0.hotel.id == hotelId }) {
            return result.prices
        }
        throw HotelSearchError.hotelNotFound
    }

    func getNearbyHotels(coordinate: CLLocationCoordinate2D, radiusKm: Double) async throws -> [Hotel] {
        try await Task.sleep(nanoseconds: 300_000_000)

        return mockTaipeiHotels
            .map { $0.hotel }
            .filter { hotel in
                let distance = calculateDistance(from: coordinate, to: hotel.coordinate)
                return distance <= radiusKm
            }
    }

    // MARK: - Mock Implementation

    private func searchHotelsMock(request: HotelSearchRequest) async throws -> [HotelSearchResult] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)

        var results = mockTaipeiHotels

        // Filter by stars
        if let minStars = request.minStars {
            results = results.filter { $0.hotel.starRating >= minStars }
        }

        // Filter by max price
        if let maxPrice = request.maxPrice {
            results = results.filter { result in
                result.lowestPrice?.pricePerNight ?? 0 <= maxPrice
            }
        }

        // Sort results
        switch request.sortBy {
        case .recommended:
            results.sort { $0.hotel.userRating > $1.hotel.userRating }
        case .priceLow:
            results.sort { ($0.lowestPrice?.pricePerNight ?? 0) < ($1.lowestPrice?.pricePerNight ?? 0) }
        case .priceHigh:
            results.sort { ($0.lowestPrice?.pricePerNight ?? 0) > ($1.lowestPrice?.pricePerNight ?? 0) }
        case .rating:
            results.sort { $0.hotel.userRating > $1.hotel.userRating }
        case .distance:
            results.sort { ($0.hotel.distanceFromCenter ?? 0) < ($1.hotel.distanceFromCenter ?? 0) }
        case .stars:
            results.sort { $0.hotel.starRating > $1.hotel.starRating }
        }

        return results
    }

    // MARK: - Amadeus API (Placeholder)

    private func searchHotelsAmadeus(request: HotelSearchRequest) async throws -> [HotelSearchResult] {
        guard let apiKey = config.apiKey, let apiSecret = config.apiSecret else {
            throw HotelSearchError.notConfigured
        }

        // TODO: Implement Amadeus API integration
        // 1. Get access token: POST https://api.amadeus.com/v1/security/oauth2/token
        // 2. Search hotels: GET https://api.amadeus.com/v1/reference-data/locations/hotels/by-city
        // 3. Get offers: GET https://api.amadeus.com/v3/shopping/hotel-offers

        // For now, fall back to mock
        print("Amadeus API configured with key: \(apiKey.prefix(8))...")
        return try await searchHotelsMock(request: request)
    }

    // MARK: - RapidAPI (Placeholder)

    private func searchHotelsRapidAPI(request: HotelSearchRequest) async throws -> [HotelSearchResult] {
        guard let apiKey = config.apiKey else {
            throw HotelSearchError.notConfigured
        }

        // TODO: Implement RapidAPI Hotels integration
        // Various providers available: Hotels.com, Booking.com aggregators

        print("RapidAPI configured with key: \(apiKey.prefix(8))...")
        return try await searchHotelsMock(request: request)
    }

    // MARK: - Helper Functions

    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0  // km
    }

    // MARK: - Mock Data for Taiwan Hotels

    private var mockTaipeiHotels: [HotelSearchResult] {
        [
            createHotelResult(
                id: "hotel_grand_hyatt",
                name: "Grand Hyatt Taipei",
                nameLocal: "台北君悅酒店",
                address: "No. 2, Songshou Road, Xinyi District, Taipei",
                latitude: 25.0340,
                longitude: 121.5654,
                stars: 5,
                rating: 9.2,
                reviews: 3456,
                neighborhood: "Xinyi District",
                distance: 0.5,
                amenities: [.wifi, .pool, .gym, .spa, .restaurant, .bar, .roomService, .businessCenter],
                prices: [
                    (provider: .booking, price: 8500, hasBreakfast: true),
                    (provider: .agoda, price: 8200, hasBreakfast: true),
                    (provider: .expedia, price: 8800, hasBreakfast: false),
                    (provider: .direct, price: 9000, hasBreakfast: true)
                ]
            ),
            createHotelResult(
                id: "hotel_w_taipei",
                name: "W Taipei",
                nameLocal: "台北W飯店",
                address: "No. 10, Zhongxiao East Road Section 5, Xinyi District",
                latitude: 25.0388,
                longitude: 121.5667,
                stars: 5,
                rating: 8.9,
                reviews: 2890,
                neighborhood: "Xinyi District",
                distance: 0.3,
                amenities: [.wifi, .pool, .gym, .spa, .restaurant, .bar, .roomService],
                prices: [
                    (provider: .booking, price: 9200, hasBreakfast: false),
                    (provider: .agoda, price: 8900, hasBreakfast: false),
                    (provider: .hotels, price: 9500, hasBreakfast: true)
                ]
            ),
            createHotelResult(
                id: "hotel_regent",
                name: "Regent Taipei",
                nameLocal: "台北晶華酒店",
                address: "No. 3, Lane 39, Section 2, Zhongshan North Road",
                latitude: 25.0528,
                longitude: 121.5228,
                stars: 5,
                rating: 9.0,
                reviews: 4123,
                neighborhood: "Zhongshan District",
                distance: 2.1,
                amenities: [.wifi, .pool, .gym, .spa, .restaurant, .bar, .roomService, .airportShuttle],
                prices: [
                    (provider: .booking, price: 7800, hasBreakfast: true),
                    (provider: .agoda, price: 7500, hasBreakfast: true),
                    (provider: .trip, price: 7600, hasBreakfast: true)
                ]
            ),
            createHotelResult(
                id: "hotel_eslite",
                name: "Eslite Hotel",
                nameLocal: "誠品行旅",
                address: "No. 98, Yanchang Road, Xinyi District",
                latitude: 25.0403,
                longitude: 121.5612,
                stars: 5,
                rating: 9.1,
                reviews: 1567,
                neighborhood: "Songshan Cultural Park",
                distance: 1.2,
                amenities: [.wifi, .gym, .restaurant, .bar, .laundry],
                prices: [
                    (provider: .booking, price: 6800, hasBreakfast: true),
                    (provider: .agoda, price: 6500, hasBreakfast: true),
                    (provider: .direct, price: 7000, hasBreakfast: true)
                ]
            ),
            createHotelResult(
                id: "hotel_amba_songshan",
                name: "amba Taipei Songshan",
                nameLocal: "台北松山意舍酒店",
                address: "No. 8, Section 7, Civic Boulevard, Songshan District",
                latitude: 25.0498,
                longitude: 121.5778,
                stars: 4,
                rating: 8.5,
                reviews: 2341,
                neighborhood: "Raohe Night Market",
                distance: 3.5,
                amenities: [.wifi, .gym, .restaurant, .bar, .laundry],
                prices: [
                    (provider: .booking, price: 4200, hasBreakfast: true),
                    (provider: .agoda, price: 4000, hasBreakfast: true),
                    (provider: .expedia, price: 4500, hasBreakfast: false)
                ]
            ),
            createHotelResult(
                id: "hotel_palais_de_chine",
                name: "Palais de Chine Hotel",
                nameLocal: "君品酒店",
                address: "No. 3, Section 1, Chengde Road, Datong District",
                latitude: 25.0478,
                longitude: 121.5170,
                stars: 5,
                rating: 8.8,
                reviews: 1876,
                neighborhood: "Taipei Main Station",
                distance: 1.8,
                amenities: [.wifi, .gym, .spa, .restaurant, .bar, .roomService, .businessCenter],
                prices: [
                    (provider: .booking, price: 5500, hasBreakfast: true),
                    (provider: .agoda, price: 5200, hasBreakfast: true),
                    (provider: .hotels, price: 5800, hasBreakfast: true)
                ]
            ),
            createHotelResult(
                id: "hotel_citizen_m",
                name: "citizenM Taipei North Gate",
                nameLocal: "世民酒店台北北門",
                address: "No. 3, Zhongxiao West Road Section 1, Zhongzheng District",
                latitude: 25.0461,
                longitude: 121.5103,
                stars: 4,
                rating: 8.7,
                reviews: 987,
                neighborhood: "Beimen",
                distance: 2.0,
                amenities: [.wifi, .gym, .bar, .laundry],
                prices: [
                    (provider: .booking, price: 3800, hasBreakfast: false),
                    (provider: .agoda, price: 3600, hasBreakfast: false),
                    (provider: .direct, price: 3500, hasBreakfast: false)
                ]
            ),
            createHotelResult(
                id: "hotel_okura",
                name: "The Okura Prestige Taipei",
                nameLocal: "大倉久和大飯店",
                address: "No. 9, Section 1, Nanjing East Road, Zhongshan District",
                latitude: 25.0520,
                longitude: 121.5235,
                stars: 5,
                rating: 9.3,
                reviews: 2654,
                neighborhood: "Zhongshan",
                distance: 2.3,
                amenities: [.wifi, .pool, .gym, .spa, .restaurant, .bar, .roomService, .businessCenter, .airportShuttle],
                prices: [
                    (provider: .booking, price: 8800, hasBreakfast: true),
                    (provider: .agoda, price: 8500, hasBreakfast: true),
                    (provider: .trip, price: 8600, hasBreakfast: true)
                ]
            )
        ]
    }

    private func createHotelResult(
        id: String,
        name: String,
        nameLocal: String,
        address: String,
        latitude: Double,
        longitude: Double,
        stars: Int,
        rating: Double,
        reviews: Int,
        neighborhood: String,
        distance: Double,
        amenities: [HotelAmenity],
        prices: [(provider: HotelProvider, price: Double, hasBreakfast: Bool)]
    ) -> HotelSearchResult {
        let hotel = Hotel(
            id: id,
            name: name,
            nameLocal: nameLocal,
            address: address,
            latitude: latitude,
            longitude: longitude,
            starRating: stars,
            userRating: rating,
            reviewCount: reviews,
            thumbnailURL: nil,
            photos: [],
            amenities: amenities,
            description: "Experience exceptional hospitality in the heart of Taipei.",
            checkInTime: "15:00",
            checkOutTime: "11:00",
            distanceFromCenter: distance,
            neighborhood: neighborhood
        )

        let hotelPrices = prices.map { priceInfo in
            HotelPrice(
                id: "\(id)_\(priceInfo.provider.rawValue)",
                hotelId: id,
                roomId: nil,
                provider: priceInfo.provider,
                pricePerNight: priceInfo.price,
                totalPrice: priceInfo.price,  // Single night
                currency: "TWD",
                includesBreakfast: priceInfo.hasBreakfast,
                includesTax: true,
                bookingURL: getBookingURL(provider: priceInfo.provider, hotelName: name),
                lastUpdated: Date()
            )
        }

        return HotelSearchResult(
            id: id,
            hotel: hotel,
            prices: hotelPrices,
            availableRooms: []
        )
    }

    private func getBookingURL(provider: HotelProvider, hotelName: String) -> String {
        let encodedName = hotelName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? hotelName

        switch provider {
        case .booking:
            return "https://www.booking.com/searchresults.html?ss=\(encodedName)"
        case .agoda:
            return "https://www.agoda.com/search?searchtext=\(encodedName)"
        case .expedia:
            return "https://www.expedia.com/Hotel-Search?destination=\(encodedName)"
        case .hotels:
            return "https://www.hotels.com/search.do?q-destination=\(encodedName)"
        case .trip:
            return "https://www.trip.com/hotels/?keyword=\(encodedName)"
        case .direct:
            return "https://www.google.com/search?q=\(encodedName)+official+website"
        }
    }
}

// MARK: - Errors

enum HotelSearchError: LocalizedError {
    case hotelNotFound
    case notConfigured
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .hotelNotFound:
            return "Hotel not found"
        case .notConfigured:
            return "Hotel API not configured. Please set up API credentials."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
