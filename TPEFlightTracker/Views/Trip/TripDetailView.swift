import SwiftUI
import MapKit

struct TripDetailView: View {
    let trip: Trip
    @ObservedObject var viewModel: TripViewModel
    @State private var showingAddDestination = false
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    var body: some View {
        VStack(spacing: 0) {
            // Map
            TripMapView(destinations: trip.destinations, cameraPosition: $mapCameraPosition)
                .frame(height: 300)

            // Trip summary bar
            tripSummaryBar

            // Destinations list
            destinationsList
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddDestination = true
                    } label: {
                        Label("Add Destination", systemImage: "plus")
                    }

                    Button {
                        Task {
                            await viewModel.recalculateAllRoutes(for: trip)
                        }
                    } label: {
                        Label("Recalculate Routes", systemImage: "arrow.triangle.2.circlepath")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddDestination) {
            AddDestinationView(trip: trip, viewModel: viewModel)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var tripSummaryBar: some View {
        HStack(spacing: 16) {
            Label("\(trip.totalDestinations) stops", systemImage: "mappin.circle.fill")
            Spacer()
            if trip.totalDistanceMeters > 0 {
                Label(trip.formattedTotalDistance, systemImage: "road.lanes")
            }
            if trip.totalDurationMinutes > 0 {
                Label(trip.formattedTotalDuration, systemImage: "clock")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    private var destinationsList: some View {
        List {
            if trip.destinations.isEmpty {
                ContentUnavailableView {
                    Label("No Destinations", systemImage: "mappin.slash")
                } description: {
                    Text("Add destinations to plan your trip route.")
                } actions: {
                    Button("Add Destination") {
                        showingAddDestination = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ForEach(Array(trip.destinations.enumerated()), id: \.element.id) { index, destination in
                    DestinationRowView(
                        destination: destination,
                        index: index,
                        isFirst: index == 0,
                        isLast: index == trip.destinations.count - 1
                    )
                }
                .onDelete { offsets in
                    Task {
                        for index in offsets {
                            await viewModel.removeDestination(trip.destinations[index], from: trip)
                        }
                    }
                }
                .onMove { source, destination in
                    Task {
                        await viewModel.reorderDestinations(in: trip, from: source, to: destination)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

struct DestinationRowView: View {
    let destination: TripDestination
    let index: Int
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Travel info from previous destination
            if !isFirst, let duration = destination.formattedTravelDuration {
                HStack(spacing: 8) {
                    Image(systemName: destination.travelMode.systemImage)
                        .font(.caption2)
                    Text(duration)
                    if let distance = destination.formattedTravelDistance {
                        Text("(\(distance))")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.leading, 28)
                .padding(.vertical, 4)
            }

            // Destination info
            HStack(alignment: .top, spacing: 12) {
                // Order number
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 24, height: 24)
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(destination.name)
                        .font(.headline)

                    Text(destination.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if !destination.notes.isEmpty {
                        Text(destination.notes)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TripMapView: View {
    let destinations: [TripDestination]
    @Binding var cameraPosition: MapCameraPosition

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(Array(destinations.enumerated()), id: \.element.id) { index, destination in
                Annotation(
                    destination.name,
                    coordinate: destination.coordinate,
                    anchor: .bottom
                ) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 30, height: 30)
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
            }

            // Draw lines between destinations
            if destinations.count > 1 {
                let coordinates = destinations.map(\.coordinate)
                MapPolyline(coordinates: coordinates)
                    .stroke(Color.accentColor, lineWidth: 3)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}

#Preview {
    NavigationStack {
        TripDetailView(
            trip: Trip(
                name: "Tokyo Trip",
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 5),
                destinations: [
                    TripDestination(
                        name: "Tokyo Tower",
                        address: "4-2-8 Shibakoen, Minato City, Tokyo",
                        latitude: 35.6586,
                        longitude: 139.7454,
                        order: 0
                    ),
                    TripDestination(
                        name: "Senso-ji Temple",
                        address: "2-3-1 Asakusa, Taito City, Tokyo",
                        latitude: 35.7148,
                        longitude: 139.7967,
                        order: 1,
                        travelDurationMinutes: 25,
                        travelDistanceMeters: 8500
                    )
                ]
            ),
            viewModel: TripViewModel()
        )
    }
}
