import SwiftUI
import SwiftData

struct ChargingSessionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddSessionSheet = false

    @Query(sort: \ChargeSession.startTime, order: .reverse)
    private var chargeSessions: [ChargeSession]

    private var hasRunningSession: Bool {
        chargeSessions.contains { $0.sessionStatus == .running }
    }

    var body: some View {
        NavigationStack {
            Group {
                if chargeSessions.isEmpty {
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
                ForEach(chargeSessions) { session in
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
    private var emptyState: some View {
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

struct ChargeSessionRow: View {
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
                    Text(session.startTime.formatted(.dateTime.day().month(.twoDigits).year(.twoDigits).hour().minute()))
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
                    Button("", systemImage: "stop.circle") {
                        showEndSheet = true
                    }
                    .controlSize(.large)
                    .tint(Color("Electric Blue"))
                    .fixedSize()
                case .finished:
                    Button("", systemImage: "eurosign.circle.fill") {
                        session.sessionStatus = .paid
                    }
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
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
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
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
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
            .fontWeight(.semibold)
            .frame(width: 64)
            .padding(.vertical, 5)
        .foregroundStyle(status.foregroundStyle)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(status.backgroundFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(status.backgroundOverlay, lineWidth: 1)
        )
    }
}


#Preview("Empty State", traits: .modifier(EmptyPersistencePreview())) {
    ChargingSessionsListView()
}

#Preview("Sample Data", traits: .modifier(SampleDataPersistencePreview())) {
    ChargingSessionsListView()
}
