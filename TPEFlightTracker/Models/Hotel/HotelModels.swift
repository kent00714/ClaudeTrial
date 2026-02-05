import Foundation
import CoreLocation

// MARK: - Hotel

struct Hotel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let nameLocal: String?
    let address: String
    let latitude: Double
    let longitude: Double
    let starRating: Int  // 1-5 stars
    let userRating: Double  // 0-10 rating
    let reviewCount: Int
    let thumbnailURL: String?
    let photos: [String]
    let amenities: [HotelAmenity]
    let description: String
    let checkInTime: String  // e.g., "15:00"
    let checkOutTime: String  // e.g., "11:00"
    let distanceFromCenter: Double?  // km from city center
    let neighborhood: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedRating: String {
        String(format: "%.1f", userRating)
    }

    var ratingDescription: String {
        switch userRating {
        case 9.0...: return "Exceptional"
        case 8.0..<9.0: return "Excellent"
        case 7.0..<8.0: return "Very Good"
        case 6.0..<7.0: return "Good"
        default: return "Fair"
        }
    }

    var starRatingDisplay: String {
        String(repeating: "★", count: starRating) + String(repeating: "☆", count: 5 - starRating)
    }
}

// MARK: - Hotel Room

struct HotelRoom: Identifiable, Codable, Equatable {
    let id: String
    let hotelId: String
    let name: String  // e.g., "Deluxe Double Room"
    let description: String
    let maxOccupancy: Int
    let bedType: String  // e.g., "1 King Bed", "2 Twin Beds"
    let roomSize: Int?  // square meters
    let amenities: [String]
    let isRefundable: Bool
    let cancellationPolicy: String?

    var formattedSize: String? {
        guard let size = roomSize else { return nil }
        return "\(size) m²"
    }
}

// MARK: - Hotel Price

struct HotelPrice: Identifiable, Codable, Equatable {
    let id: String
    let hotelId: String
    let roomId: String?
    let provider: HotelProvider
    let pricePerNight: Double
    let totalPrice: Double
    let currency: String
    let includesBreakfast: Bool
    let includesTax: Bool
    let bookingURL: String
    let lastUpdated: Date

    var formattedPricePerNight: String {
        formatPrice(pricePerNight)
    }

    var formattedTotalPrice: String {
        formatPrice(totalPrice)
    }

    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "\(currency) \(Int(price))"
    }
}

// MARK: - Hotel Provider

enum HotelProvider: String, Codable, CaseIterable, Identifiable {
    case booking = "booking"
    case agoda = "agoda"
    case expedia = "expedia"
    case hotels = "hotels"
    case trip = "trip"
    case direct = "direct"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .booking: return "Booking.com"
        case .agoda: return "Agoda"
        case .expedia: return "Expedia"
        case .hotels: return "Hotels.com"
        case .trip: return "Trip.com"
        case .direct: return "Official Site"
        }
    }

    var iconName: String {
        switch self {
        case .booking: return "b.circle.fill"
        case .agoda: return "a.circle.fill"
        case .expedia: return "e.circle.fill"
        case .hotels: return "h.circle.fill"
        case .trip: return "t.circle.fill"
        case .direct: return "building.2.fill"
        }
    }

    var accentColor: String {
        switch self {
        case .booking: return "blue"
        case .agoda: return "red"
        case .expedia: return "yellow"
        case .hotels: return "red"
        case .trip: return "blue"
        case .direct: return "green"
        }
    }
}

// MARK: - Hotel Amenity

