import SwiftUI
import SwiftData

struct ChargeSessionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddSessionSheet = false
    @State private var selectedVehicle: Vehicle? = nil

    @Query(sort: \ChargeSession.startTime, order: .reverse)
    private var chargeSessions: [ChargeSession]

    @Query(sort: \Vehicle.brand)
    private var vehicles: [Vehicle]

    private var filteredSessions: [ChargeSession] {
        guard let vehicle = selectedVehicle else { return chargeSessions }
        return chargeSessions.filter { $0.vehicle?.id == vehicle.id }
    }

    private var hasRunningSession: Bool {
        chargeSessions.contains { $0.sessionStatus == .running }
    }

    private var unpaidAmount: Double {
        filteredSessions
            .filter { $0.sessionStatus == .finished }
            .reduce(0) { $0 + $1.amount }
    }

    private var unpaidCount: Int {
        filteredSessions.filter { $0.sessionStatus == .finished }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredSessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("Ladevorgänge")
            .navigationDestination(for: ChargeSession.self) { session in
                ChargeSessionDetailView(session: session)
            }
            .toolbar {
                if vehicles.count > 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button {
                                selectedVehicle = nil
                            } label: {
                                Label("Alle Fahrzeuge", systemImage: selectedVehicle == nil ? "checkmark" : "car.2")
                            }
                            Divider()
                            ForEach(vehicles) { vehicle in
                                Button {
                                    selectedVehicle = vehicle
                                } label: {
                                    Label(vehicle.displayName, systemImage: selectedVehicle?.id == vehicle.id ? "checkmark" : "car")
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "car")
                                if let vehicle = selectedVehicle {
                                    Text(vehicle.displayName)
                                        .font(.subheadline)
                                }
                            }
                            .foregroundStyle(selectedVehicle != nil ? Color.accentColor : Color.primary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: CSVExporter.csv(from: chargeSessions),
                        preview: SharePreview("Ladevorgänge exportieren", image: Image(systemName: "square.and.arrow.up"))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(chargeSessions.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSessionSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(hasRunningSession)
                }
            }
            .sheet(isPresented: $showAddSessionSheet) {
                NewChargeSessionSheet()
            }
        }
    }

    @ViewBuilder
    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if unpaidCount > 0 {
                    unpaidBanner
                }
                ForEach(filteredSessions) { session in
                    NavigationLink(value: session) {
                        ChargeSessionRow(session: session)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color("background"))
    }

    @ViewBuilder
    private var unpaidBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "eurosign.circle.fill")
                .font(.title2)
                .foregroundStyle(Color("Growth Green"))
            VStack(alignment: .leading, spacing: 2) {
                Text("Offen zur Abrechnung")
                    .font(.subheadline.weight(.semibold))
                Text(unpaidCount == 1 ? "1 Ladevorgang" : "\(unpaidCount) Ladevorgänge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(unpaidAmount.formatted(.currency(code: "EUR")))
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(Color("Growth Green"))
        }
        .padding(14)
        .background(Color("Growth Green").opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("Growth Green").opacity(0.25), lineWidth: 1))
    }

    @ViewBuilder
    private var emptyState: some View {
        if let vehicle = selectedVehicle {
            ContentUnavailableView {
                Label("Keine Ladevorgänge", systemImage: "bolt.car")
            } description: {
                Text("Keine Ladevorgänge für \(vehicle.displayName)")
            } actions: {
                Button("Filter entfernen") {
                    selectedVehicle = nil
                }
                .buttonStyle(.bordered)
            }
        } else {
            ContentUnavailableView {
                Label("Keine Ladevorgänge", systemImage: "bolt.car")
            } description: {
                Text("Füge deinen ersten Ladevorgang hinzu")
            } actions: {
                Button {
                    showAddSessionSheet = true
                } label: {
                    Label("Ladevorgang hinzufügen", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("Electric Blue"))
            }
        }
    }
}

struct ChargeSessionRow: View {
    @Environment(\.modelContext) private var modelContext
    let session: ChargeSession
    @State private var showEndSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                StationIcon(type: session.chargingStation.type)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.chargingStation.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(session.startTime.formatted(.dateTime.day().month(.twoDigits).year(.twoDigits).hour().minute()))
                        if let vehicle = session.vehicle {
                            Text("·")
                            Text(vehicle.displayName)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                StatusBadge(status: session.sessionStatus)
            }

            Divider()

            HStack(alignment: .top, spacing: 24) {
                MetricColumn(
                    label: "ENERGIE",
                    value: String(format: "%.1f", session.energyKwh),
                    unit: "kWh"
                )
                MetricColumn(
                    label: "BETRAG",
                    value: String(format: "%.2f", session.amount),
                    unit: "EUR"
                )

                Spacer()

                switch session.sessionStatus {
                case .running:
                    Button("Ladevorgang beenden", systemImage: "stop.circle") {
                        showEndSheet = true
                    }
                    .labelStyle(.iconOnly)
                    .controlSize(.large)
                    .tint(Color("Electric Blue"))
                    .fixedSize()
                case .finished:
                    Button("Als bezahlt markieren", systemImage: "eurosign.circle.fill") {
                        session.sessionStatus = .paid
                        session.billedDate = .now
                        session.updatedAt = .now
                        try? modelContext.save()
                    }
                    .labelStyle(.iconOnly)
                    .controlSize(.large)
                    .tint(Color("Growth Green"))
                    .fixedSize()
                case .paid:
                    EmptyView()
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.footnote)
            }
        }
        .padding(16)
        .background(Color("background"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color(.label).opacity(0.06), radius: 6, x: 0, y: 2)
        .containerRelativeFrame(.horizontal) { width, _ in width - 32 }
        .sheet(isPresented: $showEndSheet) {
            EndChargeSessionSheet(session: session)
        }
    }
}

private struct MetricColumn: View {
    let label: String
    let value: String
    let unit: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.primary)
                if let unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .fixedSize()
        }
    }
}

struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        Text(status.name.uppercased())
            .font(.caption)
            .bold()
            .frame(width: 64)
            .padding(5)
        .foregroundStyle(status.foregroundStyle)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(status.backgroundFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(status.backgroundOverlay, lineWidth: 1)
        )
    }
}


#Preview("Empty State", traits: .modifier(EmptyPersistencePreview())) {
    ChargeSessionsListView()
}

#Preview("Sample Data", traits: .modifier(SampleDataPersistencePreview())) {
    ChargeSessionsListView()
}
