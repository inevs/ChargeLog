import SwiftUI

struct EndChargeSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("batteryCapacityKwh") private var batteryCapacityKwh: Double = 0

    let session: ChargeSession

    // Felder aus dem Start – korrigierbar
    @State private var startTime: Date
    @State private var odometerKm: Int
    @State private var odometerText: String
    @State private var socStart: Double

    // Neue Felder beim Beenden
    @State private var endTime: Date = .now
    @State private var energyKwhText: String
    @State private var socEnd: Double

    init(session: ChargeSession) {
        self.session = session
        _startTime = State(initialValue: session.startTime)
        _odometerKm = State(initialValue: session.odometerKm)
        _odometerText = State(initialValue: String(session.odometerKm))
        _socStart = State(initialValue: session.socStart)
        _endTime = State(initialValue: Date())
        _energyKwhText = State(initialValue: "")
        _socEnd = State(initialValue: min(session.socStart + 0.5, 1.0))
    }

    private var energyKwh: Double {
        Double(energyKwhText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    /// Berechnet Energie aus SoC-Delta und Batteriegröße (falls konfiguriert)
    private var calculatedEnergyKwh: Double? {
        guard batteryCapacityKwh > 0 else { return nil }
        let delta = socEnd - socStart
        guard delta > 0 else { return nil }
        return delta * batteryCapacityKwh
    }

    private var canFinish: Bool {
        odometerKm > 0 && endTime >= startTime
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Beginn") {
                    DatePicker("Startzeit", selection: $startTime, displayedComponents: [.date, .hourAndMinute])

                    HStack {
                        Text("Kilometerstand")
                        Spacer()
                        TextField("z.B. 13500", text: $odometerText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: odometerText) { _, newValue in
                                odometerKm = Int(newValue) ?? 0
                            }
                        Text("km")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Start-SoC")
                            Spacer()
                            Text("\(Int(socStart * 100)) %")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $socStart, in: 0...1, step: 0.01)
                            .tint(Color("Electric Blue"))
                            .onChange(of: socStart) { _, _ in
                                updateCalculatedEnergy()
                            }
                    }
                }

                Section("Ende") {
                    DatePicker("Endzeit", selection: $endTime, in: startTime..., displayedComponents: [.date, .hourAndMinute])

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("End-SoC")
                            Spacer()
                            Text("\(Int(socEnd * 100)) %")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $socEnd, in: 0...1, step: 0.01)
                            .tint(Color("Electric Blue"))
                            .onChange(of: socEnd) { _, _ in
                                updateCalculatedEnergy()
                            }
                    }

                    HStack {
                        Text("Geladene Energie")
                        Spacer()
                        TextField("z.B. 48,5", text: $energyKwhText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kWh")
                            .foregroundStyle(.secondary)
                    }
                    if let calculated = calculatedEnergyKwh {
                        Text("Berechnet aus SoC-Delta: \(String(format: "%.1f", calculated)) kWh")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Ladevorgang beenden")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                updateCalculatedEnergy()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Beenden") {
                        finishSession()
                    }
                    .disabled(!canFinish)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    /// Füllt das Energie-Textfeld mit dem aus SoC-Delta berechneten Wert vor,
    /// sofern der Nutzer noch keinen eigenen Wert eingetragen hat.
    private func updateCalculatedEnergy() {
        guard let calculated = calculatedEnergyKwh else { return }
        energyKwhText = String(format: "%.1f", calculated).replacingOccurrences(of: ".", with: ",")
    }

    private func finishSession() {
        session.startTime = startTime
        session.odometerKm = odometerKm
        session.socStart = socStart
        session.endTime = endTime
        session.energyKwh = energyKwh
        session.socEnd = socEnd
        session.sessionStatus = .finished
        session.updatedAt = .now
        dismiss()
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    EndChargeSessionSheet(session: ChargeSession.sampleData.last!)
}
