import XCTest
import CoreLocation
@testable import TPEFlightTracker

final class TripSuggestionServiceTests: XCTestCase {

    var sut: TripSuggestionService!

    override func setUp() {
        super.setUp()
        sut = TripSuggestionService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - getAllSuggestions Tests

    func testGetAllSuggestionsReturnsNonEmpty() {
        let suggestions = sut.getAllSuggestions()

        XCTAssertFalse(suggestions.isEmpty)
    }

    func testAllSuggestionsHaveRequiredFields() {
        let suggestions = sut.getAllSuggestions()

        for suggestion in suggestions {
            XCTAssertFalse(suggestion.name.isEmpty, "Suggestion should have a name")
            XCTAssertFalse(suggestion.description.isEmpty, "Suggestion should have a description")
            XCTAssertFalse(suggestion.destinations.isEmpty, "Suggestion should have destinations")
        }
    }

    // MARK: - getSuggestions(for category:) Tests

    func testGetSuggestionsForFirstTimeCategory() {
        let suggestions = sut.getSuggestions(for: .firstTime)

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy { $0.category == .firstTime })
    }

    func testGetSuggestionsForCulturalCategory() {
        let suggestions = sut.getSuggestions(for: .cultural)

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy { $0.category == .cultural })
    }

    func testGetSuggestionsForFoodieCategory() {
        let suggestions = sut.getSuggestions(for: .foodie)

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy { $0.category == .foodie })
    }

    func testGetSuggestionsForNatureCategory() {
        let suggestions = sut.getSuggestions(for: .nature)

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy { $0.category == .nature })
    }

    // MARK: - getSuggestions(for duration:) Tests

    func testGetSuggestionsForFullDayDuration() {
        let suggestions = sut.getSuggestions(for: .fullDay)

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy { $0.duration == .fullDay })
    }

    func testGetSuggestionsForHalfDayDuration() {
        let suggestions = sut.getSuggestions(for: .halfDay)

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy { $0.duration == .halfDay })
    }

    // MARK: - getTrendingSuggestions Tests

    func testGetTrendingSuggestions() {
        let suggestions = sut.getTrendingSuggestions()

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy {
            $0.category == .trending || $0.tags.contains("trending")
        })
    }

    // MARK: - getRecommendedForFirstTimers Tests

    func testGetRecommendedForFirstTimers() {
        let suggestions = sut.getRecommendedForFirstTimers()

        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy {
            $0.category == .firstTime || $0.tags.contains("must-see")
        })
    }

    // MARK: - searchSuggestions Tests

    func testSearchSuggestionsWithDestinationName() {
        let results = sut.searchSuggestions(query: "Taipei 101")

        XCTAssertFalse(results.isEmpty)
    }

    func testSearchSuggestionsWithTag() {
        let results = sut.searchSuggestions(query: "food")

        XCTAssertFalse(results.isEmpty)
    }

    func testSearchSuggestionsCaseInsensitive() {
        let resultsLower = sut.searchSuggestions(query: "taipei")
        let resultsUpper = sut.searchSuggestions(query: "TAIPEI")

        XCTAssertEqual(resultsLower.count, resultsUpper.count)
    }

    func testSearchSuggestionsNoResults() {
        let results = sut.searchSuggestions(query: "xyznonexistent123")

        XCTAssertTrue(results.isEmpty)
    }

    func testSearchSuggestionsEmptyQuery() {
        let results = sut.searchSuggestions(query: "")

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Model Tests

    func testTripSuggestionToTrip() {
        let suggestion = sut.getAllSuggestions().first!
        let startDate = Date()

        let trip = suggestion.toTrip(startDate: startDate)

        XCTAssertEqual(trip.name, suggestion.name)
        XCTAssertEqual(trip.startDate, startDate)
        XCTAssertEqual(trip.destinations.count, suggestion.destinations.count)
    }

    func testTripSuggestionTotalEstimatedTime() {
        let suggestion = sut.getAllSuggestions().first!
        let expectedTotal = suggestion.destinations.map(\.estimatedTimeMinutes).reduce(0, +)

        XCTAssertEqual(suggestion.totalEstimatedTimeMinutes, expectedTotal)
    }

    func testSuggestedDestinationToTripDestination() {
        let suggestion = sut.getAllSuggestions().first!
        let suggestedDest = suggestion.destinations.first!

        let tripDest = suggestedDest.toTripDestination()

        XCTAssertEqual(tripDest.name, suggestedDest.name)
        XCTAssertEqual(tripDest.address, suggestedDest.address)
        XCTAssertEqual(tripDest.latitude, suggestedDest.latitude)
        XCTAssertEqual(tripDest.longitude, suggestedDest.longitude)
        XCTAssertEqual(tripDest.travelMode, suggestedDest.suggestedTravelMode)
    }

    // MARK: - Category Tests

    func testAllCategoriesHaveDisplayNames() {
        for category in SuggestionCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertFalse(category.systemImage.isEmpty)
            XCTAssertFalse(category.welcomeMessage.isEmpty)
        }
    }

    func testAllDurationsHaveDisplayNames() {
        for duration in TripDuration.allCases {
            XCTAssertFalse(duration.displayName.isEmpty)
            XCTAssertGreaterThan(duration.days, 0)
        }
    }

    func testAllBudgetLevelsHaveDisplayNames() {
        for level in BudgetLevel.allCases {
            XCTAssertFalse(level.displayName.isEmpty)
            XCTAssertFalse(level.dollarSigns.isEmpty)
            XCTAssertFalse(level.description.isEmpty)
        }
    }

    func testAllDifficultyLevelsHaveDisplayNames() {
        for difficulty in DifficultyLevel.allCases {
            XCTAssertFalse(difficulty.displayName.isEmpty)
            XCTAssertFalse(difficulty.systemImage.isEmpty)
            XCTAssertFalse(difficulty.description.isEmpty)
        }
    }

    // MARK: - Destination Validation Tests

    func testAllDestinationsHaveValidCoordinates() {
        let suggestions = sut.getAllSuggestions()

        for suggestion in suggestions {
            for destination in suggestion.destinations {
                XCTAssertTrue(destination.latitude >= -90 && destination.latitude <= 90,
                              "Invalid latitude for \(destination.name)")
                XCTAssertTrue(destination.longitude >= -180 && destination.longitude <= 180,
                              "Invalid longitude for \(destination.name)")
            }
        }
    }

    func testAllDestinationsHavePositiveEstimatedTime() {
        let suggestions = sut.getAllSuggestions()

        for suggestion in suggestions {
            for destination in suggestion.destinations {
                XCTAssertGreaterThan(destination.estimatedTimeMinutes, 0,
                                     "Estimated time should be positive for \(destination.name)")
            }
        }
    }

    func testDestinationsAreOrderedCorrectly() {
        let suggestions = sut.getAllSuggestions()

        for suggestion in suggestions {
            for (index, destination) in suggestion.destinations.enumerated() {
                XCTAssertEqual(destination.order, index,
                               "Destination order mismatch for \(destination.name) in \(suggestion.name)")
            }
        }
    }

    // MARK: - Formatting Tests

    func testSuggestedDestinationFormattedEstimatedTime() {
        let dest1 = SuggestedDestination(
            name: "Test",
            address: "Test",
            latitude: 25.0,
            longitude: 121.5,
            estimatedTimeMinutes: 30
        )
        XCTAssertEqual(dest1.formattedEstimatedTime, "30 min")

        let dest2 = SuggestedDestination(
            name: "Test",
            address: "Test",
            latitude: 25.0,
            longitude: 121.5,
            estimatedTimeMinutes: 60
        )
        XCTAssertEqual(dest2.formattedEstimatedTime, "1 hour")

        let dest3 = SuggestedDestination(
            name: "Test",
            address: "Test",
            latitude: 25.0,
            longitude: 121.5,
            estimatedTimeMinutes: 90
        )
        XCTAssertEqual(dest3.formattedEstimatedTime, "1h 30m")
    }

    func testBudgetLevelDollarSigns() {
        XCTAssertEqual(BudgetLevel.budget.dollarSigns, "$")
        XCTAssertEqual(BudgetLevel.moderate.dollarSigns, "$$")
        XCTAssertEqual(BudgetLevel.premium.dollarSigns, "$$$")
        XCTAssertEqual(BudgetLevel.luxury.dollarSigns, "$$$$")
    }
}

