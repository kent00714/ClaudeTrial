import SwiftUI

struct HotelSearchView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Hotel Search", systemImage: "bed.double.fill")
            } description: {
                Text("Hotel search is coming soon.")
            }
            .navigationTitle("Hotels")
        }
    }
}

#if DEBUG
private struct TripHotelSearchView_Previews: PreviewProvider {
    static var previews: some View {
        HotelSearchView()
    }
}
#endif
