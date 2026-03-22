import SwiftUI
import SwiftData

struct ChargeStationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let station: ChargeStation

    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var editType: ChargeStationType = .fastDC
    @State private var editIsFavorite: Bool = false

    private var canSave: Bool { !editName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        List {
            // Header
            Section {
                HStack(spacing: 16) {
                    StationIcon(type: isEditing ? editType : station.type)
                    VStack(alignment: .leading, spacing: 2) {
                        if isEditing {
                            TextField("Name", text: $editName)
                                .font(.title3.bold())
                        } else {
                            Text(station.name)
                                .font(.title3.bold())
                        }
                        Text((isEditing ? editType : station.type).label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !isEditing {
                        Image(systemName: station.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(station.isFavorite ? Color.yellow : Color.secondary.opacity(0.4))
                    }
                }
                .padding(.vertical, 4)
            }

            if isEditing {
                Section {
                    Toggle(isOn: $editIsFavorite) {
                        Label("Favorit", systemImage: "star")
                    }
                    .tint(.yellow)
                }

                Section("Typ") {
                    Picker("Ladetyp", selection: $editType) {
                        ForEach(ChargeStationType.allCases, id: \.self) { t in
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
            } else {
                Section("Details") {
                    LabeledContent("Typ", value: station.type.label)
                    LabeledContent("Favorit", value: station.isFavorite ? "Ja" : "Nein")
                    LabeledContent("Hinzugefügt", value: station.createdAt.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("Zuletzt geändert", value: station.updatedAt.formatted(date: .abbreviated, time: .omitted))
                }

                Section("Ladesessions") {
                    if station.chargeSessions.isEmpty {
                        Text("Noch keine Sessions an dieser Station.")
                            .foregroundStyle(.secondary)
                    } else {
                        LabeledContent("Anzahl", value: "\(station.chargeSessions.count)")
                        let totalKwh = station.chargeSessions.reduce(0) { $0 + $1.energyKwh }
                        LabeledContent("Geladene Energie", value: String(format: "%.1f kWh", totalKwh))
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Bearbeiten" : station.name)
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
        editName = station.name
        editType = station.type
        editIsFavorite = station.isFavorite
        isEditing = true
    }

    private func saveChanges() {
        station.name = editName.trimmingCharacters(in: .whitespaces)
        station.type = editType
        station.isFavorite = editIsFavorite
        station.updatedAt = .now
        try? modelContext.save()
        isEditing = false
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    NavigationStack {
        ChargeStationDetailView(station: ChargeStation.sampleData[0])
    }
}
