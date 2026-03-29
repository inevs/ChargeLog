import SwiftUI
import SwiftData

struct ChargeStationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChargeStation.name) private var stations: [ChargeStation]

    @State private var showNewStationSheet = false
    @State private var showFavoritesOnly = false

    private var favorites: [ChargeStation] { stations.filter { $0.isFavorite } }
    private var others: [ChargeStation] { stations.filter { !$0.isFavorite } }
    private var visibleStations: [ChargeStation] { showFavoritesOnly ? favorites : stations }

    var body: some View {
        List {
            if showFavoritesOnly {
                ForEach(favorites) { station in
                    stationRow(station)
                }
                .onDelete { offsets in
                    deleteStations(from: favorites, at: offsets)
                }
            } else {
                if !favorites.isEmpty {
                    Section("Favoriten") {
                        ForEach(favorites) { station in
                            stationRow(station)
                        }
                        .onDelete { offsets in
                            deleteStations(from: favorites, at: offsets)
                        }
                    }
                }
                if !others.isEmpty {
                    Section(favorites.isEmpty ? "" : "Weitere") {
                        ForEach(others) { station in
                            stationRow(station)
                        }
                        .onDelete { offsets in
                            deleteStations(from: others, at: offsets)
                        }
                    }
                }
            }
        }
        .navigationTitle("Ladestationen")
        .navigationDestination(for: ChargeStation.self) { station in
            ChargeStationDetailView(station: station)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFavoritesOnly.toggle()
                } label: {
                    Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                }
                .tint(showFavoritesOnly ? .yellow : .accentColor)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewStationSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewStationSheet) {
            NewChargeStationSheet { _ in }
        }
        .overlay {
            if visibleStations.isEmpty {
                ContentUnavailableView(
                    showFavoritesOnly ? "Keine Favoriten" : "Keine Ladestationen",
                    systemImage: showFavoritesOnly ? "star" : "ev.charger",
                    description: Text(showFavoritesOnly ? "Markiere Stationen als Favorit." : "Füge deine erste Ladestation hinzu.")
                )
            }
        }
    }

    @ViewBuilder
    private func stationRow(_ station: ChargeStation) -> some View {
        NavigationLink(value: station) {
            StationRow(station: station)
        }
        .swipeActions(edge: .leading) {
            Button {
                toggleFavorite(station)
            } label: {
                Label(
                    station.isFavorite ? "Kein Favorit" : "Favorit",
                    systemImage: station.isFavorite ? "star.slash" : "star"
                )
            }
            .tint(.yellow)
        }
    }

    private func toggleFavorite(_ station: ChargeStation) {
        station.isFavorite.toggle()
        station.updatedAt = .now
        try? modelContext.save()
    }

    private func deleteStations(from list: [ChargeStation], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(list[index])
        }
        try? modelContext.save()
    }
}

private struct StationRow: View {
    let station: ChargeStation

    var body: some View {
        HStack(spacing: 12) {
            StationIcon(type: station.type)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if station.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    Text(station.name)
                        .font(.body)
                }
                HStack(spacing: 4) {
                    Text(station.type.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !station.chargeSessions.isEmpty {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(station.chargeSessions.count) Session\(station.chargeSessions.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview("Empty State", traits: .modifier(EmptyPersistencePreview())) {
    NavigationStack {
        ChargeStationListView()
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    NavigationStack {
        ChargeStationListView()
    }
}
