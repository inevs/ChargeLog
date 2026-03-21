import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "bolt.circle.fill") {
                Text("My Statistics")
            }
            Tab("Charging Stations", systemImage: "ev.charger.fill") {
                Text("List of Charging Stations")
            }
            Tab("Sessions", systemImage: "clock.fill") {
                ChargingSessionsListView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                Text("Here we change our settings")
            }
        }
    }
}

#Preview("Empty State", traits: .modifier(EmptyPersistencePreview())) {
    MainView()
}

#Preview("Sample Data", traits: .modifier(SampleDataPersistencePreview())) {
    MainView()
}