// MARK: - Mock Suggestion Service for ViewModel Tests

class MockTripSuggestionService: TripSuggestionServiceProtocol {
    var suggestionsToReturn: [TripSuggestion] = []
    var getAllSuggestionsCallCount = 0
    var getSuggestionsForCategoryCallCount = 0
    var searchCallCount = 0
    var lastSearchQuery: String?

    func getAllSuggestions() -> [TripSuggestion] {
        getAllSuggestionsCallCount += 1
        return suggestionsToReturn
    }

    func getSuggestions(for category: SuggestionCategory) -> [TripSuggestion] {
        getSuggestionsForCategoryCallCount += 1
        return suggestionsToReturn.filter { $0.category == category }
    }

    func getSuggestions(for duration: TripDuration) -> [TripSuggestion] {
        return suggestionsToReturn.filter { $0.duration == duration }
    }

    func getTrendingSuggestions() -> [TripSuggestion] {
        return suggestionsToReturn.filter { $0.category == .trending }
    }

    func getRecommendedForFirstTimers() -> [TripSuggestion] {
        return suggestionsToReturn.filter { $0.category == .firstTime }
    }

    func searchSuggestions(query: String) -> [TripSuggestion] {
        searchCallCount += 1
        lastSearchQuery = query
        guard !query.isEmpty else { return [] }
        return suggestionsToReturn.filter {
            $0.name.lowercased().contains(query.lowercased())
        }
    }
}
