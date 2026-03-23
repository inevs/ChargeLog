import SwiftUI
import SwiftData

struct VehicleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vehicle.brand) private var vehicles: [Vehicle]

    @State private var showNewVehicleSheet = false

    var body: some View {
        List {
            ForEach(vehicles) { vehicle in
                NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                    VehicleRow(vehicle: vehicle)
                }
            }
            .onDelete(perform: deleteVehicles)
        }
        .navigationTitle("Fahrzeuge")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewVehicleSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewVehicleSheet) {
            NewVehicleSheet()
        }
        .overlay {
            if vehicles.isEmpty {
                ContentUnavailableView(
                    "Keine Fahrzeuge",
                    systemImage: "car",
                    description: Text("Füge dein erstes Fahrzeug hinzu.")
                )
            }
        }
    }

    private func deleteVehicles(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(vehicles[index])
        }
        try? modelContext.save()
    }
}

private struct VehicleRow: View {
    let vehicle: Vehicle

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(vehicle.displayName)
                    .font(.body)
                HStack(spacing: 4) {
                    Text(String(format: "%.0f kWh", vehicle.batteryCapacityKwh))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(vehicle.odometerKm.formatted()) km")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("Empty State", traits: .modifier(EmptyPersistencePreview())) {
    NavigationStack {
        VehicleListView()
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    NavigationStack {
        VehicleListView()
    }
}
