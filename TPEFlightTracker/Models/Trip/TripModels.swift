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
    var linkedFlightNumber: String?    // Flight number to track (e.g., "CI123")

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        destinations: [TripDestination] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        notes: String = "",
        sourceSuggestionName: String? = nil,
        linkedFlightNumber: String? = nil
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
        self.linkedFlightNumber = linkedFlightNumber
    }

    var isFromSuggestion: Bool {
        sourceSuggestionName != nil
    }

    var hasLinkedFlight: Bool {
        guard let flight = linkedFlightNumber else { return false }
        return !flight.isEmpty
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

// MARK: - Trip Sharing Extensions

extension Trip {
    /// Generate a shareable text summary of the trip
    var shareableText: String {
        var text = "📍 \(name)\n"
        text += "📅 \(formattedDateRange)\n"

        if hasLinkedFlight, let flight = linkedFlightNumber {
            text += "✈️ Flight: \(flight)\n"
        }

        if !destinations.isEmpty {
            text += "\n🗺️ Itinerary (\(totalDestinations) stops):\n"
            for (index, dest) in destinations.enumerated() {
                text += "\(index + 1). \(dest.name)"
                if let stay = dest.formattedEstimatedStay {
                    text += " (\(stay))"
                }
                text += "\n"
            }
        }

        if totalDistanceMeters > 0 || totalDurationMinutes > 0 {
            text += "\n📊 Total: "
            if totalDistanceMeters > 0 {
                text += formattedTotalDistance
            }
            if totalDurationMinutes > 0 {
                text += totalDistanceMeters > 0 ? " • " : ""
                text += formattedTotalDuration
            }
            text += "\n"
        }

        if !notes.isEmpty {
            text += "\n📝 Notes: \(notes)\n"
        }

        if isFromSuggestion, let source = sourceSuggestionName {
            text += "\n✨ Based on: \(source)"
        }

        text += "\n\n— Shared from TPE Flight Tracker"

        return text
    }

    private var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if Calendar.current.isDate(startDate, equalTo: endDate, toGranularity: .day) {
            return formatter.string(from: startDate)
        }
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    /// Export trip as JSON data
    func exportAsJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    /// Import trip from JSON data
    static func importFromJSON(_ data: Data) throws -> Trip {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Trip.self, from: data)
    }

    /// Generate filename for export
    var exportFilename: String {
        let sanitizedName = name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return "trip_\(sanitizedName)_\(formatter.string(from: startDate)).json"
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
