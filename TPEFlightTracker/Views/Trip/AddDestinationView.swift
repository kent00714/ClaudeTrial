import SwiftUI
import MapKit

struct AddDestinationView: View {
    let trip: Trip
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedItem: MKMapItem?
    @State private var travelMode: TravelMode = .driving
    @State private var notes = ""
    @State private var isSearching = false
    @State private var mapCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654), // Taipei default
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                if selectedItem != nil {
                    // Selected place detail
                    selectedPlaceView
                } else {
                    // Map and search results
                    mapAndResults
                }
            }
            .navigationTitle("Add Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addDestination()
                    }
                    .disabled(selectedItem == nil)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search for a place", text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    performSearch()
                }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                    selectedItem = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
    }

    private var mapAndResults: some View {
        VStack(spacing: 0) {
            // Map
            Map(position: $mapCameraPosition) {
                ForEach(searchResults, id: \.self) { item in
                    if let coordinate = item.placemark.location?.coordinate {
                        Marker(
                            item.name ?? "Location",
                            coordinate: coordinate
                        )
                    }
                }
            }
            .mapStyle(.standard)
            .frame(height: 200)

            // Search results
            if isSearching {
                ProgressView("Searching...")
                    .padding()
            } else if searchResults.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List(searchResults, id: \.self) { item in
                    Button {
                        selectItem(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Unknown")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if let address = item.placemark.formattedAddress {
                                Text(address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var selectedPlaceView: some View {
        VStack(spacing: 0) {
            // Mini map showing selected location
            if let coordinate = selectedItem?.placemark.location?.coordinate {
                Map(position: .constant(.region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                ))) {
                    Marker(selectedItem?.name ?? "Location", coordinate: coordinate)
                }
                .frame(height: 150)
                .disabled(true)
            }

            Form {
                Section("Selected Place") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(selectedItem?.name ?? "Unknown")
                                .font(.headline)
                            if let address = selectedItem?.placemark.formattedAddress {
                                Text(address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button {
                            selectedItem = nil
                        } label: {
                            Text("Change")
                                .font(.caption)
                        }
                    }
                }

                Section("Travel Mode") {
                    Picker("How will you get here?", selection: $travelMode) {
                        ForEach(TravelMode.allCases) { mode in
                            Label(mode.displayName, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Notes") {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        // Set region based on trip's existing destinations or default to Taipei
        if let lastDest = trip.destinations.last {
            request.region = MKCoordinateRegion(
                center: lastDest.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            if let items = response?.mapItems {
                searchResults = items
                // Update map to show all results
                if let first = items.first?.placemark.location?.coordinate {
                    mapCameraPosition = .region(
                        MKCoordinateRegion(
                            center: first,
                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        )
                    )
                }
            }
        }
    }

    private func selectItem(_ item: MKMapItem) {
        selectedItem = item
        if let coordinate = item.placemark.location?.coordinate {
            mapCameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
    }

    private func addDestination() {
        guard let item = selectedItem,
              let location = item.placemark.location else {
            return
        }

        Task {
            await viewModel.addDestination(
                to: trip,
                name: item.name ?? "Unknown",
                address: item.placemark.formattedAddress ?? "",
                coordinate: location.coordinate,
                travelMode: travelMode
            )
            dismiss()
        }
    }
}

extension CLPlacemark {
    var formattedAddress: String? {
        let components = [
            subThoroughfare,
            thoroughfare,
            locality,
            administrativeArea,
            country
        ].compactMap { $0 }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

#Preview {
    AddDestinationView(
        trip: Trip(name: "Test", startDate: Date(), endDate: Date()),
        viewModel: TripViewModel()
    )
}
