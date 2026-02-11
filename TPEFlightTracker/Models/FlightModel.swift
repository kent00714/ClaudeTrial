import Foundation

enum FlightDirection: String, CaseIterable, Identifiable {
    case arrival = "Arrivals"
    case departure = "Departures"

    var id: String { rawValue }
}

enum FlightStatus: String, Codable {
    case scheduled = "Scheduled"
    case boarding = "Boarding"
    case departed = "Departed"
    case inAir = "In Air"
    case landed = "Landed"
    case arrived = "Arrived"
    case delayed = "Delayed"
    case cancelled = "Cancelled"
    case active = "Active"
    case diverted = "Diverted"
    case unknown = "Unknown"

    var color: String {
        switch self {
        case .scheduled: return "gray"
        case .boarding: return "blue"
        case .departed, .inAir: return "green"
        case .landed, .arrived: return "green"
        case .delayed: return "orange"
        case .cancelled: return "red"
        case .active: return "blue"
        case .diverted: return "purple"
        case .unknown: return "gray"
        }
    }

    var displayName: String {
        return rawValue
    }
}

struct Flight: Identifiable, Codable {
    let id: String
    let flightNumber: String
    let airline: String
    let airlineLogo: String
    let direction: String
    let origin: Airport
    let destination: Airport
    let scheduledTime: Date
    let estimatedTime: Date?
    let actualTime: Date?
    let status: FlightStatus
    let terminal: String
    let gate: String?
    let aircraft: String?
    let codeshares: [String]

    var isArrival: Bool {
        direction == "arrival"
    }

    var isDeparture: Bool {
        direction == "departure"
    }

    var counterpartCity: String {
        isArrival ? origin.city : destination.city
    }

    var counterpartIATA: String {
        isArrival ? origin.iata : destination.iata
    }

    var displayTime: Date {
        actualTime ?? estimatedTime ?? scheduledTime
    }

    var isDelayed: Bool {
        status == .delayed
    }

    var departureAirport: String {
        origin.iata
    }

    var departureCity: String {
        origin.city
    }

    var arrivalAirport: String {
        destination.iata
    }

    var arrivalCity: String {
        destination.city
    }
}

struct Airport: Codable {
    let iata: String
    let name: String
    let city: String
}
