import Foundation
import CoreLocation
import MapKit
@testable import TPEFlightTracker

// MARK: - Mock Flight Service

class MockFlightService: FlightServiceProtocol {
    var arrivalsToReturn: [Flight] = []
    var departuresToReturn: [Flight] = []
    var errorToThrow: Error?
    var fetchCallCount = 0

    func fetchFlights(direction: FlightDirection) async throws -> [Flight] {
        fetchCallCount += 1
        if let error = errorToThrow {
            throw error
        }
        return direction == .arrival ? arrivalsToReturn : departuresToReturn
    }
}

// MARK: - Mock Directions Service

class MockDirectionsService: DirectionsServiceProtocol {
    var routeToReturn: RouteResult?
    var errorToThrow: Error?
    var calculateRouteCallCount = 0
    var lastOrigin: CLLocationCoordinate2D?
    var lastDestination: CLLocationCoordinate2D?
    var lastMode: TravelMode?

    func calculateRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        mode: TravelMode
    ) async throws -> RouteResult {
        calculateRouteCallCount += 1
        lastOrigin = origin
        lastDestination = destination
        lastMode = mode

        if let error = errorToThrow {
            throw error
        }

        return routeToReturn ?? RouteResult(
            distanceMeters: 5000,
            durationSeconds: 600,
            polyline: nil
        )
    }
}

// MARK: - Mock Trip Service

class MockTripService: TripServiceProtocol {
    var trips: [Trip] = []
    var loadTripsCallCount = 0
    var saveTripsCallCount = 0
    var addTripCallCount = 0
    var updateTripCallCount = 0
    var deleteTripCallCount = 0

    func loadTrips() -> [Trip] {
        loadTripsCallCount += 1
        return trips
    }

    func saveTrips(_ trips: [Trip]) {
        saveTripsCallCount += 1
        self.trips = trips
    }

    func addTrip(_ trip: Trip) {
        addTripCallCount += 1
        trips.append(trip)
    }

    func updateTrip(_ trip: Trip) {
        updateTripCallCount += 1
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
        }
    }

    func deleteTrip(id: UUID) {
        deleteTripCallCount += 1
        trips.removeAll { $0.id == id }
    }

    func getTrip(id: UUID) -> Trip? {
        trips.first { $0.id == id }
    }
}

// MARK: - Flight Test Data Factory

enum TestData {
    static let tpe = Airport(iata: "TPE", name: "Taiwan Taoyuan International Airport", city: "Taipei")
    static let nrt = Airport(iata: "NRT", name: "Narita International Airport", city: "Tokyo")
    static let lax = Airport(iata: "LAX", name: "Los Angeles International Airport", city: "Los Angeles")
    static let icn = Airport(iata: "ICN", name: "Incheon International Airport", city: "Seoul")

    static let now = Date()

    static func makeArrival(
        id: String = "arr-CI100",
        flightNumber: String = "CI100",
        airline: String = "China Airlines",
        origin: Airport = nrt,
        status: FlightStatus = .scheduled,
        scheduledTime: Date = now,
        estimatedTime: Date? = nil,
        actualTime: Date? = nil,
        terminal: String = "1",
        gate: String? = "A1",
        aircraft: String? = "Boeing 777-300ER",
        codeshares: [String] = []
    ) -> Flight {
        Flight(
            id: id,
            flightNumber: flightNumber,
            airline: airline,
            airlineLogo: "ci",
            direction: "arrival",
            origin: origin,
            destination: tpe,
            scheduledTime: scheduledTime,
            estimatedTime: estimatedTime,
            actualTime: actualTime,
            status: status,
            terminal: terminal,
            gate: gate,
            aircraft: aircraft,
            codeshares: codeshares
        )
    }

