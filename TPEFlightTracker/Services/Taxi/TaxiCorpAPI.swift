import Foundation
import CoreLocation

// MARK: - Taxi Corp API Protocol

/// Protocol defining the interface for taxi fleet API integration.
/// Implement this protocol to connect to your taxi dispatch system.
protocol TaxiCorpAPIProtocol {

    // MARK: - Booking Operations

    /// Request a new taxi booking
    /// - Parameters:
    ///   - request: The booking request details
    /// - Returns: Booking confirmation with assigned booking ID
    func requestBooking(_ request: TaxiBookingRequest) async throws -> TaxiBookingResponse

    /// Cancel an existing booking
    /// - Parameter bookingId: The booking ID to cancel
    /// - Returns: Cancellation confirmation
    func cancelBooking(bookingId: String) async throws -> TaxiCancellationResponse

    /// Get current status of a booking
    /// - Parameter bookingId: The booking ID to query
    /// - Returns: Current booking status and details
    func getBookingStatus(bookingId: String) async throws -> TaxiBookingStatusResponse

    /// Update booking details (e.g., pickup time, passenger count)
    /// - Parameters:
    ///   - bookingId: The booking ID to update
    ///   - update: The fields to update
    /// - Returns: Updated booking confirmation
    func updateBooking(bookingId: String, update: TaxiBookingUpdate) async throws -> TaxiBookingResponse

    // MARK: - Driver Operations

    /// Get assigned driver information
    /// - Parameter bookingId: The booking ID
    /// - Returns: Driver details including name, phone, vehicle info
    func getDriverInfo(bookingId: String) async throws -> TaxiDriverInfo

    /// Get real-time driver location
    /// - Parameter bookingId: The booking ID
    /// - Returns: Driver's current location and ETA
    func getDriverLocation(bookingId: String) async throws -> TaxiDriverLocation

    // MARK: - Fare Operations

    /// Get fare estimate for a route
    /// - Parameters:
    ///   - pickup: Pickup location
    ///   - dropoff: Dropoff location
    ///   - scheduledTime: When the trip is scheduled
    /// - Returns: Fare estimate with breakdown
    func estimateFare(pickup: CLLocationCoordinate2D, dropoff: CLLocationCoordinate2D, scheduledTime: Date) async throws -> TaxiFareResponse

    // MARK: - Availability

    /// Get available taxis near a location
    /// - Parameters:
    ///   - location: Center point to search from
    ///   - radius: Search radius in meters
    /// - Returns: List of nearby available taxis
    func getAvailableTaxis(near location: CLLocationCoordinate2D, radius: Int) async throws -> [TaxiAvailability]

    /// Check if service is available in an area
    /// - Parameter location: Location to check
    /// - Returns: Whether taxi service is available
    func checkServiceAvailability(at location: CLLocationCoordinate2D) async throws -> Bool
}

// MARK: - Request Models

/// Request to create a new taxi booking
struct TaxiBookingRequest: Codable {
    let pickupLocation: TaxiAPILocation
    let dropoffLocation: TaxiAPILocation
    let scheduledTime: Date
    let passengerCount: Int
    let notes: String?
    let paymentMethod: TaxiPaymentMethod?
    let customerPhone: String?
    let customerName: String?

    init(
        pickupLocation: TaxiAPILocation,
        dropoffLocation: TaxiAPILocation,
        scheduledTime: Date,
        passengerCount: Int = 1,
        notes: String? = nil,
        paymentMethod: TaxiPaymentMethod? = nil,
        customerPhone: String? = nil,
        customerName: String? = nil
    ) {
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.scheduledTime = scheduledTime
        self.passengerCount = passengerCount
        self.notes = notes
        self.paymentMethod = paymentMethod
        self.customerPhone = customerPhone
        self.customerName = customerName
    }
}

/// Location for API requests
struct TaxiAPILocation: Codable {
    let latitude: Double
    let longitude: Double
    let address: String
    let name: String?

    init(latitude: Double, longitude: Double, address: String, name: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.name = name
    }

    init(from taxiLocation: TaxiLocation) {
        self.latitude = taxiLocation.latitude
        self.longitude = taxiLocation.longitude
        self.address = taxiLocation.address
        self.name = taxiLocation.name
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Update fields for a booking
struct TaxiBookingUpdate: Codable {
    var scheduledTime: Date?
    var passengerCount: Int?
    var notes: String?
    var pickupLocation: TaxiAPILocation?
    var dropoffLocation: TaxiAPILocation?
}

/// Payment method options
enum TaxiPaymentMethod: String, Codable, CaseIterable {
    case cash = "cash"
    case creditCard = "credit_card"
    case linePay = "line_pay"
    case applePay = "apple_pay"
    case corporateAccount = "corporate"

    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .creditCard: return "Credit Card"
        case .linePay: return "LINE Pay"
        case .applePay: return "Apple Pay"
        case .corporateAccount: return "Corporate Account"
        }
    }

    var displayNameChinese: String {
        switch self {
        case .cash: return "現金"
        case .creditCard: return "信用卡"
        case .linePay: return "LINE Pay"
        case .applePay: return "Apple Pay"
        case .corporateAccount: return "企業簽單"
        }
    }
}