enum HotelAmenity: String, Codable, CaseIterable, Identifiable {
    case wifi = "wifi"
    case parking = "parking"
    case pool = "pool"
    case gym = "gym"
    case spa = "spa"
    case restaurant = "restaurant"
    case bar = "bar"
    case roomService = "room_service"
    case airConditioning = "ac"
    case laundry = "laundry"
    case businessCenter = "business"
    case meetingRooms = "meeting"
    case airportShuttle = "shuttle"
    case petFriendly = "pet"
    case nonSmoking = "non_smoking"
    case accessibility = "accessible"
    case breakfast = "breakfast"
    case kitchen = "kitchen"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wifi: return "Free WiFi"
        case .parking: return "Parking"
        case .pool: return "Pool"
        case .gym: return "Fitness Center"
        case .spa: return "Spa"
        case .restaurant: return "Restaurant"
        case .bar: return "Bar"
        case .roomService: return "Room Service"
        case .airConditioning: return "A/C"
        case .laundry: return "Laundry"
        case .businessCenter: return "Business Center"
        case .meetingRooms: return "Meeting Rooms"
        case .airportShuttle: return "Airport Shuttle"
        case .petFriendly: return "Pet Friendly"
        case .nonSmoking: return "Non-Smoking"
        case .accessibility: return "Accessible"
        case .breakfast: return "Breakfast"
        case .kitchen: return "Kitchen"
        }
    }

    var systemImage: String {
        switch self {
        case .wifi: return "wifi"
        case .parking: return "car.fill"
        case .pool: return "figure.pool.swim"
        case .gym: return "dumbbell.fill"
        case .spa: return "sparkles"
        case .restaurant: return "fork.knife"
        case .bar: return "wineglass.fill"
        case .roomService: return "bell.fill"
        case .airConditioning: return "snowflake"
        case .laundry: return "washer.fill"
        case .businessCenter: return "briefcase.fill"
        case .meetingRooms: return "person.3.fill"
        case .airportShuttle: return "bus.fill"
        case .petFriendly: return "pawprint.fill"
        case .nonSmoking: return "nosign"
        case .accessibility: return "figure.roll"
        case .breakfast: return "cup.and.saucer.fill"
        case .kitchen: return "cooktop.fill"
        }
    }
}

// MARK: - Hotel Search Request

struct HotelSearchRequest: Codable, Equatable {
    let location: String  // City name or coordinates
    let latitude: Double?
    let longitude: Double?
    let checkIn: Date
    let checkOut: Date
    let guests: Int
    let rooms: Int
    let minStars: Int?
    let maxPrice: Double?
    let amenities: [HotelAmenity]?
    let sortBy: HotelSortOption

    var nights: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: checkIn, to: checkOut).day ?? 1
        return max(1, days)
    }
}

// MARK: - Hotel Sort Option

enum HotelSortOption: String, Codable, CaseIterable, Identifiable {
    case recommended = "recommended"
    case priceLow = "price_low"
    case priceHigh = "price_high"
    case rating = "rating"
    case distance = "distance"
    case stars = "stars"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recommended: return "Recommended"
        case .priceLow: return "Price: Low to High"
        case .priceHigh: return "Price: High to Low"
        case .rating: return "Guest Rating"
        case .distance: return "Distance"
        case .stars: return "Star Rating"
        }
    }
}

// MARK: - Hotel Search Result

struct HotelSearchResult: Identifiable, Codable, Equatable {
    let id: String
    let hotel: Hotel
    let prices: [HotelPrice]
    let availableRooms: [HotelRoom]

    var lowestPrice: HotelPrice? {
        prices.min(by: { $0.pricePerNight < $1.pricePerNight })
    }

    var highestPrice: HotelPrice? {
        prices.max(by: { $0.pricePerNight < $1.pricePerNight })
    }

    var priceRange: String? {
        guard let low = lowestPrice, let high = highestPrice else { return nil }
        if low.pricePerNight == high.pricePerNight {
            return low.formattedPricePerNight
        }
        return "\(low.formattedPricePerNight) - \(high.formattedPricePerNight)"
    }

    var providerCount: Int {
        Set(prices.map { $0.provider }).count
    }
}

// MARK: - Saved Hotel

struct SavedHotel: Identifiable, Codable, Equatable {
    let id: UUID
    let hotel: Hotel
    let savedAt: Date
    let notes: String
    let tripId: UUID?  // Optional link to a trip

    init(id: UUID = UUID(), hotel: Hotel, savedAt: Date = Date(), notes: String = "", tripId: UUID? = nil) {
        self.id = id
        self.hotel = hotel
        self.savedAt = savedAt
        self.notes = notes
        self.tripId = tripId
    }
}
