import SwiftUI
import SwiftData
import CoreLocation
import MapKit
import Observation

struct NewChargeStationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var onCreate: (ChargeStation) -> Void

    @State private var name: String = ""
    @State private var type: ChargeStationType = .fastDC
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    @State private var showLocationPicker = false
    @State private var locationManager = NewStationLocationManager()

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
                Section("Standort") {
                    if let coord = selectedCoordinate {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: coord,
                            latitudinalMeters: 800,
                            longitudinalMeters: 800
                        ))) {
                            Marker("", coordinate: coord)
                        }
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

                        Button {
                            showLocationPicker = true
                        } label: {
                            Label("Standort ändern", systemImage: "map")
                        }
                    } else {
                        if let currentCoord = locationManager.currentLocation {
                            Button {
                                selectedCoordinate = currentCoord
                            } label: {
                                Label("Aktuellen Standort verwenden", systemImage: "location.fill")
                            }
                        } else if locationManager.isDenied {
                            Label("Standortzugriff verweigert", systemImage: "location.slash")
                                .foregroundStyle(.secondary)
                        } else {
                            Label("Standort wird ermittelt…", systemImage: "location")
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            showLocationPicker = true
                        } label: {
                            Label("Auf der Karte suchen", systemImage: "map")
                        }
                    }
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
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(initialCoordinate: selectedCoordinate) { coord in
                    selectedCoordinate = coord
                }
            }
            .onAppear {
                locationManager.requestLocation()
            }
        }
    }

    private func saveStation() {
        let coord = selectedCoordinate
        let station = ChargeStation(
            name: name.trimmingCharacters(in: .whitespaces),
            locationLat: coord?.latitude ?? 0,
            locationLong: coord?.longitude ?? 0,
            type: type
        )
        modelContext.insert(station)
        try? modelContext.save()
        onCreate(station)
        dismiss()
    }
}

@Observable
@MainActor
private class NewStationLocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var currentLocation: CLLocationCoordinate2D?
    var isDenied: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location.coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {}

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .denied, .restricted:
                self.isDenied = true
            case .authorizedWhenInUse, .authorizedAlways:
                self.isDenied = false
                manager.requestLocation()
            default:
                break
            }
        }
    }
}

#Preview("Sample Data", traits: .modifier(SampleDataPersistencePreview())) {
    NewChargeStationSheet() { _ in }
}
