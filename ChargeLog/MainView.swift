import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "bolt.circle.fill") {
                StatisticsView()
            }
            Tab("Charging Stations", systemImage: "ev.charger.fill") {
                NavigationStack {
                    ChargeStationListView()
                }
            }
            Tab("Sessions", systemImage: "clock.fill") {
                ChargingSessionsListView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
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
