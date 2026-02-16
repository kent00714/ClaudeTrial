import SwiftUI

struct HotelSearchView: View {
    @State private var searchText = ""
    @State private var sortBy: HotelSortOption = .rating
    @State private var results: [HotelSearchResult] = []
    @State private var selectedHotel: HotelSearchResult?

    private let service: HotelSearchServiceProtocol
    private let popularAreas: [(name: String, icon: String)] = [
        ("Taipei", "building.2.fill"),
        ("Jiufen", "mountain.2.fill"),
        ("Beitou", "drop.fill"),
        ("Taroko", "mountain.2.fill"),
        ("Sun Moon Lake", "water.waves"),
        ("Kaohsiung", "building.fill"),
        ("Tainan", "building.columns.fill")
    ]

    init(service: HotelSearchServiceProtocol = HotelSearchService.shared) {
        self.service = service
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if results.isEmpty && trimmedSearchText.isEmpty {
                    popularAreaContent
                } else if results.isEmpty {
                    emptyResultsContent
                } else {
                    resultListContent
                }
            }
            .navigationTitle(LocalizedStringKey("Hotels"))
            .sheet(item: $selectedHotel) { result in
                HotelDetailSheet(result: result)
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    results = []
                }
            }
            .onChange(of: sortBy) { _, _ in
                if !trimmedSearchText.isEmpty {
                    search()
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(LocalizedStringKey("Search area or hotel name"), text: $searchText)
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
    }

    private var popularAreaContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStringKey("Popular Areas"))
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(popularAreas, id: \.name) { area in
                        Button {
                            searchText = area.name
                            search()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: area.icon)
                                    .font(.title2)
                                Text(LocalizedStringKey(area.name))
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
    }

    private var emptyResultsContent: some View {
        ContentUnavailableView {
            Label(LocalizedStringKey("No Hotels Found"), systemImage: "building.2")
        } description: {
            Text(LocalizedStringKey("Try searching for a different area"))
        }
    }

    private var resultListContent: some View {
        VStack(spacing: 0) {
            HStack {
                Label {
                    Text("\(results.count)")
                } icon: {
                    Image(systemName: "bed.double.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text(LocalizedStringKey("Hotels"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    ForEach(HotelSortOption.allCases) { option in
                        Button {
                            sortBy = option
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

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func search() {
        let query = trimmedSearchText
        guard !query.isEmpty else {
            results = []
            return
        }

        results = service.searchHotels(in: query, sortBy: sortBy)
    }
}

struct HotelCard: View {
    let result: HotelSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 70, height: 70)
                    .overlay {
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.hotel.starDisplay)
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Text(result.hotel.name)
                        .font(.headline)
                        .lineLimit(1)

                    if !result.hotel.nameLocal.isEmpty {
                        Text(result.hotel.nameLocal)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                        Text(LocalizedStringKey(result.hotel.neighborhood))
                        if result.distanceKm > 0 {
                            Text("• \(result.formattedDistance)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.orange)
                        Text(result.hotel.formattedRating)
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)

                    HStack(spacing: 2) {
                        Text("\(result.hotel.reviewCount)")
                        Text(LocalizedStringKey("reviews"))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    Text(result.hotel.priceLevelDisplay)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(result.hotel.amenities.prefix(4), id: \.self) { amenity in
                        Text(LocalizedStringKey(amenity))
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

            HStack {
                Image(systemName: "hand.tap")
                Text(LocalizedStringKey("Tap to compare prices"))
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

struct HotelDetailSheet: View {
    let result: HotelSearchResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.hotel.starDisplay)
                            .foregroundStyle(.orange)

                        Text(result.hotel.name)
                            .font(.title2.bold())

                        if !result.hotel.nameLocal.isEmpty {
                            Text(result.hotel.nameLocal)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.orange)
                                Text(result.hotel.formattedRating)
                                    .fontWeight(.bold)
                            }

                            Text(LocalizedStringKey(result.hotel.ratingDescription))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 2) {
                                Text("(\(result.hotel.reviewCount)")
                                Text(LocalizedStringKey("reviews"))
                                Text(")")
                            }
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        }
                        .font(.subheadline)
                    }
                    .padding()

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label(LocalizedStringKey("Location"), systemImage: "mappin.circle.fill")
                            .font(.headline)

                        Text(result.hotel.address)

                        Text(LocalizedStringKey(result.hotel.neighborhood)) +
                        Text(", ") +
                        Text(LocalizedStringKey(result.hotel.area))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Label(LocalizedStringKey("Amenities"), systemImage: "checkmark.circle.fill")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(result.hotel.amenities, id: \.self) { amenity in
                                HStack(spacing: 4) {
                                    Image(systemName: amenityIcon(for: amenity))
                                        .foregroundStyle(.blue)
                                    Text(LocalizedStringKey(amenity))
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Label(LocalizedStringKey("Book Now"), systemImage: "link.circle.fill")
                            .font(.headline)

                        Text(LocalizedStringKey("Compare prices and book on these sites:"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(result.bookingLinks) { link in
                            if let url = URL(string: link.url) {
                                Link(destination: url) {
                                    HStack {
                                        Image(systemName: link.provider.iconName)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(LocalizedStringKey(link.provider.displayName))
                                            Text(LocalizedStringKey(link.label))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }

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
            .navigationTitle(LocalizedStringKey("Hotel Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedStringKey("Done")) {
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

#if DEBUG
private struct TripHotelSearchView_Previews: PreviewProvider {
    static var previews: some View {
        HotelSearchView()
    }
}
#endif
