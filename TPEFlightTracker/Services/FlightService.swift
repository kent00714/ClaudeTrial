import Foundation

class FlightService {

    // MARK: - Public API

    /// Fetch flights for TPE airport.
    /// Replace the mock implementation with a real API call when ready
    /// (e.g., AviationStack, FlightAware, or Taiwan MOTC open data).
    func fetchFlights(direction: FlightDirection) async throws -> [Flight] {
        // TODO: Replace with real API integration
        // Example endpoint: https://tdx.transportdata.tw/api/basic/v2/Air/FIDS/Airport/TPE
        try await Task.sleep(nanoseconds: 500_000_000) // simulate network delay
        return Self.mockFlights(direction: direction)
    }

    // MARK: - Mock Data

    private static let tpe = Airport(iata: "TPE", name: "Taiwan Taoyuan International Airport", city: "Taipei")

    private static let airports: [Airport] = [
        Airport(iata: "NRT", name: "Narita International Airport", city: "Tokyo"),
        Airport(iata: "KIX", name: "Kansai International Airport", city: "Osaka"),
        Airport(iata: "ICN", name: "Incheon International Airport", city: "Seoul"),
        Airport(iata: "HKG", name: "Hong Kong International Airport", city: "Hong Kong"),
        Airport(iata: "SIN", name: "Changi Airport", city: "Singapore"),
        Airport(iata: "BKK", name: "Suvarnabhumi Airport", city: "Bangkok"),
        Airport(iata: "LAX", name: "Los Angeles International Airport", city: "Los Angeles"),
        Airport(iata: "SFO", name: "San Francisco International Airport", city: "San Francisco"),
        Airport(iata: "CDG", name: "Charles de Gaulle Airport", city: "Paris"),
        Airport(iata: "LHR", name: "Heathrow Airport", city: "London"),
        Airport(iata: "PVG", name: "Pudong International Airport", city: "Shanghai"),
        Airport(iata: "MNL", name: "Ninoy Aquino International Airport", city: "Manila"),
    ]

    private static let airlines: [(code: String, name: String)] = [
        ("CI", "China Airlines"),
        ("BR", "EVA Air"),
        ("JX", "Starlux Airlines"),
        ("IT", "Tigerair Taiwan"),
        ("JL", "Japan Airlines"),
        ("NH", "ANA"),
        ("KE", "Korean Air"),
        ("OZ", "Asiana Airlines"),
        ("CX", "Cathay Pacific"),
        ("SQ", "Singapore Airlines"),
        ("TG", "Thai Airways"),
        ("AA", "American Airlines"),
        ("UA", "United Airlines"),
    ]

    private static func mockFlights(direction: FlightDirection) -> [Flight] {
        let calendar = Calendar.current
        let now = Date()

        let statuses: [FlightStatus] = [
            .scheduled, .scheduled, .boarding, .inAir,
            .landed, .arrived, .delayed, .departed
        ]

        return (0..<15).map { index in
            let airport = airports[index % airports.count]
            let airline = airlines[index % airlines.count]
            let flightNum = "\(airline.code)\(100 + index * 7)"

            let hourOffset = -2 + index
            let scheduled = calendar.date(byAdding: .hour, value: hourOffset, to: now)!
            let status = statuses[index % statuses.count]

            let estimated: Date? = status == .delayed
                ? calendar.date(byAdding: .minute, value: 35, to: scheduled)
                : nil

            let actual: Date? = (status == .landed || status == .arrived || status == .departed)
                ? calendar.date(byAdding: .minute, value: Int.random(in: -5...10), to: scheduled)
                : nil

            let origin = direction == .arrival ? airport : tpe
            let destination = direction == .arrival ? tpe : airport

            return Flight(
                id: "\(direction.rawValue)-\(flightNum)",
                flightNumber: flightNum,
                airline: airline.name,
                airlineLogo: airline.code.lowercased(),
                direction: direction == .arrival ? "arrival" : "departure",
                origin: origin,
                destination: destination,
                scheduledTime: scheduled,
                estimatedTime: estimated,
                actualTime: actual,
                status: status,
                terminal: index % 2 == 0 ? "1" : "2",
                gate: ["A\(index + 1)", "B\(index + 2)", "C\(index + 3)", nil].randomElement()!,
                aircraft: ["Boeing 777-300ER", "Airbus A350-900", "Boeing 787-9", "Airbus A321neo"][index % 4],
                codeshares: index % 3 == 0 ? ["\(airlines[(index + 3) % airlines.count].code)\(200 + index)"] : []
            )
        }
    }
}
