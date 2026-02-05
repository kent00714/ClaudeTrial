import SwiftUI

struct MainTabView: View {
    @StateObject private var flightViewModel = FlightViewModel()
    @StateObject private var tripViewModel = TripViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Flights Tab
            FlightsTabView(viewModel: flightViewModel)
                .tabItem {
                    Label("Flights", systemImage: "airplane.departure")
                }
                .tag(0)

            // Discover Tab (AI Suggestions)
            TripSuggestionsView(tripViewModel: tripViewModel)
                .tabItem {
                    Label("Discover", systemImage: "sparkles")
                }
                .tag(1)

            // Trips Tab
            TripListView(viewModel: tripViewModel)
                .tabItem {
                    Label("My Trips", systemImage: "map")
                }
                .tag(2)
        }
    }
}

struct FlightsTabView: View {
    @ObservedObject var viewModel: FlightViewModel

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Direction picker (Arrivals / Departures)
                Picker("Direction", selection: $viewModel.selectedDirection) {
                    ForEach(FlightDirection.allCases) { direction in
                        Text(direction.rawValue).tag(direction)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                // Last updated / next refresh bar
                if let lastUpdated = viewModel.lastUpdated {
                    HStack {
                        Text("Updated \(timeFormatter.string(from: lastUpdated))")
                        Spacer()
                        if let nextRefresh = viewModel.nextRefresh {
                            Text("Next: \(timeFormatter.string(from: nextRefresh))")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }

                // Flight list
                FlightListView(viewModel: viewModel)
            }
            .navigationTitle("TPE Flights")
            .searchable(text: $viewModel.searchText, prompt: "Search flights, airlines, cities...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Retry") {
                    Task { await viewModel.loadFlights() }
                }
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear {
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
    }
}

#Preview {
    MainTabView()
}
