import Foundation
import CoreLocation

// MARK: - Taxi Booking Model

struct TaxiBooking: Identifiable, Codable, Equatable {
    let id: UUID
    var pickupLocation: TaxiLocation
    var dropoffLocation: TaxiLocation
    var scheduledTime: Date
    var passengerCount: Int
    var notes: String
    var status: TaxiBookingStatus
    var linkedTripId: UUID?        // Link to a trip if booked from trip
    var linkedDestinationId: UUID? // Link to specific destination in trip
    var estimatedFare: Int?        // Estimated fare in TWD
    var estimatedDuration: Int?    // Estimated duration in minutes
    var driverName: String?
    var driverPhone: String?
    var vehiclePlate: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        pickupLocation: TaxiLocation,
        dropoffLocation: TaxiLocation,
        scheduledTime: Date,
        passengerCount: Int = 1,
        notes: String = "",
        status: TaxiBookingStatus = .pending,
        linkedTripId: UUID? = nil,
        linkedDestinationId: UUID? = nil,
        estimatedFare: Int? = nil,
        estimatedDuration: Int? = nil,
        driverName: String? = nil,
        driverPhone: String? = nil,
        vehiclePlate: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.scheduledTime = scheduledTime
        self.passengerCount = passengerCount
        self.notes = notes
        self.status = status
        self.linkedTripId = linkedTripId
        self.linkedDestinationId = linkedDestinationId
        self.estimatedFare = estimatedFare
        self.estimatedDuration = estimatedDuration
        self.driverName = driverName
        self.driverPhone = driverPhone
        self.vehiclePlate = vehiclePlate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isUpcoming: Bool {
        scheduledTime > Date() && status != .cancelled && status != .completed
    }

    var isPast: Bool {
        scheduledTime <= Date() || status == .completed || status == .cancelled
    }

    var formattedFare: String? {
        guard let fare = estimatedFare else { return nil }
        return "NT$\(fare)"
    }

    var formattedDuration: String? {
        guard let minutes = estimatedDuration else { return nil }
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes) min"
    }
}

// MARK: - Taxi Location

struct TaxiLocation: Codable, Equatable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(name: String, address: String, latitude: Double, longitude: Double) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from destination: TripDestination) {
        self.name = destination.name
        self.address = destination.address
        self.latitude = destination.latitude
        self.longitude = destination.longitude
    }
}

// MARK: - Booking Status

enum TaxiBookingStatus: String, Codable, CaseIterable, Identifiable {
    case pending      // Waiting for confirmation
    case confirmed    // Driver assigned
    case driverEnRoute // Driver on the way
    case arrived      // Driver arrived at pickup
    case inProgress   // Trip in progress
    case completed    // Trip completed
    case cancelled    // Booking cancelled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .driverEnRoute: return "Driver En Route"
        case .arrived: return "Driver Arrived"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var displayNameChinese: String {
        switch self {
        case .pending: return "待確認"
        case .confirmed: return "已確認"
        case .driverEnRoute: return "司機前往中"
        case .arrived: return "司機已到達"
        case .inProgress: return "行程中"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        }
    }

    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle"
        case .driverEnRoute: return "car.fill"
        case .arrived: return "mappin.circle.fill"
        case .inProgress: return "arrow.triangle.turn.up.right.circle.fill"
        case .completed: return "flag.checkered"
        case .cancelled: return "xmark.circle"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "blue"
        case .driverEnRoute: return "purple"
        case .arrived: return "green"
        case .inProgress: return "blue"
        case .completed: return "green"
        case .cancelled: return "red"
        }
    }

    var isActive: Bool {
        switch self {
        case .pending, .confirmed, .driverEnRoute, .arrived, .inProgress:
            return true
        case .completed, .cancelled:
            return false
        }
    }
}

// MARK: - Fare Estimation

struct TaxiFareEstimate {
    let baseFare: Int        // Base fare (起步價)
    let distanceFare: Int    // Distance-based fare
    let timeFare: Int        // Time-based fare (for traffic)
    let nightSurcharge: Int  // Night surcharge if applicable
    let totalFare: Int

    static func estimate(distanceMeters: Int, durationMinutes: Int, isNightTime: Bool = false) -> TaxiFareEstimate {
        // Taiwan taxi fare calculation (approximate)
        // Base fare: NT$85 for first 1.25km
        // NT$5 per 250m after that
        // Night surcharge (23:00-06:00): +20%

        let baseFare = 85
        let distanceKm = Double(distanceMeters) / 1000.0

        var distanceFare = 0
        if distanceKm > 1.25 {
            let extraDistance = distanceKm - 1.25
            distanceFare = Int(extraDistance / 0.25) * 5
        }

        // Time fare for slow traffic (every 3 minutes stopped adds NT$5)
        let timeFare = (durationMinutes / 3) * 5

        var subtotal = baseFare + distanceFare + timeFare
        var nightSurcharge = 0

        if isNightTime {
            nightSurcharge = Int(Double(subtotal) * 0.2)
        }

        let totalFare = subtotal + nightSurcharge

        return TaxiFareEstimate(
            baseFare: baseFare,
            distanceFare: distanceFare,
            timeFare: timeFare,
            nightSurcharge: nightSurcharge,
            totalFare: totalFare
        )
    }
}