// MARK: - Response Models

/// Response from booking request
struct TaxiBookingResponse: Codable {
    let bookingId: String
    let status: TaxiAPIStatus
    let estimatedPickupTime: Date?
    let estimatedFare: Int?
    let driverAssigned: Bool
    let driverInfo: TaxiDriverInfo?
    let confirmationCode: String?
    let message: String?
}

/// Response from cancellation request
struct TaxiCancellationResponse: Codable {
    let success: Bool
    let bookingId: String
    let cancellationFee: Int?
    let message: String?
}

/// Response for booking status query
struct TaxiBookingStatusResponse: Codable {
    let bookingId: String
    let status: TaxiAPIStatus
    let driverInfo: TaxiDriverInfo?
    let driverLocation: TaxiDriverLocation?
    let estimatedArrival: Date?
    let actualPickupTime: Date?
    let actualDropoffTime: Date?
    let finalFare: Int?
}

/// Driver information
struct TaxiDriverInfo: Codable {
    let driverId: String
    let name: String
    let phone: String
    let photoURL: String?
    let rating: Double?
    let vehiclePlate: String
    let vehicleModel: String
    let vehicleColor: String

    var formattedRating: String? {
        guard let rating = rating else { return nil }
        return String(format: "%.1f", rating)
    }
}

/// Driver location for tracking
struct TaxiDriverLocation: Codable {
    let latitude: Double
    let longitude: Double
    let heading: Double?          // Direction driver is facing (0-360)
    let speed: Double?            // Speed in km/h
    let updatedAt: Date
    let estimatedArrivalMinutes: Int?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedETA: String? {
        guard let minutes = estimatedArrivalMinutes else { return nil }
        if minutes <= 1 {
            return "Arriving now"
        }
        return "\(minutes) min"
    }
}

/// Fare estimate response
struct TaxiFareResponse: Codable {
    let estimatedFare: Int
    let currency: String
    let breakdown: TaxiFareBreakdown
    let surcharges: [TaxiSurcharge]?
    let distanceKm: Double
    let durationMinutes: Int

    var formattedFare: String {
        "NT$\(estimatedFare)"
    }
}

/// Fare breakdown details
struct TaxiFareBreakdown: Codable {
    let baseFare: Int
    let distanceFare: Int
    let timeFare: Int
    let subtotal: Int
}

/// Additional surcharges
struct TaxiSurcharge: Codable {
    let type: String
    let amount: Int
    let description: String
}

/// Available taxi information
struct TaxiAvailability: Codable, Identifiable {
    let id: String
    let driverId: String
    let vehiclePlate: String
    let vehicleType: String
    let location: TaxiDriverLocation
    let distanceMeters: Int
    let estimatedArrivalMinutes: Int

    var formattedDistance: String {
        if distanceMeters >= 1000 {
            return String(format: "%.1f km", Double(distanceMeters) / 1000)
        }
        return "\(distanceMeters) m"
    }
}

/// API status codes
enum TaxiAPIStatus: String, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case driverAssigned = "driver_assigned"
    case driverEnRoute = "driver_en_route"
    case driverArrived = "driver_arrived"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    case noDriverAvailable = "no_driver"
    case failed = "failed"

    /// Convert to app's booking status
    var toBookingStatus: TaxiBookingStatus {
        switch self {
        case .pending: return .pending
        case .confirmed, .driverAssigned: return .confirmed
        case .driverEnRoute: return .driverEnRoute
        case .driverArrived: return .arrived
        case .inProgress: return .inProgress
        case .completed: return .completed
        case .cancelled, .noDriverAvailable, .failed: return .cancelled
        }
    }
}

// MARK: - API Errors

enum TaxiAPIError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case bookingNotFound
    case driverNotAssigned
    case serviceUnavailable
    case invalidLocation
    case paymentFailed
    case bookingAlreadyCancelled
    case rateLimitExceeded
    case authenticationFailed
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .bookingNotFound:
            return "Booking not found"
        case .driverNotAssigned:
            return "No driver assigned yet"
        case .serviceUnavailable:
            return "Taxi service is temporarily unavailable"
        case .invalidLocation:
            return "Invalid pickup or dropoff location"
        case .paymentFailed:
            return "Payment processing failed"
        case .bookingAlreadyCancelled:
            return "This booking has already been cancelled"
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        case .authenticationFailed:
            return "Authentication failed. Please check your API credentials."
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }

    var errorDescriptionChinese: String {
        switch self {
        case .networkError:
            return "網路連線錯誤"
        case .invalidResponse:
            return "伺服器回應無效"
        case .bookingNotFound:
            return "找不到此預約"
        case .driverNotAssigned:
            return "尚未指派司機"
        case .serviceUnavailable:
            return "計程車服務暫時無法使用"
        case .invalidLocation:
            return "上車或下車地點無效"
        case .paymentFailed:
            return "付款處理失敗"
        case .bookingAlreadyCancelled:
            return "此預約已被取消"
        case .rateLimitExceeded:
            return "請求過於頻繁，請稍後再試"
        case .authenticationFailed:
            return "認證失敗，請確認API金鑰"
        case .serverError:
            return "伺服器錯誤"
        }
    }
}
