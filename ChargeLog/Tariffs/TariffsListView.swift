import SwiftUI
import SwiftData

struct TariffsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChargeTariff.name) private var tariffs: [ChargeTariff]

    @State private var showNewTariffSheet = false
    @State private var editingTariff: ChargeTariff? = nil
    @State private var showFavoritesOnly = false

    private var favorites: [ChargeTariff] { tariffs.filter { $0.isFavorite } }
    private var others: [ChargeTariff] { tariffs.filter { !$0.isFavorite } }
    private var visibleTariffs: [ChargeTariff] { showFavoritesOnly ? favorites : tariffs }

    var body: some View {
        List {
            if showFavoritesOnly {
                ForEach(favorites) { tariff in
                    tariffRow(tariff)
                }
                .onDelete { offsets in
                    deleteTariffs(from: favorites, at: offsets)
                }
            } else {
                if !favorites.isEmpty {
                    Section("Favoriten") {
                        ForEach(favorites) { tariff in
                            tariffRow(tariff)
                        }
                        .onDelete { offsets in
                            deleteTariffs(from: favorites, at: offsets)
                        }
                    }
                }
                if !others.isEmpty {
                    Section(favorites.isEmpty ? "" : "Weitere") {
                        ForEach(others) { tariff in
                            tariffRow(tariff)
                        }
                        .onDelete { offsets in
                            deleteTariffs(from: others, at: offsets)
                        }
                    }
                }
            }
        }
        .navigationTitle("Tarife")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewTariffSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFavoritesOnly.toggle()
                } label: {
                    Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                }
                .tint(showFavoritesOnly ? .yellow : .accentColor)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showNewTariffSheet) {
            NewChargeTariffSheet { _ in }
        }
        .sheet(item: $editingTariff) { tariff in
            EditChargeTariffSheet(tariff: tariff)
        }
        .overlay {
            if visibleTariffs.isEmpty {
                ContentUnavailableView(
                    showFavoritesOnly ? "Keine Favoriten" : "Keine Tarife",
                    systemImage: showFavoritesOnly ? "star" : "creditcard",
                    description: Text(showFavoritesOnly ? "Markiere Tarife als Favorit." : "Füge deinen ersten Ladetarif hinzu.")
                )
            }
        }
    }

    @ViewBuilder
    private func tariffRow(_ tariff: ChargeTariff) -> some View {
        Button {
            editingTariff = tariff
        } label: {
            TariffRow(tariff: tariff)
        }
        .tint(.primary)
        .swipeActions(edge: .leading) {
            Button {
                toggleFavorite(tariff)
            } label: {
                Label(
                    tariff.isFavorite ? "Kein Favorit" : "Favorit",
                    systemImage: tariff.isFavorite ? "star.slash" : "star"
                )
            }
            .tint(.yellow)
        }
    }

    private func toggleFavorite(_ tariff: ChargeTariff) {
        tariff.isFavorite.toggle()
        tariff.updatedAt = .now
        try? modelContext.save()
    }

    private func deleteTariffs(from list: [ChargeTariff], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(list[index])
        }
        try? modelContext.save()
    }
}

private struct TariffRow: View {
    let tariff: ChargeTariff

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if tariff.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    Text(tariff.name)
                        .font(.body)
                }
                HStack(spacing: 8) {
                    Label(
                        String(format: "%.2f €/kWh", tariff.pricePerKwh),
                        systemImage: "bolt"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    if tariff.basePrice > 0 {
                        Label(
                            String(format: "%.2f € Grundpreis", tariff.basePrice),
                            systemImage: "eurosign"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview(traits: .modifier(SampleDataPersistencePreview())) {
    NavigationStack {
        TariffsListView()
    }
}
