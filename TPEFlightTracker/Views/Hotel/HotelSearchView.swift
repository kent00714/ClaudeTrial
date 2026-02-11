import SwiftUI
import CoreLocation

// MARK: - Hotel Search View

struct HotelSearchView: View {
    @State private var searchText = ""
    @State private var sortBy: HotelSortOption = .rating
    @State private var results: [HotelSearchResult] = []
    @State private var selectedHotel: HotelSearchResult?

    private let service = HotelSearchService.shared
    private let areas = ["Taipei", "Jiufen", "Beitou", "Taroko", "Sun Moon Lake", "Kaohsiung", "Tainan"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search area or hotel name", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            search()
                        }
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            results = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

                if results.isEmpty && searchText.isEmpty {
                    // Quick search buttons
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Popular Areas")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                                ForEach(areas, id: \.self) { area in
                                    Button {
                                        searchText = area
                                        search()
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: areaIcon(for: area))
                                                .font(.title2)
                                            Text(area)
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)

                            Spacer()
                        }
                        .padding(.top)
                    }
                } else if results.isEmpty {
                    ContentUnavailableView {
                        Label("No Hotels Found", systemImage: "building.2")
                    } description: {
                        Text("Try searching for a different area")
                    }
                } else {
                    // Sort picker
                    HStack {
                        Text("\(results.count) hotels")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Menu {
                            ForEach(HotelSortOption.allCases) { option in
                                Button {
                                    sortBy = option
                                    search()
                                } label: {
                                    HStack {
                                        Image(systemName: option.systemImage)
                                        Text(LocalizedStringKey(option.displayName))
                                        if sortBy == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: sortBy.systemImage)
                                Text(LocalizedStringKey(sortBy.displayName))
                                Image(systemName: "chevron.down")
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // Results list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(results) { result in
                                HotelCard(result: result)
                                    .onTapGesture {
                                        selectedHotel = result
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Hotels")
            .sheet(item: $selectedHotel) { result in
                HotelDetailSheet(result: result)
            }
        }
    }

    private func search() {
        results = service.searchHotels(in: searchText, sortBy: sortBy)
    }

    private func areaIcon(for area: String) -> String {
        switch area {
        case "Taipei": return "building.2.fill"
        case "Jiufen": return "mountain.2.fill"
        case "Beitou": return "drop.fill"
        case "Taroko": return "mountain.2.fill"
        case "Sun Moon Lake": return "water.waves"
        case "Kaohsiung": return "building.fill"
        case "Tainan": return "building.columns.fill"
        default: return "mappin.circle.fill"
        }
    }
}

// MARK: - Hotel Card

struct HotelCard: View {
    let result: HotelSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Hotel icon placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 70, height: 70)
                    .overlay {
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    // Star rating
                    Text(result.hotel.starDisplay)
                        .font(.caption)
                        .foregroundStyle(.orange)

                    // Name
                    Text(result.hotel.name)
                        .font(.headline)
                        .lineLimit(1)

                    // Local name
                    Text(result.hotel.nameLocal)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Location
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                        Text(result.hotel.neighborhood)
                        if result.distanceKm > 0 {
                            Text("• \(result.formattedDistance)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Rating
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.orange)
                        Text(result.hotel.formattedRating)
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)

                    Text("\(result.hotel.reviewCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(result.hotel.priceLevelDisplay)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            // Amenities
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(result.hotel.amenities.prefix(4), id: \.self) { amenity in
                        Text(amenity)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                    if result.hotel.amenities.count > 4 {
                        Text("+\(result.hotel.amenities.count - 4)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Book button hint
            HStack {
                Image(systemName: "hand.tap")
                Text("Tap to compare prices")
            }
            .font(.caption2)
            .foregroundStyle(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Hotel Detail Sheet

struct HotelDetailSheet: View {
    let result: HotelSearchResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.hotel.starDisplay)
                            .foregroundStyle(.orange)

                        Text(result.hotel.name)
                            .font(.title2.bold())

                        Text(result.hotel.nameLocal)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // Rating
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.orange)
                                Text(result.hotel.formattedRating)
                                    .fontWeight(.bold)
                            }

                            Text(result.hotel.ratingDescription)
                                .foregroundStyle(.secondary)

                            Text("(\(result.hotel.reviewCount) reviews)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .font(.subheadline)
                    }
                    .padding()

                    Divider()

                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Location", systemImage: "mappin.circle.fill")
                            .font(.headline)

                        Text(result.hotel.address)
                        Text("\(result.hotel.neighborhood), \(result.hotel.area)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Amenities
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Amenities", systemImage: "checkmark.circle.fill")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(result.hotel.amenities, id: \.self) { amenity in
                                HStack(spacing: 4) {
                                    Image(systemName: amenityIcon(for: amenity))
                                        .foregroundStyle(.blue)
                                    Text(amenity)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // Booking Links
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Book Now", systemImage: "link.circle.fill")
                            .font(.headline)

                        Text("Compare prices and book on these sites:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(result.bookingLinks) { link in
                            if let url = URL(string: link.url) {
                                Link(destination: url) {
                                    HStack {
                                        Image(systemName: link.provider.iconName)
                                            .frame(width: 24)
                                        Text(LocalizedStringKey(link.provider.displayName))
                                        Spacer()
                                        Image(systemName: "arrow.up.right.square")
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Hotel Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func amenityIcon(for amenity: String) -> String {
        switch amenity.lowercased() {
        case "wifi": return "wifi"
        case "pool": return "figure.pool.swim"
        case "spa": return "sparkles"
        case "gym": return "dumbbell.fill"
        case "restaurant": return "fork.knife"
        case "bar": return "wineglass.fill"
        case "hot spring": return "drop.fill"
        case "lake view", "mountain view": return "eye.fill"
        case "laundry": return "washer.fill"
        default: return "checkmark"
        }
    }
}

// MARK: - Search Near Destination View (For Trip Integration)

struct HotelSearchNearView: View {
    let coordinate: CLLocationCoordinate2D
    let locationName: String

    @State private var sortBy: HotelSortOption = .distance
    @State private var results: [HotelSearchResult] = []
    @State private var selectedHotel: HotelSearchResult?
    @State private var searchRadius: Double = 5.0

    @Environment(\.dismiss) private var dismiss
    private let service = HotelSearchService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Location header
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.red)
                    VStack(alignment: .leading) {
                        Text("Hotels near")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(locationName)
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))

                // Sort and radius controls
                HStack {
                    // Radius picker
                    Menu {
                        ForEach([2.0, 5.0, 10.0, 20.0], id: \.self) { radius in
                            Button {
                                searchRadius = radius
                                search()
                            } label: {
                                HStack {
                                    Text("\(Int(radius)) km")
                                    if searchRadius == radius {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.dashed")
                            Text("\(Int(searchRadius)) km")
                        }
                        .font(.subheadline)
                    }

                    Spacer()

                    // Sort picker
                    Menu {
                        ForEach(HotelSortOption.allCases) { option in
                            Button {
                                sortBy = option
                                search()
                            } label: {
                                HStack {
                                    Image(systemName: option.systemImage)
                                    Text(LocalizedStringKey(option.displayName))
                                    if sortBy == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: sortBy.systemImage)
                            Text(LocalizedStringKey(sortBy.displayName))
                        }
                        .font(.subheadline)
                    }
                }
                .padding()

                if results.isEmpty {
                    ContentUnavailableView {
                        Label("No Hotels Nearby", systemImage: "building.2")
                    } description: {
                        Text("Try increasing the search radius")
                    }
                } else {
                    // Results list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(results) { result in
                                HotelCard(result: result)
                                    .onTapGesture {
                                        selectedHotel = result
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Nearby Hotels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedHotel) { result in
                HotelDetailSheet(result: result)
            }
            .onAppear {
                search()
            }
        }
    }

    private func search() {
        results = service.searchHotels(near: coordinate, radiusKm: searchRadius, sortBy: sortBy)
    }
}

#if DEBUG
private struct NearbyHotelSearchView_Previews: PreviewProvider {
    static var previews: some View {
        HotelSearchView()
    }
}
#endif
