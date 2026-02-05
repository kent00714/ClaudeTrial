import SwiftUI

// MARK: - Hotel Search View

struct HotelSearchView: View {
    @StateObject private var viewModel = HotelSearchViewModel()
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Form
                searchForm

                // Results
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Searching hotels...")
                    Spacer()
                } else if viewModel.hasSearched && viewModel.results.isEmpty {
                    ContentUnavailableView {
                        Label("No Hotels Found", systemImage: "building.2")
                    } description: {
                        Text("Try adjusting your search criteria or dates.")
                    }
                } else if !viewModel.results.isEmpty {
                    resultsList
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue.opacity(0.5))
                        Text("Search for hotels in Taiwan")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Compare prices from Booking.com, Agoda, Expedia and more")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Hotels")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                HotelFilterView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Search Form

    private var searchForm: some View {
        VStack(spacing: 12) {
            // Location
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.red)
                TextField("City or destination", text: $viewModel.location)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Dates
            HStack(spacing: 12) {
                // Check-in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Check-in")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("", selection: $viewModel.checkIn, in: Date()..., displayedComponents: .date)
                        .labelsHidden()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Check-out
                VStack(alignment: .leading, spacing: 4) {
                    Text("Check-out")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("", selection: $viewModel.checkOut, in: viewModel.checkIn..., displayedComponents: .date)
                        .labelsHidden()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Guests and Rooms
            HStack(spacing: 12) {
                // Guests
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.blue)
                    Stepper("\(viewModel.guests) Guest\(viewModel.guests > 1 ? "s" : "")", value: $viewModel.guests, in: 1...10)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Search Button
            Button {
                Task {
                    await viewModel.search()
                }
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search Hotels")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.location.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Results List

    private var resultsList: some View {
        VStack(spacing: 0) {
            // Results header
            HStack {
                Text("\(viewModel.results.count) hotels found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()

                // Sort picker
                Menu {
                    ForEach(HotelSortOption.allCases) { option in
                        Button {
                            viewModel.sortBy = option
                            Task { await viewModel.search() }
                        } label: {
                            HStack {
                                Text(option.displayName)
                                if viewModel.sortBy == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Sort")
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))

            // Hotel list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.results) { result in
                        NavigationLink {
                            HotelDetailView(result: result, checkIn: viewModel.checkIn, checkOut: viewModel.checkOut)
                        } label: {
                            HotelResultCard(result: result, nights: viewModel.nights)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Hotel Result Card

struct HotelResultCard: View {
    let result: HotelSearchResult
    let nights: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Hotel info
            HStack(alignment: .top, spacing: 12) {
                // Placeholder image
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    // Stars
                    Text(result.hotel.starRatingDisplay)
                        .font(.caption)
                        .foregroundStyle(.orange)

                    // Name
                    Text(result.hotel.name)
                        .font(.headline)
                        .lineLimit(1)

                    // Local name
                    if let localName = result.hotel.nameLocal {
                        Text(localName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Location
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                        Text(result.hotel.neighborhood ?? result.hotel.address)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Rating
                VStack(spacing: 2) {
                    Text(result.hotel.formattedRating)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ratingColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(result.hotel.ratingDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("\(result.hotel.reviewCount) reviews")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Amenities
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(result.hotel.amenities.prefix(5)) { amenity in
                        HStack(spacing: 4) {
                            Image(systemName: amenity.systemImage)
                            Text(amenity.displayName)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                    }
                }
            }

            Divider()

            // Prices comparison
            HStack {
                // Provider count
                Text("Compare \(result.providerCount) sites")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Lowest price
                if let lowest = result.lowestPrice {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("from")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(lowest.formattedPricePerNight)
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                        Text("/night")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var ratingColor: Color {
        switch result.hotel.userRating {
        case 9.0...: return .green
        case 8.0..<9.0: return .blue
        case 7.0..<8.0: return .orange
        default: return .gray
        }
    }
}

// MARK: - Hotel Detail View

struct HotelDetailView: View {
    let result: HotelSearchResult
    let checkIn: Date
    let checkOut: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.hotel.starRatingDisplay)
                        .foregroundStyle(.orange)

                    Text(result.hotel.name)
                        .font(.title2.bold())

                    if let localName = result.hotel.nameLocal {
                        Text(localName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Rating
                    HStack(spacing: 8) {
                        Text(result.hotel.formattedRating)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text(result.hotel.ratingDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("(\(result.hotel.reviewCount) reviews)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()

                Divider()

                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Label("Location", systemImage: "mappin.circle.fill")
                        .font(.headline)

                    Text(result.hotel.address)
                        .font(.subheadline)

                    if let neighborhood = result.hotel.neighborhood {
                        Text(neighborhood)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let distance = result.hotel.distanceFromCenter {
                        Text("\(String(format: "%.1f", distance)) km from city center")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)

                Divider()

                // Amenities
                VStack(alignment: .leading, spacing: 12) {
                    Label("Amenities", systemImage: "checkmark.circle.fill")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                        ForEach(result.hotel.amenities) { amenity in
                            HStack(spacing: 6) {
                                Image(systemName: amenity.systemImage)
                                    .foregroundStyle(.blue)
                                Text(amenity.displayName)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                // Check-in/out times
                HStack(spacing: 24) {
                    VStack(alignment: .leading) {
                        Text("Check-in")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(result.hotel.checkInTime)
                            .font(.headline)
                    }

                    VStack(alignment: .leading) {
                        Text("Check-out")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(result.hotel.checkOutTime)
                            .font(.headline)
                    }
                }
                .padding(.horizontal)

                Divider()

                // Price Comparison
                VStack(alignment: .leading, spacing: 12) {
                    Label("Compare Prices", systemImage: "dollarsign.circle.fill")
                        .font(.headline)

                    ForEach(result.prices.sorted(by: { $0.pricePerNight < $1.pricePerNight })) { price in
                        PriceComparisonRow(price: price)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Hotel Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Price Comparison Row

struct PriceComparisonRow: View {
    let price: HotelPrice

    var body: some View {
        HStack {
            // Provider
            VStack(alignment: .leading, spacing: 2) {
                Text(price.provider.displayName)
                    .font(.subheadline.bold())

                HStack(spacing: 4) {
                    if price.includesBreakfast {
                        Label("Breakfast", systemImage: "cup.and.saucer.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                    if price.includesTax {
                        Text("Tax included")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Price and Book Button
            VStack(alignment: .trailing, spacing: 4) {
                Text(price.formattedPricePerNight)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let url = URL(string: price.bookingURL) {
                    Link(destination: url) {
                        Text("Book Now")
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Hotel Filter View

struct HotelFilterView: View {
    @ObservedObject var viewModel: HotelSearchViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Star Rating") {
                    Picker("Minimum Stars", selection: $viewModel.minStars) {
                        Text("Any").tag(Optional<Int>.none)
                        ForEach(1...5, id: \.self) { stars in
                            Text(String(repeating: "★", count: stars)).tag(Optional(stars))
                        }
                    }
                }

                Section("Price") {
                    Toggle("Set Max Price", isOn: Binding(
                        get: { viewModel.maxPrice != nil },
                        set: { viewModel.maxPrice = $0 ? 5000 : nil }
                    ))

                    if viewModel.maxPrice != nil {
                        Stepper(
                            "Max: NT$ \(Int(viewModel.maxPrice ?? 5000))",
                            value: Binding(
                                get: { viewModel.maxPrice ?? 5000 },
                                set: { viewModel.maxPrice = $0 }
                            ),
                            in: 1000...50000,
                            step: 500
                        )
                    }
                }

                Section("Sort By") {
                    Picker("Sort", selection: $viewModel.sortBy) {
                        ForEach(HotelSortOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        viewModel.resetFilters()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        dismiss()
                        Task { await viewModel.search() }
                    }
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class HotelSearchViewModel: ObservableObject {
    @Published var location: String = "Taipei"
    @Published var checkIn: Date = Date()
    @Published var checkOut: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @Published var guests: Int = 2
    @Published var rooms: Int = 1
    @Published var minStars: Int? = nil
    @Published var maxPrice: Double? = nil
    @Published var sortBy: HotelSortOption = .recommended

    @Published var results: [HotelSearchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false

    private let service = HotelSearchService.shared

    var nights: Int {
        let days = Calendar.current.dateComponents([.day], from: checkIn, to: checkOut).day ?? 1
        return max(1, days)
    }

    func search() async {
        isLoading = true
        errorMessage = nil
        hasSearched = true

        let request = HotelSearchRequest(
            location: location,
            latitude: nil,
            longitude: nil,
            checkIn: checkIn,
            checkOut: checkOut,
            guests: guests,
            rooms: rooms,
            minStars: minStars,
            maxPrice: maxPrice,
            amenities: nil,
            sortBy: sortBy
        )

        do {
            results = try await service.searchHotels(request: request)
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isLoading = false
    }

    func resetFilters() {
        minStars = nil
        maxPrice = nil
        sortBy = .recommended
    }
}

#Preview {
    HotelSearchView()
}
