import SwiftUI

struct SettingsView: View {
    @AppStorage("batteryCapacityKwh") private var batteryCapacityKwh: Double = 0
    @State private var batteryCapacityText: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Fahrzeug") {
                    HStack {
                        Text("Batteriegröße")
                        Spacer()
                        TextField("z.B. 77", text: $batteryCapacityText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: batteryCapacityText) { _, newValue in
                                batteryCapacityKwh = Double(newValue.replacingOccurrences(of: ",", with: ".")) ?? 0
                            }
                        Text("kWh")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Stammdaten") {
                    NavigationLink {
                        TariffsListView()
                    } label: {
                        Label("Tarife", systemImage: "creditcard")
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .onAppear {
                if batteryCapacityKwh > 0 {
                    batteryCapacityText = String(format: "%.1f", batteryCapacityKwh).replacingOccurrences(of: ".", with: ",")
                }
            }
        }
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    SettingsView()
}
