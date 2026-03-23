import SwiftUI
import SwiftData

struct NewChargeSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ChargeStation.name) private var stations: [ChargeStation]
    @Query(sort: \ChargeTariff.name) private var tariffs: [ChargeTariff]
    @Query(sort: \Vehicle.createdAt, order: .reverse) private var vehicles: [Vehicle]

    @AppStorage("stationPickerFavoritesOnly") private var stationFavoritesOnly: Bool = false
    @AppStorage("tariffPickerFavoritesOnly") private var tariffFavoritesOnly: Bool = false

    @State private var selectedStation: ChargeStation?
    @State private var selectedTariff: ChargeTariff?
    @State private var selectedVehicle: Vehicle?

    private var visibleStations: [ChargeStation] {
        stationFavoritesOnly ? stations.filter { $0.isFavorite } : stations
    }
    private var visibleTariffs: [ChargeTariff] {
        tariffFavoritesOnly ? tariffs.filter { $0.isFavorite } : tariffs
    }
    @State private var socStart: Double = 0.2
    @State private var odometerKm: Int = 0
    @State private var odometerText: String = ""

    @State private var showNewStationSheet = false
    @State private var showNewTariffSheet = false

    private var canStart: Bool {
        selectedStation != nil && selectedTariff != nil && selectedVehicle != nil && odometerKm > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Fahrzeug") {
                    if vehicles.isEmpty {
                        NavigationLink {
                            VehicleListView()
                        } label: {
                            Label("Kein Fahrzeug vorhanden – jetzt anlegen", systemImage: "car")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Picker("Fahrzeug", selection: $selectedVehicle) {
                            ForEach(vehicles) { vehicle in
                                Text(vehicle.displayName).tag(Optional(vehicle))
                            }
                        }
                    }
                }

                Section {
                    if visibleStations.isEmpty {
                        Text(stationFavoritesOnly ? "Keine Favoriten vorhanden" : "Keine Ladestationen vorhanden")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Station", selection: $selectedStation) {
                            Text("Bitte wählen").tag(Optional<ChargeStation>(nil))
                            ForEach(visibleStations) { station in
                                Label(station.name, systemImage: station.type.symbolName)
                                    .tag(Optional(station))
                            }
                        }
                    }
                    Button {
                        showNewStationSheet = true
                    } label: {
                        Label("Neue Ladestation", systemImage: "plus.circle")
                            .foregroundStyle(Color("Electric Blue"))
                    }
                } header: {
                    HStack {
                        Text("Ladestation")
                        Spacer()
                        Button {
                            stationFavoritesOnly.toggle()
                            if let selected = selectedStation, !visibleStations.contains(where: { $0.id == selected.id }) {
                                selectedStation = visibleStations.first
                            }
                        } label: {
                            Label(
                                stationFavoritesOnly ? "Nur Favoriten" : "Alle",
                                systemImage: stationFavoritesOnly ? "star.fill" : "star"
                            )
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(stationFavoritesOnly ? .electricBlue : .secondary)
                        }
                    }
                }

                Section {
                    if visibleTariffs.isEmpty {
                        Text(tariffFavoritesOnly ? "Keine Favoriten vorhanden" : "Keine Tarife vorhanden")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Tarif", selection: $selectedTariff) {
                            Text("Bitte wählen").tag(Optional<ChargeTariff>(nil))
                            ForEach(visibleTariffs) { tariff in
                                Text(tariff.name)
                                    .tag(Optional(tariff))
                            }
                        }
                    }
                    Button {
                        showNewTariffSheet = true
                    } label: {
                        Label("Neuer Tarif", systemImage: "plus.circle")
                            .foregroundStyle(Color("Electric Blue"))
                    }
                } header: {
                    HStack {
                        Text("Tarif")
                        Spacer()
                        Button {
                            tariffFavoritesOnly.toggle()
                            if let selected = selectedTariff, !visibleTariffs.contains(where: { $0.id == selected.id }) {
                                selectedTariff = visibleTariffs.first
                            }
                        } label: {
                            Label(
                                tariffFavoritesOnly ? "Nur Favoriten" : "Alle",
                                systemImage: tariffFavoritesOnly ? "star.fill" : "star"
                            )
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(tariffFavoritesOnly ? .electricBlue : .secondary)
                        }
                    }
                }

                Section("Fahrzeugdaten") {
                    HStack {
                        Text("Kilometerstand")
                        Spacer()
                        TextField("", text: $odometerText)
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
                    }
                }
            }
            .navigationTitle("Ladevorgang starten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Starten") {
                        startSession()
                    }
                    .disabled(!canStart)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if selectedVehicle == nil { selectedVehicle = vehicles.first }
                if selectedStation == nil { selectedStation = visibleStations.first }
                if selectedTariff == nil { selectedTariff = visibleTariffs.first }
            }
            .sheet(isPresented: $showNewStationSheet) {
                NewChargeStationSheet { newStation in
                    selectedStation = newStation
                }
            }
            .sheet(isPresented: $showNewTariffSheet) {
                NewChargeTariffSheet { newTariff in
                    selectedTariff = newTariff
                }
            }
        }
    }

    private func startSession() {
        guard let station = selectedStation, let tariff = selectedTariff, let vehicle = selectedVehicle, odometerKm > 0 else { return }

        let session = ChargeSession(
            odometerKm: odometerKm,
            socStart: socStart,
            chargingStation: station,
            chargeTariff: tariff,
            vehicle: vehicle
        )
        modelContext.insert(session)
        try? modelContext.save()
        dismiss()
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    NewChargeSessionSheet()
}
