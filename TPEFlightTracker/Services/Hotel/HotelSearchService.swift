import Foundation
import CoreLocation

// MARK: - Hotel Search Service

protocol HotelSearchServiceProtocol {
    func searchHotels(
        near coordinate: CLLocationCoordinate2D,
        radiusKm: Double,
        sortBy: HotelSortOption
    ) -> [HotelSearchResult]

    func searchHotels(
        in area: String,
        sortBy: HotelSortOption
    ) -> [HotelSearchResult]

    func generateBookingLinks(for hotel: Hotel) -> [BookingLink]
}

class HotelSearchService: HotelSearchServiceProtocol {

    static let shared = HotelSearchService()

    // MARK: - Search Hotels Near Location

    func searchHotels(
        near coordinate: CLLocationCoordinate2D,
        radiusKm: Double = 5.0,
        sortBy: HotelSortOption = .rating
    ) -> [HotelSearchResult] {
        var results = allTaiwanHotels.map { hotel -> HotelSearchResult in
            let distance = calculateDistance(from: coordinate, to: hotel.coordinate)
            return HotelSearchResult(
                id: hotel.id,
                hotel: hotel,
                distanceKm: distance,
                bookingLinks: generateBookingLinks(for: hotel)
            )
        }

        // Filter by radius
        results = results.filter { $0.distanceKm <= radiusKm }

        // Sort results
        switch sortBy {
        case .distance:
            results.sort { $0.distanceKm < $1.distanceKm }
        case .rating:
            results.sort { $0.hotel.rating > $1.hotel.rating }
        case .ratingCount:
            results.sort { $0.hotel.reviewCount > $1.hotel.reviewCount }
        case .priceEstimate:
            results.sort { $0.hotel.priceLevel < $1.hotel.priceLevel }
        }

        return results
    }

    func searchHotels(
        in area: String,
        sortBy: HotelSortOption = .rating
    ) -> [HotelSearchResult] {
        let lowercased = area.lowercased()

        var results = allTaiwanHotels
            .filter { hotel in
                hotel.area.lowercased().contains(lowercased) ||
                hotel.name.lowercased().contains(lowercased) ||
                hotel.nameLocal.lowercased().contains(lowercased) ||
                hotel.neighborhood.lowercased().contains(lowercased)
            }
            .map { hotel -> HotelSearchResult in
                HotelSearchResult(
                    id: hotel.id,
                    hotel: hotel,
                    distanceKm: 0,
                    bookingLinks: generateBookingLinks(for: hotel)
                )
            }

        // Sort results
        switch sortBy {
        case .distance:
            break // No distance when searching by area
        case .rating:
            results.sort { $0.hotel.rating > $1.hotel.rating }
        case .ratingCount:
            results.sort { $0.hotel.reviewCount > $1.hotel.reviewCount }
        case .priceEstimate:
            results.sort { $0.hotel.priceLevel < $1.hotel.priceLevel }
        }

        return results
    }

    // MARK: - Generate Booking Links

    func generateBookingLinks(for hotel: Hotel) -> [BookingLink] {
        let encodedName = hotel.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? hotel.name
        let encodedArea = hotel.area.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? hotel.area

        return [
            BookingLink(
                provider: .googleMaps,
                url: "https://www.google.com/maps/search/\(encodedName)+\(encodedArea)",
                label: "View on Google Maps"
            ),
            BookingLink(
                provider: .booking,
                url: "https://www.booking.com/searchresults.html?ss=\(encodedName)+\(encodedArea)",
                label: "Search on Booking.com"
            ),
            BookingLink(
                provider: .agoda,
                url: "https://www.agoda.com/search?searchtext=\(encodedName)+\(encodedArea)",
                label: "Search on Agoda"
            ),
            BookingLink(
                provider: .expedia,
                url: "https://www.expedia.com/Hotel-Search?destination=\(encodedName)+\(encodedArea)",
                label: "Search on Expedia"
            ),
            BookingLink(
                provider: .trip,
                url: "https://www.trip.com/hotels/?keyword=\(encodedName)",
                label: "Search on Trip.com"
            )
        ]
    }

