import Foundation

protocol FlightServiceProtocol {
    func fetchFlights(direction: FlightDirection) async throws -> [Flight]
}

class FlightService: FlightServiceProtocol {

    private let session: URLSession
    private let apiKey: String
    private let baseURL: String

    init(
        session: URLSession = .shared,
        apiKey: String = APIConfig.airLabsAPIKey,
        baseURL: String = APIConfig.airLabsBaseURL
    ) {
        self.session = session
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    // MARK: - Public API

    func fetchFlights(direction: FlightDirection) async throws -> [Flight] {
        // Fall back to mock data if no API key is configured
        guard apiKey != "YOUR_API_KEY_HERE" else {
            return Self.mockFlights(direction: direction)
        }

        let schedules = try await fetchSchedules(direction: direction)
        return schedules.compactMap { schedule in
            Self.convert(schedule: schedule, direction: direction)
        }
    }

    // MARK: - AirLabs API

    private func fetchSchedules(direction: FlightDirection) async throws -> [AirLabsSchedule] {
        let paramKey = direction == .arrival ? "arr_iata" : "dep_iata"
        let urlString = "\(baseURL)/schedules?\(paramKey)=\(APIConfig.airportCode)&api_key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw FlightServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlightServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw FlightServiceError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(AirLabsScheduleResponse.self, from: data)
        return decoded.response
    }

    // MARK: - Conversion

    private static func convert(schedule: AirLabsSchedule, direction: FlightDirection) -> Flight? {
        guard let flightIata = schedule.flightIata,
              let depIata = schedule.depIata,
              let arrIata = schedule.arrIata,
              let depTimeStr = schedule.depTime,
              let arrTimeStr = schedule.arrTime else {
            return nil
        }

        let origin = AirportLookup.airport(for: depIata)
        let destination = AirportLookup.airport(for: arrIata)

        let airlineName = schedule.airlineIata.map { AirlineLookup.airlineName(for: $0) } ?? flightIata
        let airlineLogo = (schedule.airlineIata ?? "").lowercased()

        let scheduledTime: Date
        let estimatedTime: Date?
        let actualTime: Date?

        if direction == .arrival {
            scheduledTime = parseLocalTime(arrTimeStr) ?? Date()
            estimatedTime = schedule.arrEstimated.flatMap { parseLocalTime($0) }
            actualTime = schedule.arrActual.flatMap { parseLocalTime($0) }
        } else {
            scheduledTime = parseLocalTime(depTimeStr) ?? Date()
            estimatedTime = schedule.depEstimated.flatMap { parseLocalTime($0) }
            actualTime = schedule.depActual.flatMap { parseLocalTime($0) }
        }

        let terminal: String
        let gate: String?
        if direction == .arrival {
            terminal = schedule.arrTerminal ?? "--"
            gate = schedule.arrGate
        } else {
            terminal = schedule.depTerminal ?? "--"
            gate = schedule.depGate
        }

        let status = mapStatus(schedule.status, delayed: schedule.delayed)

        var codeshares: [String] = []
        if let csFlightIata = schedule.csFlightIata {
            codeshares.append(csFlightIata)
        }

        let id = "\(direction == .arrival ? "arr" : "dep")-\(flightIata)-\(depTimeStr)"

        return Flight(
            id: id,
            flightNumber: flightIata,
            airline: airlineName,
            airlineLogo: airlineLogo,
            direction: direction == .arrival ? "arrival" : "departure",
            origin: origin,
            destination: destination,
            scheduledTime: scheduledTime,
            estimatedTime: estimatedTime,
            actualTime: actualTime,
            status: status,
            terminal: terminal,
            gate: gate,
            aircraft: schedule.aircraftIcao,
            codeshares: codeshares
        )
    }

    private static func mapStatus(_ status: String?, delayed: Int?) -> FlightStatus {
        guard let status = status?.lowercased() else { return .scheduled }

        if let delayed = delayed, delayed > 0 {
            return .delayed
        }

        switch status {
        case "scheduled": return .scheduled
        case "active", "en-route", "en_route": return .inAir
        case "landed": return .landed
        case "cancelled": return .cancelled
        case "incident", "diverted": return .delayed
        default: return .scheduled
        }
    }

    private static func parseLocalTime(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // AirLabs returns local times as "YYYY-MM-DD HH:mm"
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        // TPE is in Asia/Taipei timezone
        formatter.timeZone = TimeZone(identifier: "Asia/Taipei")
        return formatter.date(from: string)
    }

    // MARK: - Mock Data (fallback when no API key)

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

    static func mockFlights(direction: FlightDirection) -> [Flight] {
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

// MARK: - Errors

enum FlightServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server returned error (HTTP \(code))"
        }
    }
}
