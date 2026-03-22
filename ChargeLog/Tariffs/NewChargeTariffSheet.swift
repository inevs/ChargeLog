import SwiftUI
import SwiftData

struct NewChargeTariffSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var onCreate: (ChargeTariff) -> Void

    @State private var name: String = ""
    @State private var pricePerKwhText: String = ""
    @State private var basePriceText: String = ""

    private var pricePerKwh: Double { Double(pricePerKwhText.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var basePrice: Double { Double(basePriceText.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && pricePerKwh > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("z.B. ADAC e-Charge", text: $name)
                }
                Section("Preise") {
                    HStack {
                        Text("Preis pro kWh")
                        Spacer()
                        TextField("0,00", text: $pricePerKwhText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("€")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Grundpreis")
                        Spacer()
                        TextField("0,00", text: $basePriceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("€")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Neuer Tarif")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        saveTariff()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveTariff() {
        let tariff = ChargeTariff(
            name: name.trimmingCharacters(in: .whitespaces),
            pricePerKwh: pricePerKwh,
            basePrice: basePrice
        )
        modelContext.insert(tariff)
        try? modelContext.save()
        onCreate(tariff)
        dismiss()
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    NewChargeTariffSheet() { _ in }
}
