import SwiftUI

struct FlightDetailView: View {
    let flight: Flight

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Route
                routeSection

                // Details
                detailsSection

                // Codeshares
                if !flight.codeshares.isEmpty {
                    codesharesSection
                }
            }
            .padding()
        }
        .navigationTitle(flight.flightNumber)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(flight.airline)
                .font(.title2)
                .fontWeight(.bold)

            Text(flight.flightNumber)
                .font(.title3)
                .foregroundStyle(.secondary)

            FlightStatusBadge(status: flight.status)

            if let aircraft = flight.aircraft {
                Text(aircraft)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Route

    private var routeSection: some View {
        VStack(spacing: 16) {
            Text("Route")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                // Origin
                VStack(spacing: 4) {
                    Text(flight.origin.iata)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(flight.origin.city)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Arrow
                VStack(spacing: 4) {
                    Image(systemName: "airplane")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Destination
                VStack(spacing: 4) {
                    Text(flight.destination.iata)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(flight.destination.city)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(spacing: 16) {
            Text("Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                detailRow(label: "Date", value: dateFormatter.string(from: flight.scheduledTime))

                Divider()

                detailRow(label: "Scheduled", value: timeFormatter.string(from: flight.scheduledTime))

                if let estimated = flight.estimatedTime {
                    Divider()
                    detailRow(label: "Estimated", value: timeFormatter.string(from: estimated))
                }

                if let actual = flight.actualTime {
                    Divider()
                    detailRow(label: "Actual", value: timeFormatter.string(from: actual))
                }

                Divider()

                detailRow(label: "Terminal", value: flight.terminal)

                if let gate = flight.gate {
                    Divider()
                    detailRow(label: "Gate", value: gate)
                }
            }
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Codeshares

    private var codesharesSection: some View {
        VStack(spacing: 16) {
            Text("Codeshare Flights")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(flight.codeshares, id: \.self) { code in
                    Text(code)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
