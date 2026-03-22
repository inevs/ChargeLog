import SwiftUI
import SwiftData

struct ChargeSessionDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let session: ChargeSession

    @Query(sort: \ChargeStation.name) private var stations: [ChargeStation]
    @Query(sort: \ChargeTariff.name) private var tariffs: [ChargeTariff]

    @AppStorage("batteryCapacityKwh") private var batteryCapacityKwh: Double = 0

    @State private var isEditing = false

    // Bearbeitungsfelder
    @State private var editStartTime: Date = .now
    @State private var editEndTime: Date = .now
    @State private var editOdometerText: String = ""
    @State private var editOdometerKm: Int = 0
    @State private var editEnergyText: String = ""
    @State private var editSocStart: Double = 0
    @State private var editSocEnd: Double = 0
    @State private var editStation: ChargeStation? = nil
    @State private var editTariff: ChargeTariff? = nil
    @State private var editStatus: SessionStatus = .finished
    @State private var editBilledDate: Date = .now
    @State private var editHasBilledDate: Bool = false

    private var editEnergyKwh: Double {
        Double(editEnergyText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    /// Berechnet Energie aus SoC-Delta und Batteriegröße (falls konfiguriert)
    private var calculatedEnergyKwh: Double? {
        guard batteryCapacityKwh > 0 else { return nil }
        let delta = editSocEnd - editSocStart
        guard delta > 0 else { return nil }
        return delta * batteryCapacityKwh
    }

    private var canSave: Bool {
        editStation != nil && editTariff != nil && editOdometerKm > 0 && editEndTime >= editStartTime
    }

    // Berechnete Werte für Anzeige
    private var duration: String? {
        guard let end = session.endTime else { return nil }
        let seconds = Int(end.timeIntervalSince(session.startTime))
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h) h \(m) min" }
        return "\(m) min"
    }

    var body: some View {
        List {
            // Header
            Section {
                HStack(spacing: 16) {
                    StationIcon(type: session.chargingStation.type)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.chargingStation.name)
                            .font(.title3.bold())
                        Text(session.startTime.formatted(.dateTime.day().month().year()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(status: session.sessionStatus)
                }
                .padding(.vertical, 4)
            }

            if isEditing {
                editingSections
            } else {
                detailSections
            }
        }
        .navigationTitle(isEditing ? "Bearbeiten" : "Ladevorgang")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { isEditing = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { saveChanges() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button("Bearbeiten") { startEditing() }
                }
            }
        }
    }

    // MARK: - Detail Sections

    @ViewBuilder
    private var detailSections: some View {
        Section("Zeitraum") {
            LabeledContent("Start", value: session.startTime.formatted(.dateTime.day().month().year().hour().minute()))
            if let end = session.endTime {
                LabeledContent("Ende", value: end.formatted(.dateTime.day().month().year().hour().minute()))
            }
            if let dur = duration {
                LabeledContent("Dauer", value: dur)
            }
        }

        Section("Energie & Kosten") {
            LabeledContent("Geladene Energie", value: String(format: "%.1f kWh", session.energyKwh))
            LabeledContent("Tarif", value: session.chargeTariff.name)
            LabeledContent("Preis / kWh", value: String(format: "%.2f EUR", session.chargeTariff.pricePerKwh))
            LabeledContent("Betrag", value: String(format: "%.2f EUR", session.amount))
        }

        Section("Fahrzeug") {
            LabeledContent("Kilometerstand", value: "\(session.odometerKm) km")
            LabeledContent("Start-SoC", value: "\(Int(session.socStart * 100)) %")
            if let socEnd = session.socEnd {
                LabeledContent("End-SoC", value: "\(Int(socEnd * 100)) %")
            }
        }

        Section("Status") {
            LabeledContent("Status", value: session.sessionStatus.name.capitalized)
            if let billed = session.billedDate {
                LabeledContent("Abgerechnet am", value: billed.formatted(date: .abbreviated, time: .omitted))
            }
            LabeledContent("Erstellt", value: session.createdAt.formatted(date: .abbreviated, time: .omitted))
            LabeledContent("Geändert", value: session.updatedAt.formatted(date: .abbreviated, time: .omitted))
        }
    }

    // MARK: - Editing Sections

    @ViewBuilder
    private var editingSections: some View {
        Section("Ladestation") {
            Picker("Station", selection: $editStation) {
                ForEach(stations) { station in
                    Label(station.name, systemImage: station.type.symbolName)
                        .tag(Optional(station))
                }
            }
        }

        Section("Tarif") {
            Picker("Tarif", selection: $editTariff) {
                ForEach(tariffs) { tariff in
                    Text(tariff.name).tag(Optional(tariff))
                }
            }
        }

        Section("Zeitraum") {
            DatePicker("Start", selection: $editStartTime, displayedComponents: [.date, .hourAndMinute])
            DatePicker("Ende", selection: $editEndTime, in: editStartTime..., displayedComponents: [.date, .hourAndMinute])
        }

        Section("Energie") {
            HStack {
                Text("Geladene Energie")
                Spacer()
                TextField("z.B. 48,5", text: $editEnergyText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text("kWh")
                    .foregroundStyle(.secondary)
            }
            if let calculated = calculatedEnergyKwh {
                Button {
                    editEnergyText = String(format: "%.1f", calculated).replacingOccurrences(of: ".", with: ",")
                } label: {
                    Text("Aus SoC-Delta berechnen: \(String(format: "%.1f", calculated)) kWh")
                        .font(.caption)
                }
            }
        }

        Section("Fahrzeug") {
            HStack {
                Text("Kilometerstand")
                Spacer()
                TextField("z.B. 13500", text: $editOdometerText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: editOdometerText) { _, newValue in
                        editOdometerKm = Int(newValue) ?? 0
                    }
                Text("km")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Start-SoC")
                    Spacer()
                    Text("\(Int(editSocStart * 100)) %")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $editSocStart, in: 0...1, step: 0.01)
                    .tint(Color("Electric Blue"))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("End-SoC")
                    Spacer()
                    Text("\(Int(editSocEnd * 100)) %")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $editSocEnd, in: 0...1, step: 0.01)
                    .tint(Color("Electric Blue"))
            }
        }

        Section("Status") {
            Picker("Status", selection: $editStatus) {
                ForEach([SessionStatus.finished, .paid], id: \.self) { status in
                    Text(status.name.capitalized).tag(status)
                }
            }

            Toggle("Abgerechnet", isOn: $editHasBilledDate)
            if editHasBilledDate {
                DatePicker("Datum", selection: $editBilledDate, displayedComponents: .date)
            }
        }
    }

    // MARK: - Actions

    private func startEditing() {
        editStartTime = session.startTime
        editEndTime = session.endTime ?? .now
        editOdometerKm = session.odometerKm
        editOdometerText = String(session.odometerKm)
        editEnergyText = String(format: "%.1f", session.energyKwh).replacingOccurrences(of: ".", with: ",")
        editSocStart = session.socStart
        editSocEnd = session.socEnd ?? session.socStart
        editStation = session.chargingStation
        editTariff = session.chargeTariff
        editStatus = session.sessionStatus == .running ? .finished : session.sessionStatus
        editHasBilledDate = session.billedDate != nil
        editBilledDate = session.billedDate ?? .now
        isEditing = true
    }

    private func saveChanges() {
        guard let station = editStation, let tariff = editTariff else { return }
        session.startTime = editStartTime
        session.endTime = editEndTime
        session.odometerKm = editOdometerKm
        session.energyKwh = editEnergyKwh
        session.socStart = editSocStart
        session.socEnd = editSocEnd
        session.chargingStation = station
        session.chargeTariff = tariff
        session.sessionStatus = editStatus
        session.billedDate = editHasBilledDate ? editBilledDate : nil
        session.updatedAt = .now
        try? modelContext.save()
        isEditing = false
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    NavigationStack {
        ChargeSessionDetailView(session: ChargeSession.sampleData[0])
    }
}

