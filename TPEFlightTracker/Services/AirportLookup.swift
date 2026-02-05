import Foundation

/// Static airport lookup table for common TPE-connected airports.
/// AirLabs schedules API only returns IATA codes, so we need this
/// to resolve airport names and cities for the UI.
enum AirportLookup {

    static func airport(for iata: String) -> Airport {
        if let known = airports[iata] {
            return known
        }
        return Airport(iata: iata, name: iata, city: iata)
    }

    private static let airports: [String: Airport] = [
        // Taiwan
        "TPE": Airport(iata: "TPE", name: "Taiwan Taoyuan International Airport", city: "Taipei"),
        "TSA": Airport(iata: "TSA", name: "Taipei Songshan Airport", city: "Taipei"),
        "KHH": Airport(iata: "KHH", name: "Kaohsiung International Airport", city: "Kaohsiung"),
        "RMQ": Airport(iata: "RMQ", name: "Taichung International Airport", city: "Taichung"),
        "TNN": Airport(iata: "TNN", name: "Tainan Airport", city: "Tainan"),
        "HUN": Airport(iata: "HUN", name: "Hualien Airport", city: "Hualien"),
        "TTT": Airport(iata: "TTT", name: "Taitung Airport", city: "Taitung"),
        "MZG": Airport(iata: "MZG", name: "Magong Airport", city: "Magong"),
        "KNH": Airport(iata: "KNH", name: "Kinmen Airport", city: "Kinmen"),
        "LZN": Airport(iata: "LZN", name: "Matsu Nangan Airport", city: "Matsu"),

        // Japan
        "NRT": Airport(iata: "NRT", name: "Narita International Airport", city: "Tokyo"),
        "HND": Airport(iata: "HND", name: "Haneda Airport", city: "Tokyo"),
        "KIX": Airport(iata: "KIX", name: "Kansai International Airport", city: "Osaka"),
        "ITM": Airport(iata: "ITM", name: "Osaka Itami Airport", city: "Osaka"),
        "CTS": Airport(iata: "CTS", name: "New Chitose Airport", city: "Sapporo"),
        "FUK": Airport(iata: "FUK", name: "Fukuoka Airport", city: "Fukuoka"),
        "NGO": Airport(iata: "NGO", name: "Chubu Centrair Airport", city: "Nagoya"),
        "OKA": Airport(iata: "OKA", name: "Naha Airport", city: "Okinawa"),
        "SDJ": Airport(iata: "SDJ", name: "Sendai Airport", city: "Sendai"),
        "HIJ": Airport(iata: "HIJ", name: "Hiroshima Airport", city: "Hiroshima"),
        "KOJ": Airport(iata: "KOJ", name: "Kagoshima Airport", city: "Kagoshima"),
        "TAK": Airport(iata: "TAK", name: "Takamatsu Airport", city: "Takamatsu"),
        "MYJ": Airport(iata: "MYJ", name: "Matsuyama Airport", city: "Matsuyama"),
        "KMQ": Airport(iata: "KMQ", name: "Komatsu Airport", city: "Kanazawa"),
        "MMJ": Airport(iata: "MMJ", name: "Matsumoto Airport", city: "Matsumoto"),
        "ISG": Airport(iata: "ISG", name: "Ishigaki Airport", city: "Ishigaki"),

        // Korea
        "ICN": Airport(iata: "ICN", name: "Incheon International Airport", city: "Seoul"),
        "GMP": Airport(iata: "GMP", name: "Gimpo International Airport", city: "Seoul"),
        "PUS": Airport(iata: "PUS", name: "Gimhae International Airport", city: "Busan"),
        "CJU": Airport(iata: "CJU", name: "Jeju International Airport", city: "Jeju"),
        "TAE": Airport(iata: "TAE", name: "Daegu International Airport", city: "Daegu"),

        // China & Hong Kong & Macau
        "HKG": Airport(iata: "HKG", name: "Hong Kong International Airport", city: "Hong Kong"),
        "MFM": Airport(iata: "MFM", name: "Macau International Airport", city: "Macau"),
        "PVG": Airport(iata: "PVG", name: "Pudong International Airport", city: "Shanghai"),
        "SHA": Airport(iata: "SHA", name: "Hongqiao International Airport", city: "Shanghai"),
        "PEK": Airport(iata: "PEK", name: "Beijing Capital International Airport", city: "Beijing"),
        "PKX": Airport(iata: "PKX", name: "Beijing Daxing International Airport", city: "Beijing"),
        "CAN": Airport(iata: "CAN", name: "Baiyun International Airport", city: "Guangzhou"),
        "SZX": Airport(iata: "SZX", name: "Shenzhen Bao'an International Airport", city: "Shenzhen"),
        "CTU": Airport(iata: "CTU", name: "Chengdu Shuangliu International Airport", city: "Chengdu"),
        "CKG": Airport(iata: "CKG", name: "Chongqing Jiangbei International Airport", city: "Chongqing"),
        "XMN": Airport(iata: "XMN", name: "Xiamen Gaoqi International Airport", city: "Xiamen"),
        "FOC": Airport(iata: "FOC", name: "Fuzhou Changle International Airport", city: "Fuzhou"),
        "NKG": Airport(iata: "NKG", name: "Nanjing Lukou International Airport", city: "Nanjing"),
        "HGH": Airport(iata: "HGH", name: "Hangzhou Xiaoshan International Airport", city: "Hangzhou"),
        "WUH": Airport(iata: "WUH", name: "Wuhan Tianhe International Airport", city: "Wuhan"),
        "CSX": Airport(iata: "CSX", name: "Changsha Huanghua International Airport", city: "Changsha"),
        "KMG": Airport(iata: "KMG", name: "Kunming Changshui International Airport", city: "Kunming"),
        "TSN": Airport(iata: "TSN", name: "Tianjin Binhai International Airport", city: "Tianjin"),

        // Southeast Asia
        "SIN": Airport(iata: "SIN", name: "Changi Airport", city: "Singapore"),
        "BKK": Airport(iata: "BKK", name: "Suvarnabhumi Airport", city: "Bangkok"),
        "DMK": Airport(iata: "DMK", name: "Don Mueang International Airport", city: "Bangkok"),
        "CNX": Airport(iata: "CNX", name: "Chiang Mai International Airport", city: "Chiang Mai"),
        "MNL": Airport(iata: "MNL", name: "Ninoy Aquino International Airport", city: "Manila"),
        "CEB": Airport(iata: "CEB", name: "Mactan-Cebu International Airport", city: "Cebu"),
        "CRK": Airport(iata: "CRK", name: "Clark International Airport", city: "Clark"),
        "KUL": Airport(iata: "KUL", name: "Kuala Lumpur International Airport", city: "Kuala Lumpur"),
        "SGN": Airport(iata: "SGN", name: "Tan Son Nhat International Airport", city: "Ho Chi Minh City"),
        "HAN": Airport(iata: "HAN", name: "Noi Bai International Airport", city: "Hanoi"),
        "DAD": Airport(iata: "DAD", name: "Da Nang International Airport", city: "Da Nang"),
        "REP": Airport(iata: "REP", name: "Siem Reap International Airport", city: "Siem Reap"),
        "PNH": Airport(iata: "PNH", name: "Phnom Penh International Airport", city: "Phnom Penh"),
        "RGN": Airport(iata: "RGN", name: "Yangon International Airport", city: "Yangon"),
        "CGK": Airport(iata: "CGK", name: "Soekarno-Hatta International Airport", city: "Jakarta"),
        "DPS": Airport(iata: "DPS", name: "Ngurah Rai International Airport", city: "Bali"),

        // South Asia & Middle East
        "DEL": Airport(iata: "DEL", name: "Indira Gandhi International Airport", city: "New Delhi"),
        "BOM": Airport(iata: "BOM", name: "Chhatrapati Shivaji International Airport", city: "Mumbai"),
        "DXB": Airport(iata: "DXB", name: "Dubai International Airport", city: "Dubai"),
        "DOH": Airport(iata: "DOH", name: "Hamad International Airport", city: "Doha"),
        "IST": Airport(iata: "IST", name: "Istanbul Airport", city: "Istanbul"),

        // Oceania
        "SYD": Airport(iata: "SYD", name: "Sydney Airport", city: "Sydney"),
        "MEL": Airport(iata: "MEL", name: "Melbourne Airport", city: "Melbourne"),
        "BNE": Airport(iata: "BNE", name: "Brisbane Airport", city: "Brisbane"),
        "AKL": Airport(iata: "AKL", name: "Auckland Airport", city: "Auckland"),
        "GUM": Airport(iata: "GUM", name: "Antonio B. Won Pat International Airport", city: "Guam"),
        "PLQ": Airport(iata: "PLQ", name: "Palau International Airport", city: "Palau"),

        // North America
        "LAX": Airport(iata: "LAX", name: "Los Angeles International Airport", city: "Los Angeles"),
        "SFO": Airport(iata: "SFO", name: "San Francisco International Airport", city: "San Francisco"),
        "JFK": Airport(iata: "JFK", name: "John F. Kennedy International Airport", city: "New York"),
        "EWR": Airport(iata: "EWR", name: "Newark Liberty International Airport", city: "Newark"),
        "SEA": Airport(iata: "SEA", name: "Seattle-Tacoma International Airport", city: "Seattle"),
        "ORD": Airport(iata: "ORD", name: "O'Hare International Airport", city: "Chicago"),
        "IAD": Airport(iata: "IAD", name: "Dulles International Airport", city: "Washington D.C."),
        "YVR": Airport(iata: "YVR", name: "Vancouver International Airport", city: "Vancouver"),
        "HNL": Airport(iata: "HNL", name: "Daniel K. Inouye International Airport", city: "Honolulu"),
        "ANC": Airport(iata: "ANC", name: "Ted Stevens Anchorage International Airport", city: "Anchorage"),

        // Europe
        "LHR": Airport(iata: "LHR", name: "Heathrow Airport", city: "London"),
        "LGW": Airport(iata: "LGW", name: "Gatwick Airport", city: "London"),
        "CDG": Airport(iata: "CDG", name: "Charles de Gaulle Airport", city: "Paris"),
        "AMS": Airport(iata: "AMS", name: "Schiphol Airport", city: "Amsterdam"),
        "FRA": Airport(iata: "FRA", name: "Frankfurt Airport", city: "Frankfurt"),
        "MUC": Airport(iata: "MUC", name: "Munich Airport", city: "Munich"),
        "FCO": Airport(iata: "FCO", name: "Fiumicino Airport", city: "Rome"),
        "VIE": Airport(iata: "VIE", name: "Vienna International Airport", city: "Vienna"),
        "ZRH": Airport(iata: "ZRH", name: "Zurich Airport", city: "Zurich"),
        "PRG": Airport(iata: "PRG", name: "Vaclav Havel Airport", city: "Prague"),
        "MAD": Airport(iata: "MAD", name: "Adolfo Suarez Madrid-Barajas Airport", city: "Madrid"),
        "BCN": Airport(iata: "BCN", name: "Barcelona-El Prat Airport", city: "Barcelona"),
        "HEL": Airport(iata: "HEL", name: "Helsinki-Vantaa Airport", city: "Helsinki"),
        "CPH": Airport(iata: "CPH", name: "Copenhagen Airport", city: "Copenhagen"),
        "ARN": Airport(iata: "ARN", name: "Stockholm Arlanda Airport", city: "Stockholm"),
    ]
}
