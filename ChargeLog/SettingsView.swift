import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Stammdaten") {
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
