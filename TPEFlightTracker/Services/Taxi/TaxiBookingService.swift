import Foundation
import CoreLocation

// MARK: - Taxi Booking Service Protocol

protocol TaxiBookingServiceProtocol {
    func loadBookings() -> [TaxiBooking]
    func saveBookings(_ bookings: [TaxiBooking])
    func addBooking(_ booking: TaxiBooking)
    func updateBooking(_ booking: TaxiBooking)
    func cancelBooking(id: UUID)
    func getBooking(id: UUID) -> TaxiBooking?
    func getBookingsForTrip(tripId: UUID) -> [TaxiBooking]
    func getUpcomingBookings() -> [TaxiBooking]
    func estimateFare(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, scheduledTime: Date) async -> TaxiFareEstimate?
}

// MARK: - Taxi Booking Service Implementation

class TaxiBookingService: TaxiBookingServiceProtocol {
    private let userDefaults: UserDefaults
    private let bookingsKey = "taxi_bookings"
    private let directionsService: DirectionsServiceProtocol

    init(userDefaults: UserDefaults = .standard, directionsService: DirectionsServiceProtocol = DirectionsService()) {
        self.userDefaults = userDefaults
        self.directionsService = directionsService
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
}

// MARK: - Taxi Booking View Model

@MainActor
class TaxiBookingViewModel: ObservableObject {
    @Published var bookings: [TaxiBooking] = []
    @Published var upcomingBookings: [TaxiBooking] = []
    @Published var pastBookings: [TaxiBooking] = []
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

        // Estimate fare
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
        isLoading = false
    }

    func cancelBooking(_ booking: TaxiBooking) {
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
}
