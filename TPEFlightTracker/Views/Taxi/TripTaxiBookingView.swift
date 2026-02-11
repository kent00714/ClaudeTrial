import SwiftUI
import MapKit

// MARK: - Book Taxi for Trip Destination

struct BookTaxiForTripView: View {
    let trip: Trip
    let fromDestination: TripDestination
    let toDestination: TripDestination
    @ObservedObject var taxiViewModel: TaxiBookingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var scheduledTime: Date
    @State private var passengerCount = 1
    @State private var notes = ""
    @State private var estimatedFare: TaxiFareEstimate?
    @State private var isEstimating = false

    init(trip: Trip, fromDestination: TripDestination, toDestination: TripDestination, taxiViewModel: TaxiBookingViewModel) {
        self.trip = trip
        self.fromDestination = fromDestination
        self.toDestination = toDestination
        self.taxiViewModel = taxiViewModel
        // Default to trip start date + estimated arrival at this destination
        _scheduledTime = State(initialValue: trip.startDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    routePreview
                } header: {
                    Text("Route")
                }

                Section {
                    DatePicker("Pickup Time", selection: $scheduledTime, in: Date()...)

                    Stepper("Passengers: \(passengerCount)", value: $passengerCount, in: 1...6)
                } header: {
                    Text("Booking Details")
                }

                Section {
                    TextField("Special requests", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Notes (Optional)")
                }

                Section {
                    if isEstimating {
                        HStack {
                            ProgressView()
                            Text("Calculating fare...")
                                .foregroundStyle(.secondary)
                        }
                    } else if let estimate = estimatedFare {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Base Fare")
                                Spacer()
                                Text("NT$\(estimate.baseFare)")
                            }
                            HStack {
                                Text("Distance")
                                Spacer()
                                Text("NT$\(estimate.distanceFare)")
                            }
                            if estimate.nightSurcharge > 0 {
                                HStack {
                                    Text("Night Surcharge")
                                    Spacer()
                                    Text("NT$\(estimate.nightSurcharge)")
                                }
                            }
                            Divider()
                            HStack {
                                Text("Estimated Total")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("NT$\(estimate.totalFare)")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                            }
                        }
                    } else {
                        Text("Fare will be calculated")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Fare Estimate")
                } footer: {
                    Text("Final fare may vary based on traffic and actual route.")
                }
            }
            .navigationTitle("Book Taxi")
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
                    .disabled(taxiViewModel.isLoading)
                }
            }
            .task {
                await estimateFare()
            }
            .overlay {
                if taxiViewModel.isLoading {
                    ProgressView("Booking...")
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var routePreview: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 12, height: 12)
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(width: 2, height: 30)
                Circle()
                    .fill(.red)
                    .frame(width: 12, height: 12)
            }

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("From")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(fromDestination.name)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("To")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(toDestination.name)
                        .fontWeight(.medium)
                }
            }
        }
    }

    private func estimateFare() async {
        isEstimating = true

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: scheduledTime)
        let isNightTime = hour >= 23 || hour < 6

        // Get distance from destination travel info or estimate
        let distanceMeters = toDestination.travelDistanceMeters ?? 5000
        let durationMinutes = toDestination.travelDurationMinutes ?? 15

        estimatedFare = TaxiFareEstimate.estimate(
            distanceMeters: distanceMeters,
            durationMinutes: durationMinutes,
            isNightTime: isNightTime
        )

        isEstimating = false
    }

    private func bookTaxi() {
        let pickupLocation = TaxiLocation(from: fromDestination)
        let dropoffLocation = TaxiLocation(from: toDestination)

        Task {
            await taxiViewModel.createBooking(
                pickupLocation: pickupLocation,
                dropoffLocation: dropoffLocation,
                scheduledTime: scheduledTime,
                passengerCount: passengerCount,
                notes: notes,
                linkedTripId: trip.id,
                linkedDestinationId: toDestination.id
            )
            dismiss()
        }
    }
}

// MARK: - Trip Taxi Bookings Section

struct TripTaxiBookingsSection: View {
    let trip: Trip
    @ObservedObject var taxiViewModel: TaxiBookingViewModel

    var tripBookings: [TaxiBooking] {
        taxiViewModel.getBookingsForTrip(tripId: trip.id)
    }

    var body: some View {
        if !tripBookings.isEmpty {
            Section {
                ForEach(tripBookings) { booking in
                    NavigationLink {
                        TaxiBookingDetailView(booking: booking, viewModel: taxiViewModel)
                    } label: {
                        TaxiBookingRowView(booking: booking)
                    }
                }
            } header: {
                Label("Taxi Bookings", systemImage: "car.side.fill")
            }
        }
    }
}

// MARK: - Destination Taxi Button

struct DestinationTaxiButton: View {
    let trip: Trip
    let destination: TripDestination
    let previousDestination: TripDestination?
    @ObservedObject var taxiViewModel: TaxiBookingViewModel
    @State private var showingBooking = false

    var canBookTaxi: Bool {
        previousDestination != nil && destination.travelMode == .taxi
    }

    var body: some View {
        if canBookTaxi, let prevDest = previousDestination {
            Button {
                showingBooking = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "car.side.fill")
                    Text("Book Taxi")
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingBooking) {
                BookTaxiForTripView(
                    trip: trip,
                    fromDestination: prevDest,
                    toDestination: destination,
                    taxiViewModel: taxiViewModel
                )
            }
        }
    }
}

#if DEBUG
private struct BookTaxiForTripView_Previews: PreviewProvider {
    static var previews: some View {
        let trip = Trip(
            name: "Test Trip",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400),
            destinations: [
                TripDestination(
                    name: "Taipei 101",
                    address: "Xinyi District",
                    latitude: 25.0339,
                    longitude: 121.5645,
                    order: 0
                ),
                TripDestination(
                    name: "Shilin Night Market",
                    address: "Shilin District",
                    latitude: 25.0879,
                    longitude: 121.5243,
                    order: 1,
                    travelDurationMinutes: 25,
                    travelDistanceMeters: 8000,
                    travelMode: .taxi
                )
            ]
        )

        return BookTaxiForTripView(
            trip: trip,
            fromDestination: trip.destinations[0],
            toDestination: trip.destinations[1],
            taxiViewModel: TaxiBookingViewModel()
        )
    }
}
#endif
