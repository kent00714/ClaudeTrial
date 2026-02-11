import Foundation
import CoreLocation
import Combine

// MARK: - Taxi Booking Service Protocol

protocol TaxiBookingServiceProtocol {
    // Local storage operations
    func loadBookings() -> [TaxiBooking]
    func saveBookings(_ bookings: [TaxiBooking])
    func addBooking(_ booking: TaxiBooking)
    func updateBooking(_ booking: TaxiBooking)
    func cancelBooking(id: UUID)
    func getBooking(id: UUID) -> TaxiBooking?
    func getBookingsForTrip(tripId: UUID) -> [TaxiBooking]
    func getUpcomingBookings() -> [TaxiBooking]
    func estimateFare(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, scheduledTime: Date) async -> TaxiFareEstimate?

    // API operations
    func requestBookingFromAPI(_ request: TaxiBookingRequest) async throws -> TaxiBookingResponse
    func cancelBookingFromAPI(bookingId: String) async throws -> TaxiCancellationResponse
    func getBookingStatusFromAPI(bookingId: String) async throws -> TaxiBookingStatusResponse
    func getDriverLocationFromAPI(bookingId: String) async throws -> TaxiDriverLocation
    func getAvailableTaxisFromAPI(near location: CLLocationCoordinate2D, radius: Int) async throws -> [TaxiAvailability]
}

// MARK: - Taxi Booking Service Implementation

class TaxiBookingService: TaxiBookingServiceProtocol {
    private let userDefaults: UserDefaults
    private let bookingsKey = "taxi_bookings"
    private let directionsService: DirectionsServiceProtocol
    private let api: TaxiCorpAPIProtocol

    init(
        userDefaults: UserDefaults = .standard,
        directionsService: DirectionsServiceProtocol = DirectionsService(),
        api: TaxiCorpAPIProtocol? = nil
    ) {
        self.userDefaults = userDefaults
        self.directionsService = directionsService
        self.api = api ?? TaxiAPIConfig.shared.api
    }

    func loadBookings() -> [TaxiBooking] {
        guard let data = userDefaults.data(forKey: bookingsKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([TaxiBooking].self, from: data)
        } catch {
            print("Error loading taxi bookings: \(error)")
            return []
        }
    }

    func saveBookings(_ bookings: [TaxiBooking]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(bookings)
            userDefaults.set(data, forKey: bookingsKey)
        } catch {
            print("Error saving taxi bookings: \(error)")
        }
    }

    func addBooking(_ booking: TaxiBooking) {
        var bookings = loadBookings()
        bookings.append(booking)
        bookings.sort { $0.scheduledTime < $1.scheduledTime }
        saveBookings(bookings)
    }

    func updateBooking(_ booking: TaxiBooking) {
        var bookings = loadBookings()
        if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
            var updatedBooking = booking
            updatedBooking.updatedAt = Date()
            bookings[index] = updatedBooking
            saveBookings(bookings)
        }
    }

    func cancelBooking(id: UUID) {
        var bookings = loadBookings()
        if let index = bookings.firstIndex(where: { $0.id == id }) {
            bookings[index].status = .cancelled
            bookings[index].updatedAt = Date()
            saveBookings(bookings)
        }
    }

    func getBooking(id: UUID) -> TaxiBooking? {
        loadBookings().first { $0.id == id }
    }

    func getBookingsForTrip(tripId: UUID) -> [TaxiBooking] {
        loadBookings().filter { $0.linkedTripId == tripId }
    }

    func getUpcomingBookings() -> [TaxiBooking] {
        loadBookings()
            .filter { $0.isUpcoming }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    func estimateFare(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, scheduledTime: Date) async -> TaxiFareEstimate? {
        do {
            let route = try await directionsService.calculateRoute(from: from, to: to, mode: .taxi)

            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: scheduledTime)
            let isNightTime = hour >= 23 || hour < 6

            return TaxiFareEstimate.estimate(
                distanceMeters: route.distanceMeters,
                durationMinutes: route.durationMinutes,
                isNightTime: isNightTime
            )
        } catch {
            print("Error estimating fare: \(error)")
            return nil
        }
    }

    // MARK: - API Operations

    func requestBookingFromAPI(_ request: TaxiBookingRequest) async throws -> TaxiBookingResponse {
        return try await api.requestBooking(request)
    }

    func cancelBookingFromAPI(bookingId: String) async throws -> TaxiCancellationResponse {
        return try await api.cancelBooking(bookingId: bookingId)
    }

    func getBookingStatusFromAPI(bookingId: String) async throws -> TaxiBookingStatusResponse {
        return try await api.getBookingStatus(bookingId: bookingId)
    }

    func getDriverLocationFromAPI(bookingId: String) async throws -> TaxiDriverLocation {
        return try await api.getDriverLocation(bookingId: bookingId)
    }

    func getAvailableTaxisFromAPI(near location: CLLocationCoordinate2D, radius: Int) async throws -> [TaxiAvailability] {
        return try await api.getAvailableTaxis(near: location, radius: radius)
    }

    func estimateFareFromAPI(pickup: CLLocationCoordinate2D, dropoff: CLLocationCoordinate2D, scheduledTime: Date) async throws -> TaxiFareResponse {
        return try await api.estimateFare(pickup: pickup, dropoff: dropoff, scheduledTime: scheduledTime)
    }
}

