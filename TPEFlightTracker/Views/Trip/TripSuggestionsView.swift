import SwiftUI

struct TripSuggestionsView: View {
    @StateObject private var viewModel: TripSuggestionsViewModel

    init(tripViewModel: TripViewModel, suggestionService: TripSuggestionServiceProtocol = TripSuggestionService()) {
        _viewModel = StateObject(wrappedValue: TripSuggestionsViewModel(
            tripViewModel: tripViewModel,
            suggestionService: suggestionService
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    welcomeHeader

                    // Search Bar
                    searchBar

                    // First Time Visitors Section
                    if viewModel.searchQuery.isEmpty {
                        firstTimeSection
                    }

                    // Trending Section
                    if viewModel.searchQuery.isEmpty && !viewModel.trendingSuggestions.isEmpty {
                        trendingSection
                    }

                    // Categories Grid
                    if viewModel.searchQuery.isEmpty {
                        categoriesSection
                    }

                    // Search Results
                    if !viewModel.searchQuery.isEmpty {
                        searchResultsSection
                    }

                    // Selected Category Results
                    if let category = viewModel.selectedCategory {
                        categoryResultsSection(category: category)
                    }
                }
                .padding()
            }
            .navigationTitle("Discover Taiwan")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $viewModel.selectedSuggestion) { suggestion in
                SuggestionDetailView(
                    suggestion: suggestion,
                    onAddToTrips: { viewModel.addSuggestionToTrips(suggestion) }
                )
            }
            .alert("Trip Added!", isPresented: $viewModel.showingAddedAlert) {
                Button("View My Trips") {
                    viewModel.showingAddedAlert = false
                }
                Button("Continue Browsing", role: .cancel) {
                    viewModel.showingAddedAlert = false
                }
            } message: {
                Text("The trip has been added to your trips. You can customize it anytime!")
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to Taiwan!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Let us help you plan the perfect trip. Browse curated itineraries designed especially for visitors like you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search destinations, activities...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - First Time Section

    private var firstTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.orange)
                Text("First Time in Taiwan?")
                    .font(.headline)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.firstTimeSuggestions) { suggestion in
                        SuggestionCard(suggestion: suggestion, style: .featured)
                            .onTapGesture {
                                viewModel.selectedSuggestion = suggestion
                            }
                    }
                }
            }
        }
    }

    // MARK: - Trending Section

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Trending Now")
                    .font(.headline)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.trendingSuggestions) { suggestion in
                        SuggestionCard(suggestion: suggestion, style: .compact)
                            .onTapGesture {
                                viewModel.selectedSuggestion = suggestion
                            }
                    }
                }
            }
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Browse by Category")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(SuggestionCategory.allCases) { category in
                    CategoryButton(category: category, isSelected: viewModel.selectedCategory == category)
                        .onTapGesture {
                            withAnimation {
                                if viewModel.selectedCategory == category {
                                    viewModel.selectedCategory = nil
                                } else {
                                    viewModel.selectedCategory = category
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search Results")
                .font(.headline)

            if viewModel.searchResults.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try searching for different keywords")
                )
            } else {
                ForEach(viewModel.searchResults) { suggestion in
                    SuggestionListRow(suggestion: suggestion)
                        .onTapGesture {
                            viewModel.selectedSuggestion = suggestion
                        }
                }
            }
        }
    }

    // MARK: - Category Results Section

    private func categoryResultsSection(category: SuggestionCategory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: category.systemImage)
                Text(category.displayName)
                    .font(.headline)

                Spacer()

                Button("Clear") {
                    withAnimation {
                        viewModel.selectedCategory = nil
                    }
                }
                .font(.subheadline)
            }

            Text(category.welcomeMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let categoryResults = viewModel.getSuggestions(for: category)
            if categoryResults.isEmpty {
                ContentUnavailableView(
                    "Coming Soon",
                    systemImage: "sparkles",
                    description: Text("More \(category.displayName.lowercased()) trips are being added!")
                )
            } else {
                ForEach(categoryResults) { suggestion in
                    SuggestionListRow(suggestion: suggestion)
                        .onTapGesture {
                            viewModel.selectedSuggestion = suggestion
                        }
                }
            }
        }
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let suggestion: TripSuggestion
    let style: CardStyle

    enum CardStyle {
        case featured
        case compact
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category Badge
            HStack {
                Image(systemName: suggestion.category.systemImage)
                Text(suggestion.category.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())

            // Title
            Text(suggestion.name)
                .font(style == .featured ? .headline : .subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            // Subtitle
            if style == .featured {
                Text(suggestion.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Info Row
            HStack(spacing: 12) {
                Label(suggestion.duration.displayName, systemImage: "clock")
                Label("\(suggestion.destinations.count) stops", systemImage: "mappin")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            // Budget
            Text(suggestion.budgetLevel.dollarSigns)
                .font(.caption)
                .foregroundStyle(.green)
        }
        .padding()
        .frame(width: style == .featured ? 280 : 200)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: SuggestionCategory
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: category.systemImage)
                .font(.title3)

            Text(category.displayName)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Suggestion List Row

struct SuggestionListRow: View {
    let suggestion: TripSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.name)
                        .font(.headline)

                    Text(suggestion.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label(suggestion.duration.displayName, systemImage: "clock")
                Label("\(suggestion.destinations.count) stops", systemImage: "mappin")
                Label(suggestion.budgetLevel.dollarSigns, systemImage: "dollarsign.circle")
                Label(suggestion.difficulty.displayName, systemImage: suggestion.difficulty.systemImage)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Tags
            if !suggestion.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestion.tags.prefix(4), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - View Model

@MainActor
class TripSuggestionsViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var selectedCategory: SuggestionCategory?
    @Published var selectedSuggestion: TripSuggestion?
    @Published var showingAddedAlert = false

    private let tripViewModel: TripViewModel
    private let suggestionService: TripSuggestionServiceProtocol

    var firstTimeSuggestions: [TripSuggestion] {
        suggestionService.getRecommendedForFirstTimers()
    }

    var trendingSuggestions: [TripSuggestion] {
        suggestionService.getTrendingSuggestions()
    }

    var searchResults: [TripSuggestion] {
        guard !searchQuery.isEmpty else { return [] }
        return suggestionService.searchSuggestions(query: searchQuery)
    }

    init(tripViewModel: TripViewModel, suggestionService: TripSuggestionServiceProtocol) {
        self.tripViewModel = tripViewModel
        self.suggestionService = suggestionService
    }

    func getSuggestions(for category: SuggestionCategory) -> [TripSuggestion] {
        suggestionService.getSuggestions(for: category)
    }

    func addSuggestionToTrips(_ suggestion: TripSuggestion) {
        let trip = suggestion.toTrip()
        tripViewModel.createTripFromSuggestion(trip)
        selectedSuggestion = nil
        showingAddedAlert = true
    }
}
