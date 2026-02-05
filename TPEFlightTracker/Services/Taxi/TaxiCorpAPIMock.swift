import Foundation
import CoreLocation

// MARK: - Mock Taxi Corp API

/// Mock implementation of TaxiCorpAPIProtocol for development and testing.
/// Simulates API responses with realistic delays and sample data.
class TaxiCorpAPIMock: TaxiCorpAPIProtocol {

    // MARK: - Configuration

    /// Simulated network delay range (seconds)
    var minDelay: Double = 0.5
    var maxDelay: Double = 2.0

    /// Whether to simulate random failures
    var simulateRandomFailures = false
    var failureRate: Double = 0.1

    /// Simulated bookings storage
    private var mockBookings: [String: MockBookingData] = [:]

    // MARK: - Booking Operations

    func requestBooking(_ request: TaxiBookingRequest) async throws -> TaxiBookingResponse {
        try await simulateNetworkDelay()
        try simulateRandomFailure()

        let bookingId = "BK\(Int.random(in: 100000...999999))"
        let confirmationCode = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })

        // Simulate driver assignment (80% chance of immediate assignment)
        let driverAssigned = Double.random(in: 0...1) < 0.8
        let driverInfo = driverAssigned ? generateMockDriver() : nil

        let mockData = MockBookingData(
            request: request,
            status: driverAssigned ? .driverAssigned : .confirmed,
            driverInfo: driverInfo,
            createdAt: Date()
        )
        mockBookings[bookingId] = mockData

        return TaxiBookingResponse(
            bookingId: bookingId,
            status: driverAssigned ? .driverAssigned : .confirmed,
            estimatedPickupTime: request.scheduledTime,
            estimatedFare: calculateMockFare(request: request),
            driverAssigned: driverAssigned,
            driverInfo: driverInfo,
            confirmationCode: confirmationCode,
            message: driverAssigned ? "Driver assigned successfully" : "Looking for nearby drivers"
        )
    }

    func cancelBooking(bookingId: String) async throws -> TaxiCancellationResponse {
        try await simulateNetworkDelay()
        try simulateRandomFailure()

        guard let booking = mockBookings[bookingId] else {
            throw TaxiAPIError.bookingNotFound
        }

        if booking.status == .cancelled {
            throw TaxiAPIError.bookingAlreadyCancelled
        }

        // Calculate cancellation fee based on status
        var cancellationFee: Int? = nil
        if booking.status == .driverEnRoute || booking.status == .driverArrived {
            cancellationFee = 50 // NT$50 cancellation fee
        }

        mockBookings[bookingId]?.status = .cancelled

        return TaxiCancellationResponse(
            success: true,
            bookingId: bookingId,
            cancellationFee: cancellationFee,
            message: cancellationFee != nil ? "Booking cancelled. Cancellation fee applies." : "Booking cancelled successfully"
        )
    }

    func getBookingStatus(bookingId: String) async throws -> TaxiBookingStatusResponse {
        try await simulateNetworkDelay()
        try simulateRandomFailure()

        guard let booking = mockBookings[bookingId] else {
            throw TaxiAPIError.bookingNotFound
        }

        // Simulate status progression
        progressBookingStatus(bookingId: bookingId)

        let driverLocation = booking.driverInfo != nil ? generateMockDriverLocation(for: booking) : nil

        return TaxiBookingStatusResponse(
            bookingId: bookingId,
            status: booking.status,
            driverInfo: booking.driverInfo,
            driverLocation: driverLocation,
            estimatedArrival: booking.request.scheduledTime,
            actualPickupTime: booking.status == .inProgress || booking.status == .completed ? Date() : nil,
            actualDropoffTime: booking.status == .completed ? Date().addingTimeInterval(1800) : nil,
            finalFare: booking.status == .completed ? calculateMockFare(request: booking.request) : nil
        )
    }

    func updateBooking(bookingId: String, update: TaxiBookingUpdate) async throws -> TaxiBookingResponse {
        try await simulateNetworkDelay()
        try simulateRandomFailure()

        guard var booking = mockBookings[bookingId] else {
            throw TaxiAPIError.bookingNotFound
        }

        // Apply updates
        if let time = update.scheduledTime {
            booking.request = TaxiBookingRequest(
                pickupLocation: booking.request.pickupLocation,
                dropoffLocation: booking.request.dropoffLocation,
                scheduledTime: time,
                passengerCount: update.passengerCount ?? booking.request.passengerCount,
                notes: update.notes ?? booking.request.notes
            )
        }

        mockBookings[bookingId] = booking

        return TaxiBookingResponse(
            bookingId: bookingId,
            status: booking.status,
            estimatedPickupTime: booking.request.scheduledTime,
            estimatedFare: calculateMockFare(request: booking.request),
            driverAssigned: booking.driverInfo != nil,
            driverInfo: booking.driverInfo,
            confirmationCode: nil,
            message: "Booking updated successfully"
        )
    }

    // MARK: - Driver Operations

    func getDriverInfo(bookingId: String) async throws -> TaxiDriverInfo {
        try await simulateNetworkDelay()

        guard let booking = mockBookings[bookingId] else {
            throw TaxiAPIError.bookingNotFound
        }

        guard let driverInfo = booking.driverInfo else {
            throw TaxiAPIError.driverNotAssigned
        }

        return driverInfo
    }

    func getDriverLocation(bookingId: String) async throws -> TaxiDriverLocation {
        try await simulateNetworkDelay()

        guard let booking = mockBookings[bookingId] else {
            throw TaxiAPIError.bookingNotFound
        }

        guard booking.driverInfo != nil else {
            throw TaxiAPIError.driverNotAssigned
        }

        return generateMockDriverLocation(for: booking)
    }

    // MARK: - Fare Operations

    func estimateFare(pickup: CLLocationCoordinate2D, dropoff: CLLocationCoordinate2D, scheduledTime: Date) async throws -> TaxiFareResponse {
        try await simulateNetworkDelay()
        try simulateRandomFailure()

        // Calculate distance using simple formula
        let distance = calculateDistance(from: pickup, to: dropoff)
        let distanceKm = distance / 1000
        let durationMinutes = Int(distanceKm * 3) // Assume ~20km/h average speed in city

        // Taiwan taxi fare calculation
        let baseFare = 85
        var distanceFare = 0
        if distanceKm > 1.25 {
            distanceFare = Int((distanceKm - 1.25) / 0.25) * 5
        }
        let timeFare = (durationMinutes / 3) * 5
        let subtotal = baseFare + distanceFare + timeFare

        // Check for night surcharge
        let hour = Calendar.current.component(.hour, from: scheduledTime)
        let isNightTime = hour >= 23 || hour < 6
        var surcharges: [TaxiSurcharge] = []
        var total = subtotal

        if isNightTime {
            let nightSurcharge = Int(Double(subtotal) * 0.2)
            surcharges.append(TaxiSurcharge(
                type: "night",
                amount: nightSurcharge,
                description: "Night surcharge (23:00-06:00)"
            ))
            total += nightSurcharge
        }

        return TaxiFareResponse(
            estimatedFare: total,
            currency: "TWD",
            breakdown: TaxiFareBreakdown(
                baseFare: baseFare,
                distanceFare: distanceFare,
                timeFare: timeFare,
                subtotal: subtotal
            ),
            surcharges: surcharges.isEmpty ? nil : surcharges,
            distanceKm: distanceKm,
            durationMinutes: durationMinutes
        )
    }

    // MARK: - Availability

    func getAvailableTaxis(near location: CLLocationCoordinate2D, radius: Int) async throws -> [TaxiAvailability] {
        try await simulateNetworkDelay()

        // Generate 3-8 mock nearby taxis
        let count = Int.random(in: 3...8)
        return (0..<count).map { index in
            let randomOffset = Double.random(in: -0.01...0.01)
            let taxiLat = location.latitude + randomOffset
            let taxiLon = location.longitude + randomOffset
            let distance = Int(calculateDistance(
                from: location,
                to: CLLocationCoordinate2D(latitude: taxiLat, longitude: taxiLon)
            ))

            return TaxiAvailability(
                id: "TX\(1000 + index)",
                driverId: "DRV\(Int.random(in: 1000...9999))",
                vehiclePlate: generateMockPlate(),
                vehicleType: ["Toyota Camry", "Toyota Wish", "Nissan Sentra", "Ford Escort"].randomElement()!,
                location: TaxiDriverLocation(
                    latitude: taxiLat,
                    longitude: taxiLon,
                    heading: Double.random(in: 0...360),
                    speed: Double.random(in: 0...40),
                    updatedAt: Date(),
                    estimatedArrivalMinutes: max(1, distance / 500)
                ),
                distanceMeters: distance,
                estimatedArrivalMinutes: max(1, distance / 500)
            )
        }.sorted { $0.distanceMeters < $1.distanceMeters }
    }

    func checkServiceAvailability(at location: CLLocationCoordinate2D) async throws -> Bool {
        try await simulateNetworkDelay()

        // Service available in Taiwan area
        let inTaiwan = location.latitude >= 21.9 && location.latitude <= 25.3 &&
                       location.longitude >= 120.0 && location.longitude <= 122.0
        return inTaiwan
    }

    // MARK: - Private Helpers

    private func simulateNetworkDelay() async throws {
        let delay = Double.random(in: minDelay...maxDelay)
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    private func simulateRandomFailure() throws {
        if simulateRandomFailures && Double.random(in: 0...1) < failureRate {
            throw TaxiAPIError.serverError("Simulated random failure")
        }
    }

    private func generateMockDriver() -> TaxiDriverInfo {
        let names = ["Wang Wei", "Chen Ming", "Lin Jia", "Zhang Yu", "Li Hua", "Wu Jun"]
        let colors = ["Yellow", "White", "Silver", "Black"]
        let models = ["Toyota Camry", "Toyota Wish", "Nissan Sentra", "Honda City"]

        return TaxiDriverInfo(
            driverId: "DRV\(Int.random(in: 1000...9999))",
            name: names.randomElement()!,
            phone: "09\(Int.random(in: 10000000...99999999))",
            photoURL: nil,
            rating: Double.random(in: 4.0...5.0),
            vehiclePlate: generateMockPlate(),
            vehicleModel: models.randomElement()!,
            vehicleColor: colors.randomElement()!
        )
    }

    private func generateMockPlate() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ"
        let prefix = String((0..<3).map { _ in letters.randomElement()! })
        let number = Int.random(in: 1000...9999)
        return "\(prefix)-\(number)"
    }

    private func generateMockDriverLocation(for booking: MockBookingData) -> TaxiDriverLocation {
        // Simulate driver moving towards pickup
        let pickup = booking.request.pickupLocation
        let randomOffset = Double.random(in: -0.005...0.005)

        return TaxiDriverLocation(
            latitude: pickup.latitude + randomOffset,
            longitude: pickup.longitude + randomOffset,
            heading: Double.random(in: 0...360),
            speed: Double.random(in: 20...50),
            updatedAt: Date(),
            estimatedArrivalMinutes: Int.random(in: 1...10)
        )
    }

    private func calculateMockFare(request: TaxiBookingRequest) -> Int {
        let distance = calculateDistance(
            from: request.pickupLocation.coordinate,
            to: request.dropoffLocation.coordinate
        )
        let distanceKm = distance / 1000

        let baseFare = 85
        var distanceFare = 0
        if distanceKm > 1.25 {
            distanceFare = Int((distanceKm - 1.25) / 0.25) * 5
        }

        return baseFare + distanceFare
    }

    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    private func progressBookingStatus(bookingId: String) {
        guard var booking = mockBookings[bookingId] else { return }

        // Simulate status progression based on time
        let elapsed = Date().timeIntervalSince(booking.createdAt)

        switch booking.status {
        case .confirmed:
            if elapsed > 10 && booking.driverInfo == nil {
                booking.driverInfo = generateMockDriver()
                booking.status = .driverAssigned
            }
        case .driverAssigned:
            if elapsed > 20 {
                booking.status = .driverEnRoute
            }
        case .driverEnRoute:
            if elapsed > 40 {
                booking.status = .driverArrived
            }
        default:
            break
        }

        mockBookings[bookingId] = booking
    }
}

// MARK: - Mock Data Structures

private struct MockBookingData {
    var request: TaxiBookingRequest
    var status: TaxiAPIStatus
    var driverInfo: TaxiDriverInfo?
    let createdAt: Date
}
