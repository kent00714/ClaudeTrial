import SwiftUI
import MapKit

struct TripDetailView: View {
    let trip: Trip
    @ObservedObject var viewModel: TripViewModel
    @ObservedObject var flightViewModel: FlightViewModel
    @State private var showingAddDestination = false
    @State private var showingEditTrip = false
    @State private var showingEditDestination: TripDestination?
    @State private var showingFlightDetail = false
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    init(trip: Trip, viewModel: TripViewModel, flightViewModel: FlightViewModel = FlightViewModel()) {
        self.trip = trip
        self.viewModel = viewModel
        self.flightViewModel = flightViewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Map
            TripMapView(destinations: trip.destinations, cameraPosition: $mapCameraPosition)
                .frame(height: 250)

            // Linked Flight (if any)
            if trip.hasLinkedFlight {
                linkedFlightSection
            }

            // Trip info header (editable)
            tripInfoHeader

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
                        showingEditTrip = true
                    } label: {
                        Label("Edit Trip Details", systemImage: "pencil")
                    }

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
        .sheet(isPresented: $showingEditTrip) {
            EditTripView(trip: trip, viewModel: viewModel)
        }
        .sheet(item: $showingEditDestination) { destination in
            EditDestinationView(trip: trip, destination: destination, viewModel: viewModel)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Linked Flight Section

    private var linkedFlightSection: some View {
        Button {
            // Search for the flight and show details
            if let flightNumber = trip.linkedFlightNumber {
                flightViewModel.searchQuery = flightNumber
                Task {
                    await flightViewModel.searchFlights()
                    showingFlightDetail = true
                }
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "airplane")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Linked Flight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(trip.linkedFlightNumber ?? "")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Tap to check status")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingFlightDetail) {
            LinkedFlightStatusView(
                flightNumber: trip.linkedFlightNumber ?? "",
                flightViewModel: flightViewModel
            )
        }
    }

    // MARK: - Trip Info Header

    private var tripInfoHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Source badge if from suggestion
            if let sourceName = trip.sourceSuggestionName {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("Based on: \(sourceName)")
                }
                .font(.caption)
                .foregroundStyle(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
            }

            // Date range
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text(formatDateRange(start: trip.startDate, end: trip.endDate))
                    .font(.subheadline)

                Spacer()

                Button {
                    showingEditTrip = true
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                }
            }