// MARK: - Taxi Booking View Model

@MainActor
class TaxiBookingViewModel: ObservableObject {
    @Published var bookings: [TaxiBooking] = []
    @Published var upcomingBookings: [TaxiBooking] = []
    @Published var pastBookings: [TaxiBooking] = []
    @Published var availableTaxis: [TaxiAvailability] = []
    @Published var currentDriverLocation: TaxiDriverLocation?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let bookingService: TaxiBookingServiceProtocol

    init(bookingService: TaxiBookingServiceProtocol = TaxiBookingService()) {
        self.bookingService = bookingService
        loadBookings()
    }

    func loadBookings() {
        bookings = bookingService.loadBookings()
        upcomingBookings = bookings.filter { $0.isUpcoming }.sorted { $0.scheduledTime < $1.scheduledTime }
        pastBookings = bookings.filter { $0.isPast }.sorted { $0.scheduledTime > $1.scheduledTime }
    }

    /// Create a booking (local + API)
    func createBooking(
        pickupLocation: TaxiLocation,
        dropoffLocation: TaxiLocation,
        scheduledTime: Date,
        passengerCount: Int = 1,
        notes: String = "",
        linkedTripId: UUID? = nil,
        linkedDestinationId: UUID? = nil
    ) async {
        isLoading = true
        errorMessage = nil

        // Try API booking first if available
        do {
            let request = TaxiBookingRequest(
                pickupLocation: TaxiAPILocation(from: pickupLocation),
                dropoffLocation: TaxiAPILocation(from: dropoffLocation),
                scheduledTime: scheduledTime,
                passengerCount: passengerCount,
                notes: notes.isEmpty ? nil : notes
            )

            let response = try await bookingService.requestBookingFromAPI(request)

            // Create local booking with API response data
            let booking = TaxiBooking(
                pickupLocation: pickupLocation,
                dropoffLocation: dropoffLocation,
                scheduledTime: scheduledTime,
                passengerCount: passengerCount,
                notes: notes,
                status: response.status.toBookingStatus,
                linkedTripId: linkedTripId,
                linkedDestinationId: linkedDestinationId,
                estimatedFare: response.estimatedFare,
                estimatedDuration: nil,
                driverName: response.driverInfo?.name,
                driverPhone: response.driverInfo?.phone,
                vehiclePlate: response.driverInfo?.vehiclePlate
            )

            bookingService.addBooking(booking)
            loadBookings()
        } catch let error as TaxiAPIError {
            // If API fails, fall back to local booking
            print("API booking failed: \(error.localizedDescription), creating local booking")
            await createLocalBooking(
                pickupLocation: pickupLocation,
                dropoffLocation: dropoffLocation,
                scheduledTime: scheduledTime,
                passengerCount: passengerCount,
                notes: notes,
                linkedTripId: linkedTripId,
                linkedDestinationId: linkedDestinationId
            )
        } catch {
            await createLocalBooking(
                pickupLocation: pickupLocation,
                dropoffLocation: dropoffLocation,
                scheduledTime: scheduledTime,
                passengerCount: passengerCount,
                notes: notes,
                linkedTripId: linkedTripId,
                linkedDestinationId: linkedDestinationId
            )
        }

        isLoading = false
    }

