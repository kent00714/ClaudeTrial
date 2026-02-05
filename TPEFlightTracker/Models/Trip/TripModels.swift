import Foundation
import CoreLocation

struct Trip: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var destinations: [TripDestination]
    var createdAt: Date
    var updatedAt: Date
    var notes: String
    var sourceSuggestionName: String?  // Track if this trip came from a suggestion

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        destinations: [TripDestination] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        notes: String = "",
        sourceSuggestionName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.destinations = destinations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
        self.sourceSuggestionName = sourceSuggestionName
    }

    var isFromSuggestion: Bool {
        sourceSuggestionName != nil
    }

    var totalDestinations: Int {
        destinations.count
    }

    var totalDurationMinutes: Int {
        destinations.compactMap(\.travelDurationMinutes).reduce(0, +)
    }

    var totalDistanceMeters: Int {
        destinations.compactMap(\.travelDistanceMeters).reduce(0, +)
    }

    var formattedTotalDistance: String {
        let km = Double(totalDistanceMeters) / 1000.0
        if km >= 1 {
            return String(format: "%.1f km", km)
        } else {
            return "\(totalDistanceMeters) m"
        }
    }

    var formattedTotalDuration: String {
        let hours = totalDurationMinutes / 60
        let minutes = totalDurationMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}

struct TripDestination: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var plannedArrival: Date?
    var plannedDeparture: Date?
    var notes: String
    var order: Int
    var estimatedStayMinutes: Int?  // How long to spend at this destination
    var tips: [String]              // Tips for this destination

    // Travel info from previous destination (calculated)
    var travelDurationMinutes: Int?
    var travelDistanceMeters: Int?
    var travelMode: TravelMode

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        plannedArrival: Date? = nil,
        plannedDeparture: Date? = nil,
        notes: String = "",
        order: Int = 0,
        estimatedStayMinutes: Int? = nil,
        tips: [String] = [],
        travelDurationMinutes: Int? = nil,
        travelDistanceMeters: Int? = nil,
        travelMode: TravelMode = .driving
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.plannedArrival = plannedArrival
        self.plannedDeparture = plannedDeparture
        self.notes = notes
        self.order = order
        self.estimatedStayMinutes = estimatedStayMinutes
        self.tips = tips
        self.travelDurationMinutes = travelDurationMinutes
        self.travelDistanceMeters = travelDistanceMeters
        self.travelMode = travelMode
    }

    var formattedEstimatedStay: String? {
        guard let minutes = estimatedStayMinutes else { return nil }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(mins) min"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedTravelDistance: String? {
        guard let meters = travelDistanceMeters else { return nil }
        let km = Double(meters) / 1000.0
        if km >= 1 {
            return String(format: "%.1f km", km)
        } else {
            return "\(meters) m"
        }
    }

    var formattedTravelDuration: String? {
        guard let minutes = travelDurationMinutes else { return nil }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins) min"
        }
    }
}

enum TravelMode: String, Codable, CaseIterable, Identifiable {
    case driving
    case walking
    case bicycling
    case transit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .driving: return "Driving"
        case .walking: return "Walking"
        case .bicycling: return "Bicycling"
        case .transit: return "Transit"
        }
    }

    var systemImage: String {
        switch self {
        case .driving: return "car.fill"
        case .walking: return "figure.walk"
        case .bicycling: return "bicycle"
        case .transit: return "bus.fill"
        }
    }

    var googleMapsMode: String {
        rawValue
    }
}
