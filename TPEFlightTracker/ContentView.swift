import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FlightViewModel()

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
    ContentView()
}
