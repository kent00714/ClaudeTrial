import Foundation

protocol TripServiceProtocol {
    func loadTrips() -> [Trip]
    func saveTrips(_ trips: [Trip])
    func addTrip(_ trip: Trip)
    func updateTrip(_ trip: Trip)
    func deleteTrip(id: UUID)
    func getTrip(id: UUID) -> Trip?
}

class TripService: TripServiceProtocol {

    private let storageKey = "com.tpeflighttracker.trips"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadTrips() -> [Trip] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }
        do {
            let trips = try JSONDecoder().decode([Trip].self, from: data)
            return trips.sorted { $0.startDate < $1.startDate }
        } catch {
            print("Failed to decode trips: \(error)")
            return []
        }
    }

    func saveTrips(_ trips: [Trip]) {
        do {
            let data = try JSONEncoder().encode(trips)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode trips: \(error)")
        }
    }

    func addTrip(_ trip: Trip) {
        var trips = loadTrips()
        trips.append(trip)
        saveTrips(trips)
    }

    func updateTrip(_ trip: Trip) {
        var trips = loadTrips()
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            let updatedTrip = Trip(
                id: trip.id,
                name: trip.name,
                startDate: trip.startDate,
                endDate: trip.endDate,
                destinations: trip.destinations,
                createdAt: trip.createdAt,
                updatedAt: Date(),
                notes: trip.notes,
                sourceSuggestionName: trip.sourceSuggestionName,
                linkedFlightNumber: trip.linkedFlightNumber
            )
            trips[index] = updatedTrip
            saveTrips(trips)
        }
    }

    func deleteTrip(id: UUID) {
        var trips = loadTrips()
        trips.removeAll { $0.id == id }
        saveTrips(trips)
    }

    func getTrip(id: UUID) -> Trip? {
        loadTrips().first { $0.id == id }
    }
}
