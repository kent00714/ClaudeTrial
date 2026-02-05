import SwiftUI
import UniformTypeIdentifiers

struct TripListView: View {
    @ObservedObject var viewModel: TripViewModel
    @StateObject private var flightViewModel = FlightViewModel()
    @State private var showingAddTrip = false
    @State private var showingImportPicker = false
    @State private var importError: String?
    @State private var showingImportError = false
    @State private var showingImportSuccess = false
    @State private var importedTripName: String = ""

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.trips.isEmpty {
                    emptyState
                } else {
                    tripList
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingImportPicker = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTrip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTrip) {
                AddTripView(viewModel: viewModel)
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .alert("Import Failed", isPresented: $showingImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importError ?? "Unknown error occurred")
            }
            .alert("Trip Imported", isPresented: $showingImportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("'\(importedTripName)' has been added to your trips.")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Trips", systemImage: "map")
        } description: {
            Text("Create your first trip to start planning your journey.")
        } actions: {
            Button("Create Trip") {
                showingAddTrip = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var tripList: some View {
        List {
            ForEach(viewModel.trips) { trip in
                NavigationLink {
                    TripDetailView(trip: trip, viewModel: viewModel, flightViewModel: flightViewModel)
                } label: {
                    TripRowView(trip: trip, dateFormatter: dateFormatter)
                }
            }
            .onDelete(perform: deleteTrips)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteTrip(viewModel.trips[index])
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Unable to access the selected file."
                showingImportError = true
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                var importedTrip = try Trip.importFromJSON(data)

                // Create a new ID to avoid conflicts
                importedTrip = Trip(
                    id: UUID(),
                    name: importedTrip.name,
                    startDate: importedTrip.startDate,
                    endDate: importedTrip.endDate,
                    destinations: importedTrip.destinations,
                    createdAt: Date(),
                    updatedAt: Date(),
                    notes: importedTrip.notes,
                    sourceSuggestionName: importedTrip.sourceSuggestionName,
                    linkedFlightNumber: importedTrip.linkedFlightNumber
                )

                viewModel.createTripFromSuggestion(importedTrip)
                importedTripName = importedTrip.name
                showingImportSuccess = true
            } catch {
                importError = "Failed to import trip: \(error.localizedDescription)"
                showingImportError = true
            }

        case .failure(let error):
            importError = error.localizedDescription
            showingImportError = true
        }
    }
}

struct TripRowView: View {
    let trip: Trip
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(trip.name)
                    .font(.headline)

                Spacer()

                // Flight indicator
                if trip.hasLinkedFlight {
                    HStack(spacing: 4) {
                        Image(systemName: "airplane")
                        Text(trip.linkedFlightNumber ?? "")
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                }
            }

            HStack {
                Text("\(dateFormatter.string(from: trip.startDate)) - \(dateFormatter.string(from: trip.endDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label("\(trip.totalDestinations)", systemImage: "mappin.circle.fill")
                if trip.totalDistanceMeters > 0 {
                    Label(trip.formattedTotalDistance, systemImage: "road.lanes")
                }
                if trip.totalDurationMinutes > 0 {
                    Label(trip.formattedTotalDuration, systemImage: "clock")
                }

                // Source indicator
                if trip.isFromSuggestion {
                    Label("AI", systemImage: "sparkles")
                        .foregroundStyle(.blue)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddTripView: View {
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3) // 3 days later
    @State private var flightNumber = ""

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
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
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
                    Text("Flight Tracking (Optional)")
                } footer: {
                    Text("Link your flight to track its status directly from this trip.")
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createTrip(name: name, startDate: startDate, endDate: endDate, flightNumber: cleanedFlightNumber)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    TripListView(viewModel: TripViewModel())
}
