import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct ChargeStationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let station: ChargeStation

    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var editType: ChargeStationType = .fastDC
    @State private var editCoordinate: CLLocationCoordinate2D? = nil
    @State private var showLocationPicker = false

    private var canSave: Bool { !editName.trimmingCharacters(in: .whitespaces).isEmpty }

    private var savedCoordinate: CLLocationCoordinate2D? {
        guard station.locationLat != 0 || station.locationLong != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: station.locationLat, longitude: station.locationLong)
    }

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
                            .foregroundStyle(station.isFavorite ? .electricBlue : Color.secondary.opacity(0.4))
                    }
                }
                .padding(.vertical, 4)
            }

            if isEditing {
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

                Section("Standort") {
                    let displayCoord = editCoordinate
                    if let coord = displayCoord {
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
                    }

                    Button {
                        showLocationPicker = true
                    } label: {
                        Label(
                            editCoordinate != nil ? "Standort ändern" : "Standort festlegen",
                            systemImage: "map"
                        )
                    }

                    if editCoordinate != nil {
                        Button(role: .destructive) {
                            editCoordinate = nil
                        } label: {
                            Label("Standort entfernen", systemImage: "trash")
                        }
                    }
                }
            } else {
                Section("Details") {
                    LabeledContent("Typ", value: station.type.label)
                    Button {
                        station.isFavorite.toggle()
                        station.updatedAt = .now
                        try? modelContext.save()
                    } label: {
                        LabeledContent("Favorit") {
                            if station.isFavorite {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.electricBlue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }

                if let coord = savedCoordinate {
                    Section("Standort") {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: coord,
                            latitudinalMeters: 800,
                            longitudinalMeters: 800
                        ))) {
                            Marker(station.name, coordinate: coord)
                        }
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

                        LabeledContent("Breitengrad", value: String(format: "%.5f°", coord.latitude))
                        LabeledContent("Längengrad", value: String(format: "%.5f°", coord.longitude))
                    }
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
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(initialCoordinate: editCoordinate) { coord in
                editCoordinate = coord
            }
        }
    }

    private func startEditing() {
        editName = station.name
        editType = station.type
        editCoordinate = savedCoordinate
        isEditing = true
    }

    private func saveChanges() {
        station.name = editName.trimmingCharacters(in: .whitespaces)
        station.type = editType
        station.locationLat = editCoordinate?.latitude ?? 0
        station.locationLong = editCoordinate?.longitude ?? 0
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