    // MARK: - Helper

    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0
    }

    // MARK: - Taiwan Hotels Data (Curated)

    private var allTaiwanHotels: [Hotel] {
        [
            // Taipei - Xinyi District
            Hotel(id: "grand_hyatt", name: "Grand Hyatt Taipei", nameLocal: "台北君悅酒店",
                  area: "Taipei", neighborhood: "Xinyi District", address: "No. 2, Songshou Road",
                  latitude: 25.0340, longitude: 121.5654,
                  rating: 4.6, reviewCount: 12453, starRating: 5, priceLevel: 4,
                  amenities: ["Pool", "Spa", "Gym", "Restaurant", "Bar", "WiFi"]),

            Hotel(id: "w_taipei", name: "W Taipei", nameLocal: "台北W飯店",
                  area: "Taipei", neighborhood: "Xinyi District", address: "No. 10, Zhongxiao East Road Sec 5",
                  latitude: 25.0388, longitude: 121.5667,
                  rating: 4.5, reviewCount: 8932, starRating: 5, priceLevel: 4,
                  amenities: ["Pool", "Spa", "Gym", "Restaurant", "Bar", "WiFi"]),

            Hotel(id: "humble_house", name: "Humble House Taipei", nameLocal: "寒舍艾麗酒店",
                  area: "Taipei", neighborhood: "Xinyi District", address: "No. 18, Songgao Road",
                  latitude: 25.0365, longitude: 121.5678,
                  rating: 4.4, reviewCount: 5621, starRating: 5, priceLevel: 4,
                  amenities: ["Gym", "Restaurant", "Bar", "WiFi"]),

            // Taipei - Zhongshan District
            Hotel(id: "regent", name: "Regent Taipei", nameLocal: "台北晶華酒店",
                  area: "Taipei", neighborhood: "Zhongshan District", address: "No. 3, Lane 39, Sec 2, Zhongshan N Rd",
                  latitude: 25.0528, longitude: 121.5228,
                  rating: 4.6, reviewCount: 15234, starRating: 5, priceLevel: 4,
                  amenities: ["Pool", "Spa", "Gym", "Restaurant", "Bar", "WiFi"]),

            Hotel(id: "okura", name: "The Okura Prestige Taipei", nameLocal: "大倉久和大飯店",
                  area: "Taipei", neighborhood: "Zhongshan District", address: "No. 9, Sec 1, Nanjing E Rd",
                  latitude: 25.0520, longitude: 121.5235,
                  rating: 4.7, reviewCount: 9876, starRating: 5, priceLevel: 4,
                  amenities: ["Pool", "Spa", "Gym", "Restaurant", "Bar", "WiFi"]),

            Hotel(id: "ambassador", name: "Ambassador Hotel Taipei", nameLocal: "台北國賓大飯店",
                  area: "Taipei", neighborhood: "Zhongshan District", address: "No. 63, Sec 2, Zhongshan N Rd",
                  latitude: 25.0535, longitude: 121.5220,
                  rating: 4.3, reviewCount: 7654, starRating: 5, priceLevel: 3,
                  amenities: ["Pool", "Gym", "Restaurant", "WiFi"]),

            // Taipei - Datong/Beimen
            Hotel(id: "palais_de_chine", name: "Palais de Chine Hotel", nameLocal: "君品酒店",
                  area: "Taipei", neighborhood: "Taipei Main Station", address: "No. 3, Sec 1, Chengde Rd",
                  latitude: 25.0478, longitude: 121.5170,
                  rating: 4.5, reviewCount: 6543, starRating: 5, priceLevel: 3,
                  amenities: ["Spa", "Gym", "Restaurant", "Bar", "WiFi"]),

            Hotel(id: "citizen_m", name: "citizenM Taipei North Gate", nameLocal: "世民酒店台北北門",
                  area: "Taipei", neighborhood: "Beimen", address: "No. 3, Zhongxiao W Rd Sec 1",
                  latitude: 25.0461, longitude: 121.5103,
                  rating: 4.4, reviewCount: 3456, starRating: 4, priceLevel: 2,
                  amenities: ["Gym", "Bar", "WiFi"]),

            // Taipei - Songshan
            Hotel(id: "amba_songshan", name: "amba Taipei Songshan", nameLocal: "台北松山意舍酒店",
                  area: "Taipei", neighborhood: "Raohe Night Market", address: "No. 8, Sec 7, Civic Blvd",
                  latitude: 25.0498, longitude: 121.5778,
                  rating: 4.3, reviewCount: 4532, starRating: 4, priceLevel: 2,
                  amenities: ["Gym", "Restaurant", "Bar", "WiFi"]),

            Hotel(id: "eslite", name: "Eslite Hotel", nameLocal: "誠品行旅",
                  area: "Taipei", neighborhood: "Songshan Cultural Park", address: "No. 98, Yanchang Rd",
                  latitude: 25.0403, longitude: 121.5612,
                  rating: 4.6, reviewCount: 5678, starRating: 5, priceLevel: 3,
                  amenities: ["Gym", "Restaurant", "WiFi"]),

            // Taipei - Wanhua/Ximending
            Hotel(id: "just_sleep_ximending", name: "Just Sleep Ximending", nameLocal: "捷絲旅西門町館",
                  area: "Taipei", neighborhood: "Ximending", address: "No. 41, Sec 2, Wuchang St",
                  latitude: 25.0425, longitude: 121.5075,
                  rating: 4.2, reviewCount: 6789, starRating: 3, priceLevel: 2,
                  amenities: ["WiFi", "Laundry"]),

            Hotel(id: "amba_ximending", name: "amba Taipei Ximending", nameLocal: "台北西門町意舍酒店",
                  area: "Taipei", neighborhood: "Ximending", address: "No. 77, Wuchang St Sec 2",
                  latitude: 25.0430, longitude: 121.5068,
                  rating: 4.3, reviewCount: 5432, starRating: 4, priceLevel: 2,
                  amenities: ["Gym", "Restaurant", "Bar", "WiFi"]),

            // Taipei - Beitou
            Hotel(id: "grand_view_beitou", name: "Grand View Resort Beitou", nameLocal: "北投麗禧溫泉酒店",
                  area: "Taipei", neighborhood: "Beitou Hot Springs", address: "No. 30, Youya Rd",
                  latitude: 25.1372, longitude: 121.5089,
                  rating: 4.5, reviewCount: 3456, starRating: 5, priceLevel: 4,
                  amenities: ["Hot Spring", "Spa", "Restaurant", "WiFi"]),

            Hotel(id: "asia_pacific_beitou", name: "Asia Pacific Hotel Beitou", nameLocal: "北投亞太飯店",
                  area: "Taipei", neighborhood: "Beitou Hot Springs", address: "No. 31, Youya Rd",
                  latitude: 25.1368, longitude: 121.5085,
                  rating: 4.4, reviewCount: 2345, starRating: 4, priceLevel: 3,
                  amenities: ["Hot Spring", "Spa", "Pool", "Restaurant", "WiFi"]),

            // New Taipei - Jiufen area
            Hotel(id: "jiufen_teahouse_hotel", name: "Jiufen Jin Shan Lou", nameLocal: "九份金山樓",
                  area: "Jiufen", neighborhood: "Jiufen Old Street", address: "No. 19, Jishan St",
                  latitude: 25.1095, longitude: 121.8447,
                  rating: 4.3, reviewCount: 1234, starRating: 3, priceLevel: 2,
                  amenities: ["Mountain View", "WiFi"]),

            // Taichung
            Hotel(id: "lalu_sun_moon", name: "The Lalu Sun Moon Lake", nameLocal: "日月潭涵碧樓",
                  area: "Sun Moon Lake", neighborhood: "Nantou", address: "No. 142, Zhongxing Rd",
                  latitude: 23.8608, longitude: 120.9167,
                  rating: 4.7, reviewCount: 5678, starRating: 5, priceLevel: 5,
                  amenities: ["Pool", "Spa", "Lake View", "Restaurant", "WiFi"]),

            Hotel(id: "fleur_de_chine", name: "Fleur de Chine Hotel", nameLocal: "日月潭雲品酒店",
                  area: "Sun Moon Lake", neighborhood: "Nantou", address: "No. 23, Zhongzheng Rd",
                  latitude: 23.8612, longitude: 120.9245,
                  rating: 4.5, reviewCount: 4532, starRating: 5, priceLevel: 4,
                  amenities: ["Pool", "Spa", "Lake View", "Restaurant", "WiFi"]),

            // Hualien - Taroko
            Hotel(id: "silks_place_taroko", name: "Silks Place Taroko", nameLocal: "太魯閣晶英酒店",
                  area: "Taroko", neighborhood: "Hualien", address: "No. 18, Tianxiang Rd",
                  latitude: 24.1820, longitude: 121.4895,
                  rating: 4.6, reviewCount: 3456, starRating: 5, priceLevel: 4,
                  amenities: ["Pool", "Spa", "Mountain View", "Restaurant", "WiFi"]),

            Hotel(id: "taroko_village", name: "Leader Village Taroko", nameLocal: "太魯閣山月村",
                  area: "Taroko", neighborhood: "Hualien", address: "No. 231-1, Fushi Village",
                  latitude: 24.1652, longitude: 121.5012,
                  rating: 4.4, reviewCount: 2345, starRating: 4, priceLevel: 3,
                  amenities: ["Mountain View", "Restaurant", "Cultural Experience", "WiFi"]),

            // Kaohsiung
            Hotel(id: "chateau_de_chine_kaohsiung", name: "Chateau de Chine Kaohsiung", nameLocal: "高雄翰品酒店",
                  area: "Kaohsiung", neighborhood: "Yancheng District", address: "No. 33, Dayong Rd",
                  latitude: 22.6245, longitude: 120.2835,
                  rating: 4.4, reviewCount: 4567, starRating: 5, priceLevel: 3,
                  amenities: ["Pool", "Gym", "Restaurant", "WiFi"]),

            Hotel(id: "h2o_kaohsiung", name: "H2O Hotel", nameLocal: "高雄水京棧國際酒店",
                  area: "Kaohsiung", neighborhood: "Lingya District", address: "No. 11, Linhai 2nd Rd",
                  latitude: 22.6178, longitude: 120.3012,
                  rating: 4.3, reviewCount: 3456, starRating: 4, priceLevel: 3,
                  amenities: ["Pool", "Gym", "Restaurant", "WiFi"]),

            // Tainan
            Hotel(id: "silks_place_tainan", name: "Silks Place Tainan", nameLocal: "台南晶英酒店",
                  area: "Tainan", neighborhood: "West Central District", address: "No. 1, Heyi Rd Sec 1",
                  latitude: 22.9912, longitude: 120.1965,
                  rating: 4.5, reviewCount: 5678, starRating: 5, priceLevel: 3,
                  amenities: ["Pool", "Gym", "Restaurant", "WiFi"]),

            Hotel(id: "tayih_landis_tainan", name: "Tayih Landis Hotel Tainan", nameLocal: "台南大億麗緻酒店",
                  area: "Tainan", neighborhood: "West Central District", address: "No. 660, Sec 1, Ximen Rd",
                  latitude: 22.9923, longitude: 120.1978,
                  rating: 4.3, reviewCount: 3456, starRating: 5, priceLevel: 3,
                  amenities: ["Gym", "Restaurant", "WiFi"])
        ]
    }
}

