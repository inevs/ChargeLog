import SwiftUI
import SwiftData

struct NewVehicleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var brand: String = ""
    @State private var model: String = ""
    @State private var batteryCapacity: String = ""
    @State private var odometer: String = ""

    private var canSave: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty &&
        parsedBattery != nil &&
        parsedOdometer != nil
    }

    private var parsedBattery: Double? {
        Double(batteryCapacity.replacingOccurrences(of: ",", with: "."))
            .flatMap { $0 > 0 ? $0 : nil }
    }

    private var parsedOdometer: Int? {
        Int(odometer)
            .flatMap { $0 >= 0 ? $0 : nil }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Marke") {
                    TextField("z.B. Tesla", text: $brand)
                }
                Section("Modell") {
                    TextField("z.B. Model 3 Long Range", text: $model)
                }
                Section("Akkukapazität") {
                    HStack {
                        TextField("z.B. 82", text: $batteryCapacity)
                            .keyboardType(.decimalPad)
                        Text("kWh")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Kilometerstand") {
                    HStack {
                        TextField("z.B. 0", text: $odometer)
                            .keyboardType(.numberPad)
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Neues Fahrzeug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        saveVehicle()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveVehicle() {
        guard let battery = parsedBattery, let odometer = parsedOdometer else { return }
        let vehicle = Vehicle(
            brand: brand.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            odometerKm: odometer,
            batteryCapacityKwh: battery
        )
        modelContext.insert(vehicle)
        try? modelContext.save()
        dismiss()
    }
}

#Preview(traits: .modifier(EmptyPersistencePreview())) {
    NewVehicleSheet()
}
