import SwiftUI
import SwiftData

struct EditChargeTariffSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let tariff: ChargeTariff

    @State private var name: String
    @State private var pricePerKwhText: String
    @State private var basePriceText: String
    @State private var isFavorite: Bool

    init(tariff: ChargeTariff) {
        self.tariff = tariff
        _name = State(initialValue: tariff.name)
        _pricePerKwhText = State(initialValue: String(format: "%.2f", tariff.pricePerKwh).replacingOccurrences(of: ".", with: ","))
        _basePriceText = State(initialValue: String(format: "%.2f", tariff.basePrice).replacingOccurrences(of: ".", with: ","))
        _isFavorite = State(initialValue: tariff.isFavorite)
    }

    private var pricePerKwh: Double { Double(pricePerKwhText.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var basePrice: Double { Double(basePriceText.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && pricePerKwh > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("z.B. ADAC e-Charge", text: $name)
                }
                Section {
                    Toggle(isOn: $isFavorite) {
                        Label("Favorit", systemImage: "star")
                    }
                    .tint(.yellow)
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
            .navigationTitle("Tarif bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        tariff.name = name.trimmingCharacters(in: .whitespaces)
        tariff.pricePerKwh = pricePerKwh
        tariff.basePrice = basePrice
        tariff.isFavorite = isFavorite
        tariff.updatedAt = .now
        try? modelContext.save()
        dismiss()
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    EditChargeTariffSheet(tariff: ChargeTariff.sampleData[0])
}
