import SwiftUI

struct FlightListView: View {
    @ObservedObject var viewModel: FlightViewModel

    var body: some View {
        List {
            if viewModel.filteredFlights.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Flights Found",
                    systemImage: "airplane.circle",
                    description: Text("No flights match your search.")
                )
            } else {
                ForEach(viewModel.filteredFlights) { flight in
                    NavigationLink(destination: FlightDetailView(flight: flight)) {
                        FlightRowView(flight: flight)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
        .overlay {
            if viewModel.isLoading && viewModel.filteredFlights.isEmpty {
                ProgressView("Loading flights...")
            }
        }
    }
}

// MARK: - Flight Row

struct FlightRowView: View {
    let flight: Flight

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }

    var body: some View {
        HStack(spacing: 12) {
            // Airline & Flight Number
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.flightNumber)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(flight.airline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 100, alignment: .leading)

            // City
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.counterpartCity)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(flight.counterpartIATA)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Time & Status
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeFormatter.string(from: flight.displayTime))
                    .font(.subheadline)
                    .fontWeight(.medium)

                if flight.isDelayed, flight.estimatedTime != nil {
                    Text(timeFormatter.string(from: flight.scheduledTime))
                        .font(.caption2)
                        .strikethrough()
                        .foregroundStyle(.secondary)
                }

                FlightStatusBadge(status: flight.status)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

struct FlightStatusBadge: View {
    let status: FlightStatus

    var statusColor: Color {
        switch status {
        case .scheduled: return .gray
        case .boarding: return .blue
        case .departed, .inAir, .landed, .arrived: return .green
        case .delayed: return .orange
        case .cancelled: return .red
        case .active: return .blue
        case .diverted: return .purple
        case .unknown: return .gray
        }
    }

    var body: some View {
        Text(LocalizedStringKey(status.rawValue))
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }
}
