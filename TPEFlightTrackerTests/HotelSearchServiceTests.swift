import XCTest
import CoreLocation
@testable import TPEFlightTracker

final class HotelSearchServiceTests: XCTestCase {

    private var sut: HotelSearchService!

    override func setUp() {
        super.setUp()
        sut = HotelSearchService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testSearchHotelsInMatchesAreaNameHotelNameNeighborhoodAndLocalName() {
        let byArea = sut.searchHotels(in: "Taipei")
        XCTAssertFalse(byArea.isEmpty)
        XCTAssertTrue(byArea.allSatisfy { $0.hotel.area == "Taipei" })

        let byHotelName = sut.searchHotels(in: "Grand Hyatt")
        XCTAssertTrue(byHotelName.contains { $0.hotel.id == "grand_hyatt" })

        let byNeighborhood = sut.searchHotels(in: "Xinyi District")
        XCTAssertTrue(byNeighborhood.contains { $0.hotel.neighborhood == "Xinyi District" })

        let byLocalName = sut.searchHotels(in: "君悅")
        XCTAssertTrue(byLocalName.contains { $0.hotel.id == "grand_hyatt" })
    }

    func testSearchHotelsInSortByRatingReturnsDescendingOrder() {
        let results = sut.searchHotels(in: "Taipei", sortBy: .rating)
        XCTAssertGreaterThan(results.count, 1)

        let ratings = results.map { $0.hotel.rating }
        XCTAssertEqual(ratings, ratings.sorted(by: >))
    }

    func testSearchHotelsInSortByMostReviewsReturnsDescendingOrder() {
        let results = sut.searchHotels(in: "Taipei", sortBy: .ratingCount)
        XCTAssertGreaterThan(results.count, 1)

        let reviewCounts = results.map { $0.hotel.reviewCount }
        XCTAssertEqual(reviewCounts, reviewCounts.sorted(by: >))
    }

    func testSearchHotelsInSortByPriceReturnsAscendingOrder() {
        let results = sut.searchHotels(in: "Taipei", sortBy: .priceEstimate)
        XCTAssertGreaterThan(results.count, 1)

        let prices = results.map { $0.hotel.priceLevel }
        XCTAssertEqual(prices, prices.sorted())
    }

    func testSearchHotelsNearFiltersByRadiusAndSortsByDistance() {
        let taipei101 = CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654)

        let tightRadius = sut.searchHotels(near: taipei101, radiusKm: 1.0, sortBy: .distance)
        let wideRadius = sut.searchHotels(near: taipei101, radiusKm: 5.0, sortBy: .distance)

        XCTAssertFalse(tightRadius.isEmpty)
        XCTAssertGreaterThan(wideRadius.count, tightRadius.count)
        XCTAssertTrue(tightRadius.allSatisfy { $0.distanceKm <= 1.0 })

        let distances = wideRadius.map { $0.distanceKm }
        XCTAssertEqual(distances, distances.sorted())
    }

    func testGenerateBookingLinksIncludesExpectedProvidersAndHttpsLinks() {
        guard let hotel = sut.searchHotels(in: "Taipei").first?.hotel else {
            return XCTFail("Expected at least one hotel for test")
        }

        let links = sut.generateBookingLinks(for: hotel)

        XCTAssertEqual(links.count, BookingProvider.allCases.count)
        XCTAssertEqual(Set(links.map(\.provider)), Set(BookingProvider.allCases))
        XCTAssertTrue(links.allSatisfy { $0.url.hasPrefix("https://") })
        XCTAssertTrue(links.allSatisfy { URL(string: $0.url) != nil })
    }
}
