import XCTest
@testable import TPEFlightTracker

final class FlightServiceTests: XCTestCase {

    private var service: FlightService!

    override func setUp() {
        super.setUp()
        // Uses default API key "YOUR_API_KEY_HERE" which triggers mock fallback
        service = FlightService()
    }

    // MARK: - Mock Fallback (no API key)

    func testFetchArrivalsReturnsMockFlightsWithoutAPIKey() async throws {
        let flights = try await service.fetchFlights(direction: .arrival)
        XCTAssertFalse(flights.isEmpty)
        XCTAssertEqual(flights.count, 15)
    }

    func testFetchDeparturesReturnsMockFlightsWithoutAPIKey() async throws {
        let flights = try await service.fetchFlights(direction: .departure)
        XCTAssertFalse(flights.isEmpty)
        XCTAssertEqual(flights.count, 15)
    }

    // MARK: - Arrival Mock Flights

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

    // MARK: - Departure Mock Flights

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

    // MARK: - AirportLookup

    func testAirportLookupReturnsKnownAirport() {
        let airport = AirportLookup.airport(for: "TPE")
        XCTAssertEqual(airport.iata, "TPE")
        XCTAssertEqual(airport.city, "Taipei")
        XCTAssertTrue(airport.name.contains("Taoyuan"))
    }

    func testAirportLookupReturnsKnownJapaneseAirport() {
        let airport = AirportLookup.airport(for: "NRT")
        XCTAssertEqual(airport.iata, "NRT")
        XCTAssertEqual(airport.city, "Tokyo")
    }

    func testAirportLookupFallsBackForUnknownCode() {
        let airport = AirportLookup.airport(for: "XYZ")
        XCTAssertEqual(airport.iata, "XYZ")
        XCTAssertEqual(airport.city, "XYZ")
    }

    // MARK: - AirlineLookup

    func testAirlineLookupReturnsKnownAirline() {
        XCTAssertEqual(AirlineLookup.airlineName(for: "CI"), "China Airlines")
        XCTAssertEqual(AirlineLookup.airlineName(for: "BR"), "EVA Air")
        XCTAssertEqual(AirlineLookup.airlineName(for: "JX"), "Starlux Airlines")
    }

    func testAirlineLookupFallsBackForUnknownCode() {
        XCTAssertEqual(AirlineLookup.airlineName(for: "ZZ"), "ZZ")
    }

    // MARK: - APIConfig

    func testAPIConfigDefaults() {
        XCTAssertEqual(APIConfig.airportCode, "TPE")
        XCTAssertTrue(APIConfig.airLabsBaseURL.contains("airlabs.co"))
    }

    // MARK: - FlightServiceError

    func testFlightServiceErrorDescriptions() {
        XCTAssertNotNil(FlightServiceError.invalidURL.errorDescription)
        XCTAssertNotNil(FlightServiceError.invalidResponse.errorDescription)
        XCTAssertNotNil(FlightServiceError.httpError(statusCode: 401).errorDescription)
        XCTAssertTrue(FlightServiceError.httpError(statusCode: 401).errorDescription!.contains("401"))
    }

    // MARK: - AirLabsSchedule Decoding

    func testAirLabsScheduleResponseDecoding() throws {
        let json = """
        {
            "response": [
                {
                    "airline_iata": "CI",
                    "flight_iata": "CI100",
                    "flight_number": "100",
                    "dep_iata": "NRT",
                    "arr_iata": "TPE",
                    "dep_terminal": "1",
                    "arr_terminal": "2",
                    "dep_gate": "A1",
                    "arr_gate": "B5",
                    "dep_time": "2026-02-05 10:00",
                    "arr_time": "2026-02-05 13:30",
                    "dep_estimated": "2026-02-05 10:15",
                    "arr_estimated": "2026-02-05 13:45",
                    "status": "active",
                    "duration": 210,
                    "delayed": 15,
                    "aircraft_icao": "B77W",
                    "cs_flight_iata": "NH5100"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AirLabsScheduleResponse.self, from: json)
        XCTAssertEqual(decoded.response.count, 1)

        let schedule = decoded.response[0]
        XCTAssertEqual(schedule.airlineIata, "CI")
        XCTAssertEqual(schedule.flightIata, "CI100")
        XCTAssertEqual(schedule.flightNumber, "100")
        XCTAssertEqual(schedule.depIata, "NRT")
        XCTAssertEqual(schedule.arrIata, "TPE")
        XCTAssertEqual(schedule.depTerminal, "1")
        XCTAssertEqual(schedule.arrTerminal, "2")
        XCTAssertEqual(schedule.depGate, "A1")
        XCTAssertEqual(schedule.arrGate, "B5")
        XCTAssertEqual(schedule.depTime, "2026-02-05 10:00")
        XCTAssertEqual(schedule.arrTime, "2026-02-05 13:30")
        XCTAssertEqual(schedule.depEstimated, "2026-02-05 10:15")
        XCTAssertEqual(schedule.arrEstimated, "2026-02-05 13:45")
        XCTAssertEqual(schedule.status, "active")
        XCTAssertEqual(schedule.duration, 210)
        XCTAssertEqual(schedule.delayed, 15)
        XCTAssertEqual(schedule.aircraftIcao, "B77W")
        XCTAssertEqual(schedule.csFlightIata, "NH5100")
    }

    func testAirLabsScheduleHandlesNullFields() throws {
        let json = """
        {
            "response": [
                {
                    "airline_iata": "BR",
                    "flight_iata": "BR201",
                    "dep_iata": "TPE",
                    "arr_iata": "LAX",
                    "dep_time": "2026-02-05 23:00",
                    "arr_time": "2026-02-05 19:00",
                    "status": "scheduled"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AirLabsScheduleResponse.self, from: json)
        let schedule = decoded.response[0]
        XCTAssertNil(schedule.depTerminal)
        XCTAssertNil(schedule.arrTerminal)
        XCTAssertNil(schedule.depGate)
        XCTAssertNil(schedule.arrGate)
        XCTAssertNil(schedule.depEstimated)
        XCTAssertNil(schedule.arrEstimated)
        XCTAssertNil(schedule.depActual)
        XCTAssertNil(schedule.arrActual)
        XCTAssertNil(schedule.delayed)
        XCTAssertNil(schedule.aircraftIcao)
        XCTAssertNil(schedule.csFlightIata)
    }
}
