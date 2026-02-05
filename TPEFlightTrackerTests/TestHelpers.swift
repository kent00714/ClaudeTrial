import Foundation
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

// MARK: - Test Data Factory

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

// MARK: - Test Errors

enum TestError: Error, LocalizedError {
    case networkFailure

    var errorDescription: String? {
        "Network connection failed"
    }
}