    /// Create a local-only booking (without API)
    private func createLocalBooking(
        pickupLocation: TaxiLocation,
        dropoffLocation: TaxiLocation,
        scheduledTime: Date,
        passengerCount: Int,
        notes: String,
        linkedTripId: UUID?,
        linkedDestinationId: UUID?
    ) async {
        // Estimate fare locally
        let fareEstimate = await bookingService.estimateFare(
            from: pickupLocation.coordinate,
            to: dropoffLocation.coordinate,
            scheduledTime: scheduledTime
        )

        let booking = TaxiBooking(
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            scheduledTime: scheduledTime,
            passengerCount: passengerCount,
            notes: notes,
            status: .pending,
            linkedTripId: linkedTripId,
            linkedDestinationId: linkedDestinationId,
            estimatedFare: fareEstimate?.totalFare,
            estimatedDuration: nil
        )

        bookingService.addBooking(booking)
        loadBookings()
    }

    func cancelBooking(_ booking: TaxiBooking) {
        // Try API cancellation
        Task {
            do {
                // Note: Would need to store API booking ID to cancel via API
                // For now, just cancel locally
                _ = try await bookingService.cancelBookingFromAPI(bookingId: booking.id.uuidString)
            } catch {
                print("API cancellation failed: \(error)")
            }
        }

        bookingService.cancelBooking(id: booking.id)
        loadBookings()
    }

    func updateBookingStatus(_ booking: TaxiBooking, status: TaxiBookingStatus) {
        var updatedBooking = booking
        updatedBooking.status = status
        bookingService.updateBooking(updatedBooking)
        loadBookings()
    }

    func getBookingsForTrip(tripId: UUID) -> [TaxiBooking] {
        bookings.filter { $0.linkedTripId == tripId }
    }

    // MARK: - API Features

    /// Fetch available taxis near a location
    func fetchAvailableTaxis(near location: CLLocationCoordinate2D, radius: Int = 2000) async {
        isLoading = true
        errorMessage = nil

        do {
            availableTaxis = try await bookingService.getAvailableTaxisFromAPI(near: location, radius: radius)
        } catch {
            errorMessage = error.localizedDescription
            availableTaxis = []
        }

        isLoading = false
    }

    /// Track driver location for a booking
    func trackDriverLocation(bookingId: String) async {
        do {
            currentDriverLocation = try await bookingService.getDriverLocationFromAPI(bookingId: bookingId)
        } catch {
            print("Error tracking driver: \(error)")
            currentDriverLocation = nil
        }
    }

    /// Refresh booking status from API
    func refreshBookingStatus(bookingId: String) async {
        do {
            let status = try await bookingService.getBookingStatusFromAPI(bookingId: bookingId)

            // Update local booking with API status
            if let index = bookings.firstIndex(where: { $0.id.uuidString == bookingId }) {
                var updated = bookings[index]
                updated.status = status.status.toBookingStatus
                if let driverInfo = status.driverInfo {
                    updated.driverName = driverInfo.name
                    updated.driverPhone = driverInfo.phone
                    updated.vehiclePlate = driverInfo.vehiclePlate
                }
                bookingService.updateBooking(updated)
                loadBookings()
            }
        } catch {
            print("Error refreshing status: \(error)")
        }
    }
}
