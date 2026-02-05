import SwiftUI
import MapKit

// MARK: - Taxi Booking List View

struct TaxiBookingListView: View {
    @StateObject private var viewModel = TaxiBookingViewModel()
    @State private var showingNewBooking = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.bookings.isEmpty {
                    emptyState
                } else {
                    bookingsList
                }
            }
            .navigationTitle("Taxi Bookings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewBooking = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewBooking) {
                NewTaxiBookingView(viewModel: viewModel)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Bookings", systemImage: "car.side.fill")
        } description: {
            Text("Book a taxi for your trips around Taiwan.")
        } actions: {
            Button("Book a Taxi") {
                showingNewBooking = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var bookingsList: some View {
        List {
            if !viewModel.upcomingBookings.isEmpty {
                Section("Upcoming") {
                    ForEach(viewModel.upcomingBookings) { booking in
                        NavigationLink {
                            TaxiBookingDetailView(booking: booking, viewModel: viewModel)
                        } label: {
                            TaxiBookingRowView(booking: booking)
                        }
                    }
                }
            }

            if !viewModel.pastBookings.isEmpty {
                Section("Past") {
                    ForEach(viewModel.pastBookings) { booking in
                        NavigationLink {
                            TaxiBookingDetailView(booking: booking, viewModel: viewModel)
                        } label: {
                            TaxiBookingRowView(booking: booking)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.loadBookings()
        }
    }
}

// MARK: - Booking Row View

struct TaxiBookingRowView: View {
    let booking: TaxiBooking

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status and time
            HStack {
                Label(booking.status.displayNameChinese, systemImage: booking.status.systemImage)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .clipShape(Capsule())

                Spacer()

                Text(dateFormatter.string(from: booking.scheduledTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Route
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text(booking.pickupLocation.name)
                            .font(.subheadline)
                            .lineLimit(1)
                    }

                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                        Text(booking.dropoffLocation.name)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let fare = booking.formattedFare {
                    Text(fare)
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch booking.status {
        case .pending: return .orange
        case .confirmed, .driverEnRoute, .inProgress: return .blue
        case .arrived: return .green
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

// MARK: - New Taxi Booking View

struct NewTaxiBookingView: View {
    @ObservedObject var viewModel: TaxiBookingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pickupName = ""
    @State private var pickupAddress = ""
    @State private var dropoffName = ""
    @State private var dropoffAddress = ""
    @State private var scheduledTime = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var passengerCount = 1
    @State private var notes = ""

    @State private var showingPickupSearch = false
    @State private var showingDropoffSearch = false
    @State private var pickupCoordinate: CLLocationCoordinate2D?
    @State private var dropoffCoordinate: CLLocationCoordinate2D?

    var canBook: Bool {
        !pickupName.isEmpty && !dropoffName.isEmpty &&
        pickupCoordinate != nil && dropoffCoordinate != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingPickupSearch = true
                    } label: {
                        HStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 12, height: 12)
                            if pickupName.isEmpty {
                                Text("Select pickup location")
                                    .foregroundStyle(.secondary)
                            } else {
                                VStack(alignment: .leading) {
                                    Text(pickupName)
                                        .foregroundStyle(.primary)
                                    Text(pickupAddress)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingDropoffSearch = true
                    } label: {
                        HStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                            if dropoffName.isEmpty {
                                Text("Select dropoff location")
                                    .foregroundStyle(.secondary)
                            } else {
                                VStack(alignment: .leading) {
                                    Text(dropoffName)
                                        .foregroundStyle(.primary)
                                    Text(dropoffAddress)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Route")
                }

                Section {
                    DatePicker("Pickup Time", selection: $scheduledTime, in: Date()...)

                    Stepper("Passengers: \(passengerCount)", value: $passengerCount, in: 1...6)
                } header: {
                    Text("Details")
                }

                Section {
                    TextField("Special requests or notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes (Optional)")
                } footer: {
                    Text("Add any special requirements like luggage, wheelchair access, etc.")
                }

                Section {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(.green)
                        Text("Estimated Fare")
                        Spacer()
                        Text("NT$85 ~ NT$500")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.blue)
                        Text("Estimated Duration")
                        Spacer()
                        Text("Calculated after booking")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Estimate")
                } footer: {
                    Text("Final fare depends on actual route and traffic conditions.")
                }
            }
            .navigationTitle("Book a Taxi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Book") {
                        bookTaxi()
                    }
                    .disabled(!canBook || viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showingPickupSearch) {
                LocationSearchView(
                    title: "Pickup Location",
                    onSelect: { name, address, coordinate in
                        pickupName = name
                        pickupAddress = address
                        pickupCoordinate = coordinate
                    }
                )
            }
            .sheet(isPresented: $showingDropoffSearch) {
                LocationSearchView(
                    title: "Dropoff Location",
                    onSelect: { name, address, coordinate in
                        dropoffName = name
                        dropoffAddress = address
                        dropoffCoordinate = coordinate
                    }
                )
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Booking...")
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func bookTaxi() {
        guard let pickup = pickupCoordinate, let dropoff = dropoffCoordinate else { return }

        let pickupLocation = TaxiLocation(
            name: pickupName,
            address: pickupAddress,
            latitude: pickup.latitude,
            longitude: pickup.longitude
        )

        let dropoffLocation = TaxiLocation(
            name: dropoffName,
            address: dropoffAddress,
            latitude: dropoff.latitude,
            longitude: dropoff.longitude
        )

        Task {
            await viewModel.createBooking(
                pickupLocation: pickupLocation,
                dropoffLocation: dropoffLocation,
                scheduledTime: scheduledTime,
                passengerCount: passengerCount,
                notes: notes
            )
            dismiss()
        }
    }
}

// MARK: - Location Search View

struct LocationSearchView: View {
    let title: String
    let onSelect: (String, String, CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            List {
                if searchResults.isEmpty && !searchText.isEmpty && !isSearching {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(searchResults, id: \.self) { item in
                        Button {
                            selectLocation(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "Unknown")
                                    .foregroundStyle(.primary)
                                if let address = item.placemark.formattedAddress {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search location")
            .onChange(of: searchText) { _, newValue in
                searchLocations(query: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isSearching {
                    ProgressView()
                }
            }
        }
    }

    private func searchLocations(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654), // Taipei center
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            if let items = response?.mapItems {
                searchResults = items
            }
        }
    }

    private func selectLocation(_ item: MKMapItem) {
        let name = item.name ?? "Selected Location"
        let address = item.placemark.formattedAddress ?? ""
        let coordinate = item.placemark.coordinate
        onSelect(name, address, coordinate)
        dismiss()
    }
}

// MARK: - Booking Detail View

struct TaxiBookingDetailView: View {
    let booking: TaxiBooking
    @ObservedObject var viewModel: TaxiBookingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCancelConfirmation = false

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        return f
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status card
                statusCard

                // Route card
                routeCard

                // Details card
                detailsCard

                // Driver card (if assigned)
                if booking.status != .pending && booking.status != .cancelled {
                    driverCard
                }

                // Action buttons
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Booking Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cancel Booking", isPresented: $showingCancelConfirmation) {
            Button("Keep Booking", role: .cancel) { }
            Button("Cancel Booking", role: .destructive) {
                viewModel.cancelBooking(booking)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to cancel this taxi booking?")
        }
    }

    private var statusCard: some View {
        VStack(spacing: 12) {
            Image(systemName: booking.status.systemImage)
                .font(.system(size: 48))
                .foregroundStyle(statusColor)

            Text(booking.status.displayNameChinese)
                .font(.title2)
                .fontWeight(.semibold)

            Text(dateFormatter.string(from: booking.scheduledTime))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var routeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Route")
                .font(.headline)

            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 2, height: 40)
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                }

                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pickup")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(booking.pickupLocation.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(booking.pickupLocation.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dropoff")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(booking.dropoffLocation.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(booking.dropoffLocation.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            HStack {
                Label("\(booking.passengerCount) passenger(s)", systemImage: "person.fill")
                Spacer()
                if let fare = booking.formattedFare {
                    Text(fare)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }

            if !booking.notes.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(booking.notes)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var driverCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Driver")
                .font(.headline)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.driverName ?? "Driver assigned")
                        .font(.headline)
                    if let plate = booking.vehiclePlate {
                        Text(plate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let phone = booking.driverPhone {
                    Button {
                        if let url = URL(string: "tel://\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if booking.status.isActive && booking.status != .inProgress {
                Button(role: .destructive) {
                    showingCancelConfirmation = true
                } label: {
                    Text("Cancel Booking")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var statusColor: Color {
        switch booking.status {
        case .pending: return .orange
        case .confirmed, .driverEnRoute, .inProgress: return .blue
        case .arrived: return .green
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

// MARK: - Placemark Extension

extension MKPlacemark {
    var formattedAddress: String? {
        var parts: [String] = []
        if let street = thoroughfare {
            if let subStreet = subThoroughfare {
                parts.append("\(subStreet) \(street)")
            } else {
                parts.append(street)
            }
        }
        if let city = locality {
            parts.append(city)
        }
        if let area = administrativeArea {
            parts.append(area)
        }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

#Preview {
    TaxiBookingListView()
}
