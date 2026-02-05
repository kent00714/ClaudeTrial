import Foundation

/// Raw JSON response from AirLabs /schedules endpoint
struct AirLabsScheduleResponse: Decodable {
    let response: [AirLabsSchedule]
}

/// A single schedule entry from AirLabs API
struct AirLabsSchedule: Decodable {
    let airlineIata: String?
    let airlineIcao: String?
    let flightIata: String?
    let flightIcao: String?
    let flightNumber: String?
    let depIata: String?
    let depIcao: String?
    let depTerminal: String?
    let depGate: String?
    let depTime: String?
    let depTimeUtc: String?
    let depEstimated: String?
    let depEstimatedUtc: String?
    let depActual: String?
    let depActualUtc: String?
    let arrIata: String?
    let arrIcao: String?
    let arrTerminal: String?
    let arrGate: String?
    let arrTime: String?
    let arrTimeUtc: String?
    let arrEstimated: String?
    let arrEstimatedUtc: String?
    let arrActual: String?
    let arrActualUtc: String?
    let status: String?
    let duration: Int?
    let delayed: Int?
    let aircraftIcao: String?
    let csAirlineIata: String?
    let csFlightIata: String?
    let csFlightNumber: String?

    enum CodingKeys: String, CodingKey {
        case airlineIata = "airline_iata"
        case airlineIcao = "airline_icao"
        case flightIata = "flight_iata"
        case flightIcao = "flight_icao"
        case flightNumber = "flight_number"
        case depIata = "dep_iata"
        case depIcao = "dep_icao"
        case depTerminal = "dep_terminal"
        case depGate = "dep_gate"
        case depTime = "dep_time"
        case depTimeUtc = "dep_time_utc"
        case depEstimated = "dep_estimated"
        case depEstimatedUtc = "dep_estimated_utc"
        case depActual = "dep_actual"
        case depActualUtc = "dep_actual_utc"
        case arrIata = "arr_iata"
        case arrIcao = "arr_icao"
        case arrTerminal = "arr_terminal"
        case arrGate = "arr_gate"
        case arrTime = "arr_time"
        case arrTimeUtc = "arr_time_utc"
        case arrEstimated = "arr_estimated"
        case arrEstimatedUtc = "arr_estimated_utc"
        case arrActual = "arr_actual"
        case arrActualUtc = "arr_actual_utc"
        case status
        case duration
        case delayed
        case aircraftIcao = "aircraft_icao"
        case csAirlineIata = "cs_airline_iata"
        case csFlightIata = "cs_flight_iata"
        case csFlightNumber = "cs_flight_number"
    }
}