    static func makeDeparture(
        id: String = "dep-BR201",
        flightNumber: String = "BR201",
        airline: String = "EVA Air",
        destination: Airport = lax,
        status: FlightStatus = .boarding,
        scheduledTime: Date = now,
        estimatedTime: Date? = nil,
        actualTime: Date? = nil,
        terminal: String = "2",
        gate: String? = "B5",
        aircraft: String? = "Airbus A350-900",
        codeshares: [String] = []
    ) -> Flight {
        Flight(
            id: id,
            flightNumber: flightNumber,
            airline: airline,
            airlineLogo: "br",
            direction: "departure",
            origin: tpe,
            destination: destination,
            scheduledTime: scheduledTime,
            estimatedTime: estimatedTime,
            actualTime: actualTime,
            status: status,
            terminal: terminal,
            gate: gate,
            aircraft: aircraft,
            codeshares: codeshares
        )
    }

    static let sampleArrivals: [Flight] = [
        makeArrival(id: "arr-1", flightNumber: "CI100", airline: "China Airlines", origin: nrt, status: .landed),
        makeArrival(id: "arr-2", flightNumber: "BR201", airline: "EVA Air", origin: lax, status: .inAir),
        makeArrival(id: "arr-3", flightNumber: "JX801", airline: "Starlux Airlines", origin: icn, status: .delayed,
                    estimatedTime: Calendar.current.date(byAdding: .minute, value: 30, to: now)),
    ]

    static let sampleDepartures: [Flight] = [
        makeDeparture(id: "dep-1", flightNumber: "CI101", airline: "China Airlines", destination: nrt, status: .boarding),
        makeDeparture(id: "dep-2", flightNumber: "BR202", airline: "EVA Air", destination: lax, status: .scheduled),
    ]
}

// MARK: - Trip Test Data Factory

enum TripTestData {
    // Taipei coordinates
    static let taipei101 = CLLocationCoordinate2D(latitude: 25.0339, longitude: 121.5645)
    static let taipeiStation = CLLocationCoordinate2D(latitude: 25.0478, longitude: 121.5170)
    static let shilinNightMarket = CLLocationCoordinate2D(latitude: 25.0879, longitude: 121.5243)
    static let taoyuanAirport = CLLocationCoordinate2D(latitude: 25.0797, longitude: 121.2342)

    static func makeDestination(
        id: UUID = UUID(),
        name: String = "Taipei 101",
        address: String = "No. 7, Section 5, Xinyi Road, Xinyi District",
        coordinate: CLLocationCoordinate2D = taipei101,
        order: Int = 0,
        travelDurationMinutes: Int? = nil,
        travelDistanceMeters: Int? = nil,
        travelMode: TravelMode = .driving
    ) -> TripDestination {
        TripDestination(
            id: id,
            name: name,
            address: address,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            order: order,
            travelDurationMinutes: travelDurationMinutes,
            travelDistanceMeters: travelDistanceMeters,
            travelMode: travelMode
        )
    }

    static func makeTrip(
        id: UUID = UUID(),
        name: String = "Taipei Trip",
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(86400 * 3),
        destinations: [TripDestination] = [],
        notes: String = "",
        sourceSuggestionName: String? = nil,
        linkedFlightNumber: String? = nil
    ) -> Trip {
        Trip(
            id: id,
            name: name,
            startDate: startDate,
            endDate: endDate,
            destinations: destinations,
            notes: notes,
            sourceSuggestionName: sourceSuggestionName,
            linkedFlightNumber: linkedFlightNumber
        )
    }

    static let sampleDestinations: [TripDestination] = [
        makeDestination(name: "Taoyuan Airport", address: "Taoyuan Airport", coordinate: taoyuanAirport, order: 0),
        makeDestination(name: "Taipei 101", address: "Xinyi District", coordinate: taipei101, order: 1,
                        travelDurationMinutes: 45, travelDistanceMeters: 40000),
        makeDestination(name: "Shilin Night Market", address: "Shilin District", coordinate: shilinNightMarket, order: 2,
                        travelDurationMinutes: 20, travelDistanceMeters: 8000),
    ]

    static let sampleTrip = makeTrip(
        name: "Taiwan Adventure",
        destinations: sampleDestinations
    )
}

// MARK: - Test Errors

enum TestError: Error, LocalizedError {
    case networkFailure
    case directionsFailure

    var errorDescription: String? {
        switch self {
        case .networkFailure:
            return "Network connection failed"
        case .directionsFailure:
            return "Failed to calculate directions"
        }
    }
}
