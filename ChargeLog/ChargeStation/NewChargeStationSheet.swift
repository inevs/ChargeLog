import SwiftUI
import SwiftData

struct NewChargeStationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var onCreate: (ChargeStation) -> Void

    @State private var name: String = ""
    @State private var type: ChargeStationType = .fastDC

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("z.B. IONITY A8 Nord", text: $name)
                }
                Section("Typ") {
                    Picker("Ladetyp", selection: $type) {
                        ForEach(ChargeStationType.allCases, id: \.self) { t in
//                            Label(t.label, systemImage: t.symbolName).tag(t)
                            HStack {
                                StationIcon(type: t)
                                    .padding(.trailing)
                                Text(t.label)
                            }
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Neue Ladestation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        saveStation()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveStation() {
        let station = ChargeStation(
            name: name.trimmingCharacters(in: .whitespaces),
            locationLat: 0,
            locationLong: 0,
            type: type
        )
        modelContext.insert(station)
        try? modelContext.save()
        onCreate(station)
        dismiss()
    }
}

#Preview("Sample Data", traits: .modifier(SampleDataPersistencePreview())) {
    NewChargeStationSheet() { _ in }
}
