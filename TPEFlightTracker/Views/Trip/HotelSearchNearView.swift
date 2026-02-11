import SwiftUI
import MapKit

struct HotelSearchNearView: View {
    let coordinate: CLLocationCoordinate2D
    let locationName: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var selectedHotel: MKMapItem?
    @State private var mapCameraPosition: MapCameraPosition
    
    init(coordinate: CLLocationCoordinate2D, locationName: String) {
        self.coordinate = coordinate
        self.locationName = locationName
        _mapCameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        ))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map showing location and nearby hotels
                Map(position: $mapCameraPosition) {
                    // Original destination marker
                    Marker(locationName, systemImage: "mappin.circle.fill", coordinate: coordinate)
                        .tint(.blue)
                    
                    // Hotel markers
                    ForEach(searchResults, id: \.self) { hotel in
                        if let hotelCoordinate = hotel.placemark.location?.coordinate {
                            Marker(
                                hotel.name ?? "Hotel",
                                systemImage: "bed.double.fill",
                                coordinate: hotelCoordinate
                            )
                            .tint(.red)
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(height: 250)
                
                // Hotel search results list
                if isSearching {
                    Spacer()
                    ProgressView("Searching for nearby hotels...")
                        .padding()
                    Spacer()
                } else if searchResults.isEmpty {
                    ContentUnavailableView(
                        "No Hotels Found",
                        systemImage: "bed.double.fill",
                        description: Text("No hotels were found near \(locationName)")
                    )
                } else {
                    List {
                        Section {
                            ForEach(searchResults, id: \.self) { hotel in
                                HotelRowView(hotel: hotel, destinationCoordinate: coordinate)
                                    .onTapGesture {
                                        selectedHotel = hotel
                                        if let hotelCoordinate = hotel.placemark.location?.coordinate {
                                            mapCameraPosition = .region(
                                                MKCoordinateRegion(
                                                    center: hotelCoordinate,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                                )
                                            )
                                        }
                                    }
                            }
                        } header: {
                            Text("Hotels near \(locationName)")
                        }
                    }
                }
            }
            .navigationTitle("Find Hotels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await searchForHotels()
            }
        }
    }
    
    private func searchForHotels() async {
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "hotels"
        request.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        request.resultTypes = .pointOfInterest
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            searchResults = response.mapItems.filter { item in
                // Filter for hotels
                (item.pointOfInterestCategory == .some(.hotel)) ||
                (item.name?.localizedCaseInsensitiveContains("hotel") ?? false) ||
                (item.name?.localizedCaseInsensitiveContains("inn") ?? false)
            }
        } catch {
            print("Error searching for hotels: \(error)")
            searchResults = []
        }
        
        isSearching = false
    }
}

struct HotelRowView: View {
    let hotel: MKMapItem
    let destinationCoordinate: CLLocationCoordinate2D
    
    private var distance: String {
        guard let hotelLocation = hotel.placemark.location else {
            return "Unknown"
        }
        
        let destinationLocation = CLLocation(
            latitude: destinationCoordinate.latitude,
            longitude: destinationCoordinate.longitude
        )
        
        let distanceInMeters = hotelLocation.distance(from: destinationLocation)
        let distanceInKm = distanceInMeters / 1000.0
        
        if distanceInKm < 1 {
            return String(format: "%.0f m", distanceInMeters)
        } else {
            return String(format: "%.1f km", distanceInKm)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(hotel.name ?? "Unknown Hotel")
                        .font(.headline)
                    
                    if let address = hotel.placemark.formattedAddress {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "bed.double.fill")
                        .foregroundStyle(.red)
                    
                    Text(distance)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Phone and website if available
            HStack(spacing: 16) {
                if let phone = hotel.phoneNumber {
                    Link(destination: URL(string: "tel:\(phone)")!) {
                        Label("Call", systemImage: "phone.fill")
                            .font(.caption)
                    }
                }
                
                if let url = hotel.url {
                    Link(destination: url) {
                        Label("Website", systemImage: "safari")
                            .font(.caption)
                    }
                }
                
                // Open in Maps
                Button {
                    hotel.openInMaps()
                } label: {
                    Label("Directions", systemImage: "map.fill")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
private struct HotelSearchNearView_Previews: PreviewProvider {
    static var previews: some View {
        HotelSearchNearView(
            coordinate: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654),
            locationName: "Taipei 101"
        )
    }
}
#endif
