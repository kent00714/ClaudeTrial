import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FlightViewModel()

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
                .padding()

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
        .task {
            await viewModel.loadFlights()
        }
    }
}

#Preview {
    ContentView()
}
