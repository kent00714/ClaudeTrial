import SwiftUI
import MapKit

struct SuggestionDetailView: View {
    let suggestion: TripSuggestion
    let onAddToTrips: (String, Date, String) -> Void  // (name, startDate, notes)

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDestination: SuggestedDestination?
    @State private var showingCustomizeSheet = false
    @State private var mapRegion: MKCoordinateRegion

    init(suggestion: TripSuggestion, onAddToTrips: @escaping (String, Date, String) -> Void) {
        self.suggestion = suggestion
        self.onAddToTrips = onAddToTrips

        // Calculate map region to show all destinations
        if let first = suggestion.destinations.first {
            let coordinates = suggestion.destinations.map { $0.coordinate }
            let minLat = coordinates.map(\.latitude).min() ?? first.latitude
            let maxLat = coordinates.map(\.latitude).max() ?? first.latitude
            let minLon = coordinates.map(\.longitude).min() ?? first.longitude
            let maxLon = coordinates.map(\.longitude).max() ?? first.longitude

            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            let span = MKCoordinateSpan(
                latitudeDelta: max(0.05, (maxLat - minLat) * 1.5),
                longitudeDelta: max(0.05, (maxLon - minLon) * 1.5)
            )
            _mapRegion = State(initialValue: MKCoordinateRegion(center: center, span: span))
        } else {
            // Default to Taipei
            _mapRegion = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Map Header
                    mapSection

                    VStack(spacing: 24) {
                        // Title Section
                        titleSection

                        // Quick Info
                        quickInfoSection

                        // Description
                        descriptionSection

                        // Highlights
                        if !suggestion.highlights.isEmpty {
                            highlightsSection
                        }

                        // Best Seasons
                        if !suggestion.bestSeasons.contains(.all) && !suggestion.bestSeasons.isEmpty {
                            bestSeasonsSection
                        }

                        // Seasonal Note
                        if let note = suggestion.seasonalNote {
                            seasonalNoteSection(note: note)
                        }

                        // Destinations
                        destinationsSection

                        // Add to Trips Button
                        addToTripsButton
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedDestination) { destination in
                DestinationDetailSheet(destination: destination)
            }
            .sheet(isPresented: $showingCustomizeSheet) {
                CustomizeTripSheet(
                    suggestion: suggestion,
                    onConfirm: { name, startDate, notes in
                        onAddToTrips(name, startDate, notes)
                        showingCustomizeSheet = false
                    }
                )
            }
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        Map(coordinateRegion: .constant(mapRegion), annotationItems: suggestion.destinations) { destination in
            MapAnnotation(coordinate: destination.coordinate) {
                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 30, height: 30)
                            .shadow(radius: 2)

                        Text("\(destination.order + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                }
                .onTapGesture {
                    selectedDestination = destination
                }
            }
        }
        .frame(height: 200)
        .allowsHitTesting(true)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Badges row
            HStack(spacing: 8) {
                // Category Badge
                HStack {
                    Image(systemName: suggestion.category.systemImage)
                    Text(suggestion.category.displayName)
                }
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())

                // Trending Badge
                if let badge = suggestion.trendingData?.trendingBadge {
                    HStack(spacing: 4) {
                        if badge == "Hot" {
                            Image(systemName: "flame.fill")
                        }
                        Text(badge)
                        if let direction = suggestion.trendingData?.trendDirection {
                            Image(systemName: direction.systemImage)
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(badge == "Hot" ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundStyle(badge == "Hot" ? .red : .orange)
                    .clipShape(Capsule())
                }

                // Seasonal Badge
                if suggestion.isGoodForCurrentSeason && suggestion.trendingData?.peakSeason == Season.current {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Perfect Now")
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
                }
            }

            Text(suggestion.name)
                .font(.title)
                .fontWeight(.bold)

            // Dynamic subtitle with trending reason
            if suggestion.trendingData?.isCurrentlyHot == true, let reason = suggestion.trendingData?.trendingReason {
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            } else {
                Text(suggestion.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Social proof
            if let mentions = suggestion.trendingData?.formattedMentions, suggestion.trendingData?.socialMentions ?? 0 > 1000 {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                        Text("\(mentions) social mentions")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let direction = suggestion.trendingData?.trendDirection {
                        HStack(spacing: 2) {
                            Image(systemName: direction.systemImage)
                            Text(direction == .rising ? "Rising" : direction == .declining ? "Cooling" : "Steady")
                        }
                        .font(.caption)
                        .foregroundStyle(direction == .rising ? .green : direction == .declining ? .red : .secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Quick Info Section

    private var quickInfoSection: some View {
        HStack(spacing: 0) {
            InfoItem(
                icon: "clock",
                title: "Duration",
                value: suggestion.duration.displayName
            )

            Divider()
                .frame(height: 40)

            InfoItem(
                icon: "mappin.circle",
                title: "Stops",
                value: "\(suggestion.destinations.count)"
            )

            Divider()
                .frame(height: 40)

            InfoItem(
                icon: "dollarsign.circle",
                title: "Budget",
                value: suggestion.budgetLevel.displayName
            )

            Divider()
                .frame(height: 40)

            InfoItem(
                icon: suggestion.difficulty.systemImage,
                title: "Level",
                value: suggestion.difficulty.displayName
            )
        }
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About This Trip")
                .font(.headline)

            Text(suggestion.description)
                .font(.body)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "sun.max")
                Text("Best Time: \(suggestion.bestTime)")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Highlights Section

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(suggestion.highlights, id: \.self) { highlight in
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(highlight)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Best Seasons Section

    private var bestSeasonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Time to Visit")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(suggestion.bestSeasons, id: \.self) { season in
                    let isCurrent = season == Season.current
                    HStack(spacing: 4) {
                        Image(systemName: seasonIcon(for: season))
                        Text(season.displayName.components(separatedBy: " ").first ?? season.rawValue.capitalized)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrent ? Color.green.opacity(0.2) : Color(.systemGray6))
                    .foregroundStyle(isCurrent ? .green : .primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isCurrent ? Color.green : Color.clear, lineWidth: 2)
                    )
                }
            }

            if suggestion.bestSeasons.contains(Season.current) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Great time to visit!")
                        .foregroundStyle(.green)
                }
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func seasonIcon(for season: Season) -> String {
        switch season {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .autumn: return "wind"
        case .winter: return "snowflake"
        case .all: return "calendar"
        }
    }

    // MARK: - Seasonal Note Section

    private func seasonalNoteSection(note: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)

            Text(note)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Destinations Section

    private var destinationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Itinerary")
                .font(.headline)

            ForEach(Array(suggestion.destinations.enumerated()), id: \.element.id) { index, destination in
                DestinationRow(
                    destination: destination,
                    isLast: index == suggestion.destinations.count - 1
                )
                .onTapGesture {
                    selectedDestination = destination
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Add to Trips Button

    private var addToTripsButton: some View {
        VStack(spacing: 12) {
            // Primary action - Add and Customize
            Button {
                showingCustomizeSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add to My Trips")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Customization hint
            Text("You can customize dates, destinations, and notes after adding")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
}

// MARK: - Info Item

struct InfoItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Destination Row

struct DestinationRow: View {
    let destination: SuggestedDestination
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 32, height: 32)

                    Text("\(destination.order + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(destination.name)
                    .font(.headline)

                if !destination.nameLocal.isEmpty {
                    Text(destination.nameLocal)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(destination.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: 16) {
                    Label(destination.formattedEstimatedTime, systemImage: "clock")
                    Label(destination.suggestedTravelMode.displayName, systemImage: destination.suggestedTravelMode.systemImage)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Tips preview
                if let firstTip = destination.tips.first {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(firstTip)
                            .lineLimit(2)
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
    }
}

// MARK: - Destination Detail Sheet

struct DestinationDetailSheet: View {
    let destination: SuggestedDestination
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Map
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: destination.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [destination]) { dest in
                        MapMarker(coordinate: dest.coordinate, tint: .blue)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text(destination.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        if !destination.nameLocal.isEmpty {
                            Text(destination.nameLocal)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Address
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.red)
                        Text(destination.address)
                    }
                    .font(.subheadline)

                    // Description
                    if !destination.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)

                            Text(destination.description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Info
                    HStack(spacing: 24) {
                        VStack(alignment: .leading) {
                            Text("Time Needed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(destination.formattedEstimatedTime)
                                .font(.headline)
                        }

                        VStack(alignment: .leading) {
                            Text("Travel By")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: destination.suggestedTravelMode.systemImage)
                                Text(destination.suggestedTravelMode.displayName)
                            }
                            .font(.headline)
                        }
                    }

                    // Tips
                    if !destination.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tips")
                                .font(.headline)

                            ForEach(destination.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(.yellow)
                                    Text(tip)
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Open in Maps Button
                    Button {
                        openInMaps()
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Open in Maps")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Destination Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: destination.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = destination.name
        mapItem.openInMaps()
    }
}

// MARK: - Flow Layout (for tags/highlights)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            height = y + rowHeight
        }
    }
}

// MARK: - Customize Trip Sheet

struct CustomizeTripSheet: View {
    let suggestion: TripSuggestion
    let onConfirm: (String, Date, String) -> Void  // (name, startDate, notes)

    @Environment(\.dismiss) private var dismiss
    @State private var tripName: String
    @State private var startDate: Date = Date()
    @State private var notes: String

    init(suggestion: TripSuggestion, onConfirm: @escaping (String, Date, String) -> Void) {
        self.suggestion = suggestion
        self.onConfirm = onConfirm
        _tripName = State(initialValue: suggestion.name)
        _notes = State(initialValue: suggestion.description)
    }

    var endDate: Date {
        Calendar.current.date(
            byAdding: .day,
            value: suggestion.duration.days,
            to: startDate
        ) ?? startDate
    }

    var body: some View {
        NavigationStack {
            Form {
                // Trip Summary
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: suggestion.category.systemImage)
                                .foregroundStyle(.blue)
                            Text(suggestion.category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(suggestion.name)
                            .font(.headline)

                        HStack(spacing: 16) {
                            Label("\(suggestion.destinations.count) stops", systemImage: "mappin")
                            Label(suggestion.duration.displayName, systemImage: "clock")
                            Label(suggestion.budgetLevel.dollarSigns, systemImage: "dollarsign.circle")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Adding to Your Trips")
                }

                // Customize Name
                Section("Customize") {
                    TextField("Trip Name", text: $tripName)

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    HStack {
                        Text("End Date")
                        Spacer()
                        Text(formatDate(endDate))
                            .foregroundStyle(.secondary)
                    }
                }

                // Optional Notes
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }

                // What's Included
                Section {
                    ForEach(suggestion.destinations.prefix(3)) { destination in
                        HStack {
                            Text("\(destination.order + 1).")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                            Text(destination.name)
                                .lineLimit(1)
                        }
                        .font(.subheadline)
                    }

                    if suggestion.destinations.count > 3 {
                        Text("+ \(suggestion.destinations.count - 3) more destinations")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Included Destinations")
                } footer: {
                    Text("You can add, remove, or reorder destinations after adding to your trips.")
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Trip") {
                        onConfirm(tripName, startDate, notes)
                    }
                    .fontWeight(.semibold)
                    .disabled(tripName.isEmpty)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
