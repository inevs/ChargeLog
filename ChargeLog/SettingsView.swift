import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Stammdaten") {
                    NavigationLink {
                        VehicleListView()
                    } label: {
                        Label("Fahrzeuge", systemImage: "car")
                    }
                    NavigationLink {
                        TariffsListView()
                    } label: {
                        Label("Tarife", systemImage: "creditcard")
                    }
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    SettingsView()
}