            // Notes preview
            if !trip.notes.isEmpty {
                Text(trip.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if Calendar.current.isDate(start, equalTo: end, toGranularity: .day) {
            return formatter.string(from: start)
        }
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingEditDestination = destination
                    }
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(destination.name)
                        .font(.headline)

                    Text(destination.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    // Estimated stay time
                    if let stayTime = destination.formattedEstimatedStay {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("Spend: \(stayTime)")
                        }
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    }

                    if !destination.notes.isEmpty {
                        Text(destination.notes)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }

                    // Tips preview
                    if let firstTip = destination.tips.first {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text(firstTip)
                                .lineLimit(1)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                Spacer()

                VStack {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.tertiary)
                }
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

// MARK: - Edit Trip View

struct EditTripView: View {
    let trip: Trip
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var flightNumber: String

    init(trip: Trip, viewModel: TripViewModel) {
        self.trip = trip
        self.viewModel = viewModel
        _name = State(initialValue: trip.name)
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
        _notes = State(initialValue: trip.notes)
        _flightNumber = State(initialValue: trip.linkedFlightNumber ?? "")
    }

    var cleanedFlightNumber: String? {
        let cleaned = flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return cleaned.isEmpty ? nil : cleaned
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $name)

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section {
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundStyle(.blue)
                        TextField("Flight Number (e.g., CI123)", text: $flightNumber)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Flight Tracking")
                } footer: {
                    Text("Link your flight to track its status directly from this trip.")
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                if trip.isFromSuggestion {
                    Section {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text("Based on suggestion")
                                    .font(.subheadline)
                                Text(trip.sourceSuggestionName ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } footer: {
                        Text("This trip was created from a curated suggestion. You can customize it freely!")
                    }
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        var updatedTrip = trip
        updatedTrip.name = name
        updatedTrip.startDate = startDate
        updatedTrip.endDate = endDate
        updatedTrip.notes = notes
        updatedTrip.linkedFlightNumber = cleanedFlightNumber
        updatedTrip.updatedAt = Date()
        viewModel.updateTrip(updatedTrip)
        dismiss()
    }
}

// MARK: - Edit Destination View

struct EditDestinationView: View {
    let trip: Trip
    let destination: TripDestination
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var notes: String
    @State private var travelMode: TravelMode
    @State private var estimatedStayMinutes: Int

    init(trip: Trip, destination: TripDestination, viewModel: TripViewModel) {
        self.trip = trip
        self.destination = destination
        self.viewModel = viewModel
        _name = State(initialValue: destination.name)
        _notes = State(initialValue: destination.notes)
        _travelMode = State(initialValue: destination.travelMode)
        _estimatedStayMinutes = State(initialValue: destination.estimatedStayMinutes ?? 60)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Destination") {
                    TextField("Name", text: $name)

                    Text(destination.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Time at Location") {
                    Stepper(value: $estimatedStayMinutes, in: 15...480, step: 15) {
                        HStack {
                            Text("Estimated Stay")
                            Spacer()
                            Text(formatMinutes(estimatedStayMinutes))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Travel Mode") {
                    Picker("How to get here", selection: $travelMode) {
                        ForEach(TravelMode.allCases) { mode in
                            Label(mode.displayName, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                // Tips section (read-only from suggestion)
                if !destination.tips.isEmpty {
                    Section("Tips") {
                        ForEach(destination.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                Text(tip)
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        removeDestination()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Remove from Trip")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(mins) min"
        }
    }

    private func saveChanges() {
        guard let index = trip.destinations.firstIndex(where: { $0.id == destination.id }) else {
            dismiss()
            return
        }

        var updatedTrip = trip
        updatedTrip.destinations[index].name = name
        updatedTrip.destinations[index].notes = notes
        updatedTrip.destinations[index].travelMode = travelMode
        updatedTrip.destinations[index].estimatedStayMinutes = estimatedStayMinutes
        updatedTrip.updatedAt = Date()
        viewModel.updateTrip(updatedTrip)
        dismiss()
    }

    private func removeDestination() {
        Task {
            await viewModel.removeDestination(destination, from: trip)
            dismiss()
        }
    }
}

// MARK: - Linked Flight Status View

struct LinkedFlightStatusView: View {
    let flightNumber: String
    @ObservedObject var flightViewModel: FlightViewModel
    @Environment(\.dismiss) private var dismiss

    var matchingFlight: Flight? {
        flightViewModel.flights.first { flight in
            flight.flightNumber.uppercased().contains(flightNumber.uppercased()) ||
            flightNumber.uppercased().contains(flight.flightNumber.uppercased())
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if flightViewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Searching for flight \(flightNumber)...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let flight = matchingFlight {
                    flightDetailContent(flight: flight)
                } else if !flightViewModel.flights.isEmpty {
                    // Found flights but none match
                    ContentUnavailableView {
                        Label("Flight Not Found", systemImage: "airplane.circle")
                    } description: {
                        Text("Could not find flight \(flightNumber) in today's schedule. The flight may have already departed or not yet scheduled.")
                    }
                } else {
                    // No flights at all
                    ContentUnavailableView {
                        Label("No Results", systemImage: "magnifyingglass")
                    } description: {
                        Text("Unable to find flight information for \(flightNumber). Please check the flight number and try again.")
                    } actions: {
                        Button("Retry") {
                            Task {
                                await flightViewModel.searchFlights()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Flight Status")
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

    private func flightDetailContent(flight: Flight) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Flight Header
                VStack(spacing: 8) {
                    Text(flight.flightNumber)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(flight.airline)
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    // Status Badge
                    Text(flight.status.displayName)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(statusColor(for: flight.status).opacity(0.2))
                        .foregroundStyle(statusColor(for: flight.status))
                        .clipShape(Capsule())
                }
                .padding()

                // Route Info
                HStack(spacing: 0) {
                    VStack {
                        Text(flight.departureAirport)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(flight.departureCity)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Image(systemName: "airplane")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    VStack {
                        Text(flight.arrivalAirport)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(flight.arrivalCity)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Time Info
                VStack(spacing: 16) {
                    if let scheduledTime = flight.scheduledTime {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Scheduled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatTime(scheduledTime))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }

                    if let estimatedTime = flight.estimatedTime {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Estimated")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatTime(estimatedTime))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                            }
                            Spacer()
                        }
                    }

                    if let actualTime = flight.actualTime {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Actual")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatTime(actualTime))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Terminal & Gate
                if flight.terminal != nil || flight.gate != nil {
                    HStack(spacing: 24) {
                        if let terminal = flight.terminal {
                            VStack {
                                Text("Terminal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(terminal)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        if let gate = flight.gate {
                            VStack {
                                Text("Gate")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(gate)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                // Refresh Button
                Button {
                    Task {
                        await flightViewModel.searchFlights()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Status")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .disabled(flightViewModel.isLoading)
            }
            .padding(.vertical)
        }
    }

    private func statusColor(for status: FlightStatus) -> Color {
        switch status {
        case .scheduled, .active:
            return .blue
        case .landed:
            return .green
        case .cancelled:
            return .red
        case .delayed:
            return .orange
        case .diverted:
            return .purple
        case .unknown:
            return .gray
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
                        order: 0,
                        estimatedStayMinutes: 90,
                        tips: ["Visit at sunset for amazing views"]
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
                ],
                sourceSuggestionName: "Essential Tokyo"
            ),
            viewModel: TripViewModel()
        )
    }
}
