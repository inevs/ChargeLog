import SwiftUI
import MapKit
import CoreLocation
import Observation

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    var onSelect: (CLLocationCoordinate2D) -> Void
    var initialCoordinate: CLLocationCoordinate2D?

    @State private var cameraPosition: MapCameraPosition
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var locationManager = PickerLocationManager()

    init(initialCoordinate: CLLocationCoordinate2D? = nil, onSelect: @escaping (CLLocationCoordinate2D) -> Void) {
        self.onSelect = onSelect
        self.initialCoordinate = initialCoordinate

        let startCoord = initialCoordinate ?? CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515)
        _selectedCoordinate = State(initialValue: startCoord)
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: startCoord,
            latitudinalMeters: initialCoordinate != nil ? 1000 : 500_000,
            longitudinalMeters: initialCoordinate != nil ? 1000 : 500_000
        )))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition)
                    .onMapCameraChange { context in
                        selectedCoordinate = context.camera.centerCoordinate
                    }
                    .ignoresSafeArea(edges: .bottom)

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.red, .white)
                    .shadow(radius: 4)
                    .offset(y: -18)
            }
            .navigationTitle("Standort wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") {
                        onSelect(selectedCoordinate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        moveToCurrentLocation()
                    } label: {
                        Label("Aktueller Standort", systemImage: "location.fill")
                    }
                    .disabled(locationManager.isDenied)
                }
            }
            .onAppear {
                locationManager.onFirstLocation = { [initialCoordinate] coord in
                    guard initialCoordinate == nil else { return }
                    withAnimation {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: coord,
                            latitudinalMeters: 1000,
                            longitudinalMeters: 1000
                        ))
                    }
                }
                locationManager.requestLocation()
            }
        }
    }

    private func moveToCurrentLocation() {
        if let coord = locationManager.currentLocation {
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: coord,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                ))
            }
        } else {
            locationManager.requestLocation()
        }
    }
}

@Observable
@MainActor
private class PickerLocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var currentLocation: CLLocationCoordinate2D?
    var isDenied: Bool = false
    var onFirstLocation: ((CLLocationCoordinate2D) -> Void)?
    private var hasDeliveredFirst = false

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
            if !self.hasDeliveredFirst {
                self.hasDeliveredFirst = true
                self.onFirstLocation?(location.coordinate)
            }
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

#Preview {
    LocationPickerView { coordinate in
        print("Selected: \(coordinate.latitude), \(coordinate.longitude)")
    }
}
