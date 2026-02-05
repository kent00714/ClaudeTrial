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

                    // Hot Right Now Section (viral content)
                    if viewModel.searchQuery.isEmpty && !viewModel.hotRightNow.isEmpty {
                        hotRightNowSection
                    }

                    // Seasonal Picks
                    if viewModel.searchQuery.isEmpty && !viewModel.seasonalPicks.isEmpty {
                        seasonalSection
                    }

                    // First Time Visitors Section
                    if viewModel.searchQuery.isEmpty {
                        firstTimeSection
                    }

                    // Trending Section
                    if viewModel.searchQuery.isEmpty && !viewModel.trendingSuggestions.isEmpty {
                        trendingSection
                    }

                    // Upcoming Events
                    if viewModel.searchQuery.isEmpty && !viewModel.upcomingEvents.isEmpty {
                        upcomingEventsSection
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refreshTrending()
                        }
                    } label: {
                        if viewModel.isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel.isRefreshing)
                }
            }
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

    // MARK: - Hot Right Now Section

    private var hotRightNowSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.red)
                Text("Hot Right Now")
                    .font(.headline)
                Image(systemName: "sparkle")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            Text("Viral destinations trending on social media")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.hotRightNow) { suggestion in
                        HotSuggestionCard(suggestion: suggestion)
                            .onTapGesture {
                                viewModel.selectedSuggestion = suggestion
                            }
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.red.opacity(0.1), .orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Seasonal Section

    private var seasonalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: Season.current == .spring ? "leaf.fill" :
                        Season.current == .summer ? "sun.max.fill" :
                        Season.current == .autumn ? "wind" : "snowflake")
                    .foregroundStyle(.green)
                Text("Best for \(Season.current.displayName.components(separatedBy: " ").first ?? "Now")")
                    .font(.headline)
            }

            Text(Season.current.taiwanHighlights)
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.seasonalPicks) { suggestion in
                        SuggestionCard(suggestion: suggestion, style: .compact)
                            .onTapGesture {
                                viewModel.selectedSuggestion = suggestion
                            }
                    }
                }
            }
        }
    }

    // MARK: - Upcoming Events Section

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.purple)
                Text("Upcoming Events")
                    .font(.headline)
            }

            ForEach(viewModel.upcomingEvents.prefix(3)) { event in
                EventRow(event: event)
            }
        }
    }

    // MARK: - Trending Section

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.orange)
                Text("Trending Trips")
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
            // Top row: Category Badge + Trending Badge
            HStack {
                HStack {
                    Image(systemName: suggestion.category.systemImage)
                    Text(suggestion.category.displayName)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())

                Spacer()

                // Trending Badge
                if let trendingBadge = suggestion.trendingData?.trendingBadge {
                    TrendingBadge(badge: trendingBadge, direction: suggestion.trendingData?.trendDirection)
                }
            }

            // Title
            Text(suggestion.name)
                .font(style == .featured ? .headline : .subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            // Dynamic subtitle (shows trending reason if hot)
            if style == .featured {
                Text(suggestion.dynamicSubtitle)
                    .font(.caption)
                    .foregroundStyle(suggestion.trendingData?.isCurrentlyHot == true ? .orange : .secondary)
                    .lineLimit(2)
            }

            // Info Row
            HStack(spacing: 12) {
                Label(suggestion.duration.displayName, systemImage: "clock")
                Label("\(suggestion.destinations.count) stops", systemImage: "mappin")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            // Bottom row: Budget + Social mentions
            HStack {
                Text(suggestion.budgetLevel.dollarSigns)
                    .font(.caption)
                    .foregroundStyle(.green)

                Spacer()

                if let mentions = suggestion.trendingData?.formattedMentions, suggestion.trendingData?.socialMentions ?? 0 > 1000 {
                    HStack(spacing: 2) {
                        Image(systemName: "bubble.left.fill")
                            .font(.caption2)
                        Text(mentions)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(width: style == .featured ? 280 : 200)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(alignment: .topTrailing) {
            if suggestion.trendingData?.isCurrentlyHot == true {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .padding(8)
            }
        }
    }
}

// MARK: - Hot Suggestion Card

struct HotSuggestionCard: View {
    let suggestion: TripSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Hot badge with reason
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.red)
                if let reason = suggestion.trendingData?.trendingReason {
                    Text(reason)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
            }

            Text(suggestion.name)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(2)

            // Social proof
            if let mentions = suggestion.trendingData?.formattedMentions {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.fill")
                        .font(.caption2)
                    Text("\(mentions) mentions")
                        .font(.caption2)

                    if let direction = suggestion.trendingData?.trendDirection, direction == .rising {
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label(suggestion.duration.displayName, systemImage: "clock")
                Label(suggestion.budgetLevel.dollarSigns, systemImage: "dollarsign.circle")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 220)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), .red.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .red.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: SpecialEvent

    var body: some View {
        HStack(spacing: 12) {
            // Date indicator
            VStack(spacing: 2) {
                Text(monthString)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text(dayString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.purple)
            }
            .frame(width: 50)
            .padding(.vertical, 8)
            .background(Color.purple.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if event.isHappeningNow {
                        Text("NOW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }

                Text(event.nameLocal)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(event.location)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: event.startDate).uppercased()
    }

    private var dayString: String {
        let day = Calendar.current.component(.day, from: event.startDate)
        return "\(day)"
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
                    HStack(spacing: 8) {
                        Text(suggestion.name)
                            .font(.headline)

                        // Trending badge
                        if let badge = suggestion.trendingData?.trendingBadge {
                            TrendingBadge(badge: badge, direction: suggestion.trendingData?.trendDirection, compact: true)
                        }
                    }

                    Text(suggestion.dynamicSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(suggestion.trendingData?.isCurrentlyHot == true ? .orange : .secondary)
                }

                Spacer()

                // Trend direction arrow
                if let direction = suggestion.trendingData?.trendDirection {
                    Image(systemName: direction.systemImage)
                        .font(.caption)
                        .foregroundStyle(direction == .rising ? .green : (direction == .declining ? .red : .secondary))
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label(suggestion.duration.displayName, systemImage: "clock")
                Label("\(suggestion.destinations.count) stops", systemImage: "mappin")
                Label(suggestion.budgetLevel.dollarSigns, systemImage: "dollarsign.circle")
                Label(suggestion.difficulty.displayName, systemImage: suggestion.difficulty.systemImage)

                // Social mentions
                if let mentions = suggestion.trendingData?.formattedMentions, suggestion.trendingData?.socialMentions ?? 0 > 1000 {
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "bubble.left.fill")
                        Text(mentions)
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Tags with seasonal indicator
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Seasonal tag if good for current season
                    if suggestion.isGoodForCurrentSeason && suggestion.trendingData?.peakSeason == Season.current {
                        Text("Perfect for \(Season.current.displayName.components(separatedBy: " ").first ?? "now")")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }

                    ForEach(suggestion.tags.prefix(3), id: \.self) { tag in
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
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(alignment: .topLeading) {
            if suggestion.trendingData?.isCurrentlyHot == true {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .padding(8)
            }
        }
    }
}

// MARK: - Trending Badge

struct TrendingBadge: View {
    let badge: String
    let direction: TrendDirection?
    var compact: Bool = false

    var badgeColor: Color {
        switch badge {
        case "Hot": return .red
        case "Popular": return .orange
        case "Rising": return .green
        default: return .blue
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            if badge == "Hot" {
                Image(systemName: "flame.fill")
                    .font(.caption2)
            }
            Text(badge)
                .font(.caption2)
                .fontWeight(.semibold)
            if !compact, let direction = direction {
                Image(systemName: direction.systemImage)
                    .font(.caption2)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 2 : 4)
        .background(badgeColor.opacity(0.2))
        .foregroundStyle(badgeColor)
        .clipShape(Capsule())
    }
}

// MARK: - View Model

@MainActor
class TripSuggestionsViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var selectedCategory: SuggestionCategory?
    @Published var selectedSuggestion: TripSuggestion?
    @Published var showingAddedAlert = false
    @Published var isRefreshing = false

    private let tripViewModel: TripViewModel
    private let suggestionService: TripSuggestionServiceProtocol

    var firstTimeSuggestions: [TripSuggestion] {
        suggestionService.getRecommendedForFirstTimers()
    }

    var trendingSuggestions: [TripSuggestion] {
        suggestionService.getTrendingSuggestions()
    }

    var hotRightNow: [TripSuggestion] {
        suggestionService.getHotRightNow()
    }

    var seasonalPicks: [TripSuggestion] {
        suggestionService.getSeasonalSuggestions().prefix(5).map { $0 }
    }

    var upcomingEvents: [SpecialEvent] {
        suggestionService.getUpcomingEvents()
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

    func refreshTrending() async {
        isRefreshing = true
        await suggestionService.refreshTrendingData()
        isRefreshing = false
    }
}
