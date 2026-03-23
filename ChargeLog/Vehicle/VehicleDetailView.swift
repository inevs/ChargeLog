import SwiftUI
import SwiftData

struct VehicleDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let vehicle: Vehicle

    @State private var isEditing = false
    @State private var editBrand: String = ""
    @State private var editModel: String = ""
    @State private var editBatteryCapacity: String = ""
    @State private var editOdometer: String = ""

    private var canSave: Bool {
        !editBrand.trimmingCharacters(in: .whitespaces).isEmpty &&
        !editModel.trimmingCharacters(in: .whitespaces).isEmpty &&
        parsedBattery != nil &&
        parsedOdometer != nil
    }

    private var parsedBattery: Double? {
        Double(editBatteryCapacity.replacingOccurrences(of: ",", with: "."))
            .flatMap { $0 > 0 ? $0 : nil }
    }

    private var parsedOdometer: Int? {
        Int(editOdometer)
            .flatMap { $0 >= 0 ? $0 : nil }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .font(.title)
                        .foregroundStyle(.tint)
                        .frame(width: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        if isEditing {
                            TextField("Marke", text: $editBrand)
                                .font(.title3.bold())
                            TextField("Modell", text: $editModel)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(vehicle.brand)
                                .font(.title3.bold())
                            Text(vehicle.model)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if isEditing {
                Section("Akku") {
                    HStack {
                        TextField("z.B. 82", text: $editBatteryCapacity)
                            .keyboardType(.decimalPad)
                        Text("kWh")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Kilometerstand") {
                    HStack {
                        TextField("z.B. 34500", text: $editOdometer)
                            .keyboardType(.numberPad)
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Section("Details") {
                    LabeledContent("Akkukapazität", value: String(format: "%.1f kWh", vehicle.batteryCapacityKwh))
                    LabeledContent("Kilometerstand", value: "\(vehicle.odometerKm.formatted()) km")
                }
            }
        }
        .navigationTitle(isEditing ? "Bearbeiten" : vehicle.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        isEditing = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button("Bearbeiten") {
                        startEditing()
                    }
                }
            }
        }
    }

    private func startEditing() {
        editBrand = vehicle.brand
        editModel = vehicle.model
        editBatteryCapacity = String(format: "%.1f", vehicle.batteryCapacityKwh)
            .replacingOccurrences(of: ".", with: ",")
        editOdometer = "\(vehicle.odometerKm)"
        isEditing = true
    }

    private func saveChanges() {
        guard let battery = parsedBattery, let odometer = parsedOdometer else { return }
        vehicle.brand = editBrand.trimmingCharacters(in: .whitespaces)
        vehicle.model = editModel.trimmingCharacters(in: .whitespaces)
        vehicle.batteryCapacityKwh = battery
        vehicle.odometerKm = odometer
        try? modelContext.save()
        isEditing = false
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    NavigationStack {
        VehicleDetailView(vehicle: Vehicle.sampleData[0])
    }
}
