import Foundation

/// Static airline name lookup for common carriers at TPE.
/// AirLabs schedules API returns airline_iata codes only.
enum AirlineLookup {

    static func airlineName(for iata: String) -> String {
        airlines[iata] ?? iata
    }

    private static let airlines: [String: String] = [
        // Taiwan
        "CI": "China Airlines",
        "BR": "EVA Air",
        "JX": "Starlux Airlines",
        "IT": "Tigerair Taiwan",
        "B7": "Uni Air",
        "AE": "Mandarin Airlines",
        "FE": "Far Eastern Air Transport",

        // Japan
        "JL": "Japan Airlines",
        "NH": "ANA",
        "MM": "Peach Aviation",
        "GK": "Jetstar Japan",
        "7C": "Jeju Air",
        "BC": "Skymark Airlines",

        // Korea
        "KE": "Korean Air",
        "OZ": "Asiana Airlines",
        "TW": "T'way Air",
        "LJ": "Jin Air",
        "ZE": "Eastar Jet",
        "BX": "Air Busan",
        "RF": "Aero K",
        "RS": "Air Seoul",

        // China
        "CA": "Air China",
        "MU": "China Eastern Airlines",
        "CZ": "China Southern Airlines",
        "HU": "Hainan Airlines",
        "MF": "Xiamen Airlines",
        "ZH": "Shenzhen Airlines",
        "3U": "Sichuan Airlines",
        "FM": "Shanghai Airlines",
        "SC": "Shandong Airlines",
        "GS": "Tianjin Airlines",

        // Hong Kong / Macau
        "CX": "Cathay Pacific",
        "KA": "Cathay Dragon",
        "HX": "Hong Kong Airlines",
        "UO": "HK Express",
        "NX": "Air Macau",

        // Southeast Asia
        "SQ": "Singapore Airlines",
        "TR": "Scoot",
        "TG": "Thai Airways",
        "FD": "Thai AirAsia",
        "PR": "Philippine Airlines",
        "5J": "Cebu Pacific",
        "MH": "Malaysia Airlines",
        "AK": "AirAsia",
        "VN": "Vietnam Airlines",
        "VJ": "VietJet Air",
        "QZ": "Indonesia AirAsia",
        "GA": "Garuda Indonesia",
        "BI": "Royal Brunei Airlines",
        "MI": "SilkAir",

        // Middle East
        "EK": "Emirates",
        "QR": "Qatar Airways",
        "TK": "Turkish Airlines",

        // Oceania
        "QF": "Qantas",
        "NZ": "Air New Zealand",

        // North America
        "AA": "American Airlines",
        "UA": "United Airlines",
        "DL": "Delta Air Lines",
        "AC": "Air Canada",
        "HA": "Hawaiian Airlines",

        // Europe
        "BA": "British Airways",
        "AF": "Air France",
        "LH": "Lufthansa",
        "KL": "KLM Royal Dutch Airlines",
        "AY": "Finnair",
        "SK": "Scandinavian Airlines",
        "LX": "Swiss International Air Lines",
        "OS": "Austrian Airlines",
    ]
}
