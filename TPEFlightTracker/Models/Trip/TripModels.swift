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
    /// URL scheme for deep linking
    static let urlScheme = "tpetracker"

    /// Generate a shareable deep link URL for this trip
    var shareableLink: URL? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(self)
            let base64String = jsonData.base64EncodedString()

            // URL-safe base64 encoding
            let urlSafeBase64 = base64String
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")

            var components = URLComponents()
            components.scheme = Trip.urlScheme
            components.host = "trip"
            components.queryItems = [URLQueryItem(name: "data", value: urlSafeBase64)]

            return components.url
        } catch {
            return nil
        }
    }

    /// Import trip from a shareable link URL
    static func importFromLink(_ url: URL) throws -> Trip {
        guard url.scheme == urlScheme,
              url.host == "trip",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let dataItem = components.queryItems?.first(where: { $0.name == "data" }),
              let base64String = dataItem.value else {
            throw TripImportError.invalidURL
        }

        // Convert URL-safe base64 back to standard
        var standardBase64 = base64String
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        let paddingLength = (4 - standardBase64.count % 4) % 4
        standardBase64 += String(repeating: "=", count: paddingLength)

        guard let data = Data(base64Encoded: standardBase64) else {
            throw TripImportError.invalidData
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Trip.self, from: data)
    }

    /// Generate shareable text with the trip link
    var shareableTextWithLink: String {
        var text = shareableText

        if let link = shareableLink {
            text += "\n\nOpen in TPE Flight Tracker:\n\(link.absoluteString)"
        }

        return text
    }

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

enum TripImportError: Error, LocalizedError {
    case invalidURL
    case invalidData
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The shared link is not valid."
        case .invalidData:
            return "Could not decode the trip data."
        case .decodingFailed:
            return "Failed to import the trip. The data may be corrupted."
        }
    }
}

enum TravelMode: String, Codable, CaseIterable, Identifiable {
    case driving
    case walking
    case bicycling
    case transit
    case taxi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .driving: return "Driving"
        case .walking: return "Walking"
        case .bicycling: return "Bicycling"
        case .transit: return "Transit"
        case .taxi: return "Taxi"
        }
    }

    var systemImage: String {
        switch self {
        case .driving: return "car.fill"
        case .walking: return "figure.walk"
        case .bicycling: return "bicycle"
        case .transit: return "bus.fill"
        case .taxi: return "car.side.fill"
        }
    }

    var googleMapsMode: String {
        rawValue
    }

    /// Whether this mode supports booking
    var supportsBooking: Bool {
        self == .taxi
    }
}