// MARK: - Hotel Model (Simplified)

struct Hotel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let nameLocal: String
    let area: String
    let neighborhood: String
    let address: String
    let latitude: Double
    let longitude: Double
    let rating: Double      // Google Maps rating (1-5)
    let reviewCount: Int
    let starRating: Int     // Hotel star rating (1-5)
    let priceLevel: Int     // 1-5 ($ to $$$$$)
    let amenities: [String]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedRating: String {
        String(format: "%.1f", rating)
    }

    var starDisplay: String {
        String(repeating: "★", count: starRating)
    }

    var priceLevelDisplay: String {
        String(repeating: "$", count: priceLevel)
    }

    var ratingDescription: String {
        switch rating {
        case 4.5...: return "Excellent"
        case 4.0..<4.5: return "Very Good"
        case 3.5..<4.0: return "Good"
        default: return "Fair"
        }
    }
}

// MARK: - Hotel Search Result

struct HotelSearchResult: Identifiable, Equatable {
    let id: String
    let hotel: Hotel
    let distanceKm: Double
    let bookingLinks: [BookingLink]

    var formattedDistance: String {
        if distanceKm < 1 {
            return "\(Int(distanceKm * 1000)) m"
        }
        return String(format: "%.1f km", distanceKm)
    }

    static func == (lhs: HotelSearchResult, rhs: HotelSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Booking Link

struct BookingLink: Identifiable, Equatable {
    let id = UUID()
    let provider: BookingProvider
    let url: String
    let label: String
}

enum BookingProvider: String, CaseIterable {
    case googleMaps = "google_maps"
    case booking = "booking"
    case agoda = "agoda"
    case expedia = "expedia"
    case trip = "trip"

    var displayName: String {
        switch self {
        case .googleMaps: return "Google Maps"
        case .booking: return "Booking.com"
        case .agoda: return "Agoda"
        case .expedia: return "Expedia"
        case .trip: return "Trip.com"
        }
    }

    var iconName: String {
        switch self {
        case .googleMaps: return "map.fill"
        case .booking: return "b.circle.fill"
        case .agoda: return "a.circle.fill"
        case .expedia: return "e.circle.fill"
        case .trip: return "t.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .googleMaps: return "green"
        case .booking: return "blue"
        case .agoda: return "red"
        case .expedia: return "yellow"
        case .trip: return "blue"
        }
    }
}

// MARK: - Sort Option

enum HotelSortOption: String, CaseIterable, Identifiable {
    case rating = "rating"
    case distance = "distance"
    case ratingCount = "reviews"
    case priceEstimate = "price"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rating: return "Rating"
        case .distance: return "Distance"
        case .ratingCount: return "Most Reviews"
        case .priceEstimate: return "Price (Low to High)"
        }
    }

    var systemImage: String {
        switch self {
        case .rating: return "star.fill"
        case .distance: return "location.fill"
        case .ratingCount: return "text.bubble.fill"
        case .priceEstimate: return "dollarsign.circle.fill"
        }
    }
}
