import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var languageManager: LanguageManager
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
                    Label(languageManager.t(.tabFlights), systemImage: "airplane.departure")
                }
                .tag(0)

            // Discover Tab (AI Suggestions)
            TripSuggestionsView(tripViewModel: tripViewModel)
                .tabItem {
                    Label(languageManager.t(.tabDiscover), systemImage: "sparkles")
                }
                .tag(1)

            // Trips Tab
            TripListView(viewModel: tripViewModel)
                .tabItem {
                    Label(languageManager.t(.tabTrips), systemImage: "map")
                }
                .tag(2)

            // Taxi Tab
            TaxiBookingListView()
                .tabItem {
                    Label(languageManager.t(.tabTaxi), systemImage: "car.side.fill")
                }
                .tag(3)

            // Hotels Tab
            HotelSearchView()
                .tabItem {
                    Label(languageManager.t(.tabHotels), systemImage: "bed.double.fill")
                }
                .tag(4)
        }
        .overlay(alignment: .topTrailing) {
            Menu {
                ForEach(LanguageManager.Language.allCases) { language in
                    Button {
                        languageManager.setLanguage(language)
                    } label: {
                        if languageManager.currentLanguage == language {
                            Label(languageManager.displayName(for: language), systemImage: "checkmark")
                        } else {
                            Text(languageManager.displayName(for: language))
                        }
                    }
                }
            } label: {
                Image(systemName: "globe")
                    .font(.headline)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(languageManager.t(.language))
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .alert(languageManager.t(.tripImportedTitle), isPresented: $showingImportSuccess) {
            Button(languageManager.t(.viewTrip)) {
                selectedTab = 2 // Switch to My Trips tab
            }
            Button(languageManager.t(.ok), role: .cancel) { }
        } message: {
            Text(languageManager.tripImportedMessage(importedTripName))
        }
        .alert(languageManager.t(.importFailed), isPresented: $showingImportError) {
            Button(languageManager.t(.ok), role: .cancel) { }
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
    @EnvironmentObject private var languageManager: LanguageManager
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
                Picker(languageManager.t(.direction), selection: $viewModel.selectedDirection) {
                    ForEach(FlightDirection.allCases) { direction in
                        Text(languageManager.directionText(direction)).tag(direction)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                // Last updated / next refresh bar
                if let lastUpdated = viewModel.lastUpdated {
                    HStack {
                        Text("\(languageManager.t(.updated)) \(timeFormatter.string(from: lastUpdated))")
                        Spacer()
                        if let nextRefresh = viewModel.nextRefresh {
                            Text("\(languageManager.t(.next)): \(timeFormatter.string(from: nextRefresh))")
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
            .navigationTitle(languageManager.t(.flightsTitle))
            .searchable(text: $viewModel.searchText, prompt: languageManager.t(.searchPrompt))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert(languageManager.t(.error), isPresented: .constant(viewModel.errorMessage != nil)) {
                Button(languageManager.t(.retry)) {
                    Task { await viewModel.loadFlights() }
                }
                Button(languageManager.t(.ok), role: .cancel) {
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
            .environmentObject(LanguageManager())
    }
}
#endif
