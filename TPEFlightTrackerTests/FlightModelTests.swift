import XCTest
@testable import TPEFlightTracker

final class FlightModelTests: XCTestCase {

    // MARK: - FlightDirection

    func testFlightDirectionRawValues() {
        XCTAssertEqual(FlightDirection.arrival.rawValue, "Arrivals")
        XCTAssertEqual(FlightDirection.departure.rawValue, "Departures")
    }

    func testFlightDirectionAllCases() {
        XCTAssertEqual(FlightDirection.allCases.count, 2)
    }

    func testFlightDirectionIdentifiable() {
        XCTAssertEqual(FlightDirection.arrival.id, "Arrivals")
        XCTAssertEqual(FlightDirection.departure.id, "Departures")
    }

    // MARK: - FlightStatus

    func testFlightStatusRawValues() {
        XCTAssertEqual(FlightStatus.scheduled.rawValue, "Scheduled")
        XCTAssertEqual(FlightStatus.boarding.rawValue, "Boarding")
        XCTAssertEqual(FlightStatus.departed.rawValue, "Departed")
        XCTAssertEqual(FlightStatus.inAir.rawValue, "In Air")
        XCTAssertEqual(FlightStatus.landed.rawValue, "Landed")
        XCTAssertEqual(FlightStatus.arrived.rawValue, "Arrived")
        XCTAssertEqual(FlightStatus.delayed.rawValue, "Delayed")
        XCTAssertEqual(FlightStatus.cancelled.rawValue, "Cancelled")
    }

    func testFlightStatusColors() {
        XCTAssertEqual(FlightStatus.scheduled.color, "gray")
        XCTAssertEqual(FlightStatus.boarding.color, "blue")
        XCTAssertEqual(FlightStatus.departed.color, "green")
        XCTAssertEqual(FlightStatus.inAir.color, "green")
        XCTAssertEqual(FlightStatus.landed.color, "green")
        XCTAssertEqual(FlightStatus.arrived.color, "green")
        XCTAssertEqual(FlightStatus.delayed.color, "orange")
        XCTAssertEqual(FlightStatus.cancelled.color, "red")
    }

    // MARK: - Flight: isArrival / isDeparture

    func testIsArrivalReturnsTrueForArrivalDirection() {
        let flight = TestData.makeArrival()
        XCTAssertTrue(flight.isArrival)
        XCTAssertFalse(flight.isDeparture)
    }

    func testIsDepartureReturnsTrueForDepartureDirection() {
        let flight = TestData.makeDeparture()
        XCTAssertTrue(flight.isDeparture)
        XCTAssertFalse(flight.isArrival)
    }

    // MARK: - Flight: counterpartCity / counterpartIATA

    func testCounterpartCityForArrival() {
        let flight = TestData.makeArrival(origin: TestData.nrt)
        XCTAssertEqual(flight.counterpartCity, "Tokyo")
        XCTAssertEqual(flight.counterpartIATA, "NRT")
    }

    func testCounterpartCityForDeparture() {
        let flight = TestData.makeDeparture(destination: TestData.lax)
        XCTAssertEqual(flight.counterpartCity, "Los Angeles")
        XCTAssertEqual(flight.counterpartIATA, "LAX")
    }

    // MARK: - Flight: displayTime

    func testDisplayTimeReturnsActualTimeWhenAvailable() {
        let scheduled = Date()
        let actual = Date().addingTimeInterval(300)
        let flight = TestData.makeArrival(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(flight.displayTime, actual)
    }

    func testDisplayTimeReturnsEstimatedWhenNoActual() {
        let scheduled = Date()
        let estimated = Date().addingTimeInterval(600)
        let flight = TestData.makeArrival(scheduledTime: scheduled, estimatedTime: estimated)
        XCTAssertEqual(flight.displayTime, estimated)
    }

    func testDisplayTimeReturnsScheduledWhenNoEstimatedOrActual() {
        let scheduled = Date()
        let flight = TestData.makeArrival(scheduledTime: scheduled)
        XCTAssertEqual(flight.displayTime, scheduled)
    }

    func testDisplayTimePrefersActualOverEstimated() {
        let scheduled = Date()
        let estimated = Date().addingTimeInterval(600)
        let actual = Date().addingTimeInterval(300)
        let flight = TestData.makeArrival(scheduledTime: scheduled, estimatedTime: estimated, actualTime: actual)
        XCTAssertEqual(flight.displayTime, actual)
    }

    // MARK: - Flight: isDelayed

    func testIsDelayedReturnsTrueForDelayedStatus() {
        let flight = TestData.makeArrival(status: .delayed)
        XCTAssertTrue(flight.isDelayed)
    }

    func testIsDelayedReturnsFalseForOtherStatuses() {
        let statuses: [FlightStatus] = [.scheduled, .boarding, .departed, .inAir, .landed, .arrived, .cancelled]
        for status in statuses {
            let flight = TestData.makeArrival(status: status)
            XCTAssertFalse(flight.isDelayed, "Expected isDelayed=false for \(status.rawValue)")
        }
    }

    // MARK: - Flight: Codable

    func testFlightEncodesAndDecodes() throws {
        let original = TestData.makeArrival(codeshares: ["NH500", "UA800"])
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Flight.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.flightNumber, original.flightNumber)
        XCTAssertEqual(decoded.airline, original.airline)
        XCTAssertEqual(decoded.direction, original.direction)
        XCTAssertEqual(decoded.origin.iata, original.origin.iata)
        XCTAssertEqual(decoded.destination.iata, original.destination.iata)
        XCTAssertEqual(decoded.status, original.status)
        XCTAssertEqual(decoded.terminal, original.terminal)
        XCTAssertEqual(decoded.gate, original.gate)
        XCTAssertEqual(decoded.aircraft, original.aircraft)
        XCTAssertEqual(decoded.codeshares, original.codeshares)
    }

    // MARK: - Airport

    func testAirportProperties() {
        let airport = Airport(iata: "TPE", name: "Taiwan Taoyuan International Airport", city: "Taipei")
        XCTAssertEqual(airport.iata, "TPE")
        XCTAssertEqual(airport.name, "Taiwan Taoyuan International Airport")
        XCTAssertEqual(airport.city, "Taipei")
    }

    func testAirportEncodesAndDecodes() throws {
        let original = Airport(iata: "NRT", name: "Narita International Airport", city: "Tokyo")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Airport.self, from: data)
        XCTAssertEqual(decoded.iata, original.iata)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.city, original.city)
    }
}
