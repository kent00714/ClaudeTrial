import SwiftUI

struct MainTabView: View {
    @StateObject private var flightViewModel = FlightViewModel()
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var taxiViewModel = TaxiBookingViewModel()
    @State private var selectedTab = 0
    @State private var showingImportSuccess = false
    @State private var showingImportError = false
    @State private var importedTripName = ""
    @State private var importErrorMessage = ""

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

            // Taxi Tab
            TaxiBookingListView()
                .tabItem {
                    Label("Taxi", systemImage: "car.side.fill")
                }
                .tag(3)

            // Hotels Tab
            HotelSearchView()
                .tabItem {
                    Label("Hotels", systemImage: "bed.double.fill")
                }
                .tag(4)
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .alert("Trip Imported!", isPresented: $showingImportSuccess) {
            Button("View Trip") {
                selectedTab = 2 // Switch to My Trips tab
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("'\(importedTripName)' has been added to your trips.")
        }
        .alert("Import Failed", isPresented: $showingImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importErrorMessage)
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == Trip.urlScheme else { return }

        do {
            var importedTrip = try Trip.importFromLink(url)

            // Create a new ID to avoid conflicts with existing trips
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

            tripViewModel.createTripFromSuggestion(importedTrip)
            importedTripName = importedTrip.name
            showingImportSuccess = true
        } catch {
            importErrorMessage = error.localizedDescription
            showingImportError = true
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

#if DEBUG
private struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
#endif
