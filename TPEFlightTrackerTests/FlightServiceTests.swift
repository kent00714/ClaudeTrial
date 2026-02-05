import XCTest
@testable import TPEFlightTracker

final class FlightServiceTests: XCTestCase {

    private var service: FlightService!

    override func setUp() {
        super.setUp()
        service = FlightService()
    }

    // MARK: - Arrival Flights

    func testFetchArrivalsReturnsFlights() async throws {
        let flights = try await service.fetchFlights(direction: .arrival)
        XCTAssertFalse(flights.isEmpty)
        XCTAssertEqual(flights.count, 15)
    }

    func testArrivalFlightsHaveTPEAsDestination() async throws {
        let flights = try await service.fetchFlights(direction: .arrival)
        for flight in flights {
            XCTAssertEqual(flight.destination.iata, "TPE", "Arrival flight \(flight.flightNumber) should have TPE as destination")
        }
    }

    func testArrivalFlightsHaveArrivalDirection() async throws {
        let flights = try await service.fetchFlights(direction: .arrival)
        for flight in flights {
            XCTAssertEqual(flight.direction, "arrival")
            XCTAssertTrue(flight.isArrival)
        }
    }

    func testArrivalFlightsHaveNonTPEOrigin() async throws {
        let flights = try await service.fetchFlights(direction: .arrival)
        for flight in flights {
            XCTAssertNotEqual(flight.origin.iata, "TPE", "Arrival flight \(flight.flightNumber) should not originate from TPE")
        }
    }

    // MARK: - Departure Flights

    func testFetchDeparturesReturnsFlights() async throws {
        let flights = try await service.fetchFlights(direction: .departure)
        XCTAssertFalse(flights.isEmpty)
        XCTAssertEqual(flights.count, 15)
    }

    func testDepartureFlightsHaveTPEAsOrigin() async throws {
        let flights = try await service.fetchFlights(direction: .departure)
        for flight in flights {
            XCTAssertEqual(flight.origin.iata, "TPE", "Departure flight \(flight.flightNumber) should have TPE as origin")
        }
    }

    func testDepartureFlightsHaveDepartureDirection() async throws {
        let flights = try await service.fetchFlights(direction: .departure)
        for flight in flights {
            XCTAssertEqual(flight.direction, "departure")
            XCTAssertTrue(flight.isDeparture)
        }
    }

    func testDepartureFlightsHaveNonTPEDestination() async throws {
        let flights = try await service.fetchFlights(direction: .departure)
        for flight in flights {
            XCTAssertNotEqual(flight.destination.iata, "TPE", "Departure flight \(flight.flightNumber) should not go to TPE")
        }
    }

    // MARK: - Flight Data Integrity

    func testAllFlightsHaveUniqueIds() async throws {
        let arrivals = try await service.fetchFlights(direction: .arrival)
        let departures = try await service.fetchFlights(direction: .departure)
        let allIds = (arrivals + departures).map(\.id)
        XCTAssertEqual(Set(allIds).count, allIds.count, "All flight IDs should be unique")
    }

    func testAllFlightsHaveValidFlightNumbers() async throws {
        let flights = try await service.fetchFlights(direction: .arrival)
        for flight in flights {
            XCTAssertFalse(flight.flightNumber.isEmpty, "Flight number should not be empty")
            XCTAssertFalse(flight.airline.isEmpty, "Airline should not be empty")
        }
    }

    func testAllFlightsHaveTerminal() async throws {
        let flights = try await service.fetchFlights(direction: .arrival)
        for flight in flights {
            XCTAssertTrue(flight.terminal == "1" || flight.terminal == "2",
                         "Terminal should be 1 or 2, got \(flight.terminal)")
        }
    }

    func testAllFlightsHaveAircraft() async throws {
        let flights = try await service.fetchFlights(direction: .arrival)
        for flight in flights {
            XCTAssertNotNil(flight.aircraft)
        }
    }

    // MARK: - Delayed Flights

    func testDelayedFlightsHaveEstimatedTime() async throws {
        let flights = try await service.fetchFlights(direction: .arrival)
        let delayed = flights.filter { $0.status == .delayed }
        for flight in delayed {
            XCTAssertNotNil(flight.estimatedTime,
                          "Delayed flight \(flight.flightNumber) should have estimated time")
        }
    }

    // MARK: - Landed/Arrived/Departed Flights

    func testCompletedFlightsHaveActualTime() async throws {
        let flights = try await service.fetchFlights(direction: .arrival)
        let completed = flights.filter { $0.status == .landed || $0.status == .arrived || $0.status == .departed }
        for flight in completed {
            XCTAssertNotNil(flight.actualTime,
                          "\(flight.status.rawValue) flight \(flight.flightNumber) should have actual time")
        }
    }
}
