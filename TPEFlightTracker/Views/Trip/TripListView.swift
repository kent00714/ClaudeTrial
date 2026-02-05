import SwiftUI

struct TripListView: View {
    @ObservedObject var viewModel: TripViewModel
    @State private var showingAddTrip = false

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
                    TripDetailView(trip: trip, viewModel: viewModel)
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
}

struct TripRowView: View {
    let trip: Trip
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trip.name)
                .font(.headline)

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

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $name)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
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
                        viewModel.createTrip(name: name, startDate: startDate, endDate: endDate)
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
