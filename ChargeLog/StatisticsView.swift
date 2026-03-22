import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \ChargeSession.startTime, order: .reverse) private var allSessions: [ChargeSession]

    @State private var selectedMonth: Date = Self.currentMonthStart()

    private static func currentMonthStart() -> Date {
        Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    }

    private var availableMonths: [Date] {
        var months: [Date] = []
        let calendar = Calendar.current
        for session in allSessions {
            if let start = calendar.dateInterval(of: .month, for: session.startTime)?.start, !months.contains(start) {
                months.append(start)
            }
        }
        return months.sorted(by: >)
    }

    private var filteredSessions: [ChargeSession] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: selectedMonth) else { return [] }
        return allSessions.filter { session in
            session.startTime >= interval.start && session.startTime < interval.end
        }
    }

    private var finishedSessions: [ChargeSession] {
        filteredSessions.filter { $0.sessionStatus != .running }
    }

    private var totalEnergy: Double {
        finishedSessions.reduce(0) { $0 + $1.energyKwh }
    }

    private var totalCost: Double {
        finishedSessions.reduce(0) { $0 + $1.amount }
    }

    private var averageEnergy: Double {
        guard !finishedSessions.isEmpty else { return 0 }
        return totalEnergy / Double(finishedSessions.count)
    }

    private var averageCostPerKwh: Double {
        guard totalEnergy > 0 else { return 0 }
        return totalCost / totalEnergy
    }

    private var dailyEnergyData: [(day: Date, energy: Double)] {
        let calendar = Calendar.current
        var dict: [Date: Double] = [:]
        for session in finishedSessions {
            let day = calendar.startOfDay(for: session.startTime)
            dict[day, default: 0] += session.energyKwh
        }
        return dict.map { (day: $0.key, energy: $0.value) }.sorted { $0.day < $1.day }
    }

    private var stationUsage: [(name: String, count: Int)] {
        var dict: [String: Int] = [:]
        for session in finishedSessions {
            dict[session.chargingStation.name, default: 0] += 1
        }
        return dict.map { (name: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !availableMonths.isEmpty {
                        MonthPickerView(
                            selectedMonth: $selectedMonth,
                            availableMonths: availableMonths
                        )
                        .padding(.horizontal)
                    }

                    if finishedSessions.isEmpty {
                        EmptyStatisticsView()
                            .padding(.top, 40)
                    } else {
                        statisticsContent
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistiken")
            .task(id: availableMonths.first) {
                // Wenn der aktuelle Monat keine Daten hat, wähle den neuesten Monat mit Daten
                guard !availableMonths.isEmpty else { return }
                let currentHasData = availableMonths.contains {
                    Calendar.current.isDate($0, equalTo: selectedMonth, toGranularity: .month)
                }
                if !currentHasData, let newest = availableMonths.first {
                    selectedMonth = newest
                }
            }
        }
    }

    @ViewBuilder
    private var statisticsContent: some View {
        // KPI Kacheln
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Ladevorgänge",
                value: "\(finishedSessions.count)",
                unit: "Sitzungen",
                icon: "bolt.circle.fill",
                color: Color("Electric Blue")
            )
            StatCard(
                title: "Energie geladen",
                value: totalEnergy.formatted(.number.precision(.fractionLength(1))),
                unit: "kWh",
                icon: "bolt.fill",
                color: Color("Amber Energy")
            )
            StatCard(
                title: "Gesamtkosten",
                value: totalCost.formatted(.currency(code: "EUR")),
                unit: nil,
                icon: "eurosign.circle.fill",
                color: Color("Growth Green")
            )
            StatCard(
                title: "Ø Preis / kWh",
                value: averageCostPerKwh.formatted(.currency(code: "EUR")),
                unit: "pro kWh",
                icon: "chart.line.uptrend.xyaxis",
                color: Color("Amber Energy")
            )
        }
        .padding(.horizontal)

        // Energie-Verlauf Chart
        if !dailyEnergyData.isEmpty {
            ChartCard(title: "Energie pro Tag", icon: "chart.bar.fill") {
                Chart(dailyEnergyData, id: \.day) { entry in
                    BarMark(
                        x: .value("Tag", entry.day, unit: .day),
                        y: .value("kWh", entry.energy)
                    )
                    .foregroundStyle(Color("Amber Energy").gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, dailyEnergyData.count / 6))) { _ in
                        AxisValueLabel(format: .dateTime.day())
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let kwh = value.as(Double.self) {
                                Text("\(kwh.formatted(.number.precision(.fractionLength(0)))) kWh")
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 180)
            }
            .padding(.horizontal)
        }

        // Stationen
        if !stationUsage.isEmpty {
            ChartCard(title: "Häufigste Ladestationen", icon: "ev.charger.fill") {
                Chart(stationUsage.prefix(5), id: \.name) { entry in
                    BarMark(
                        x: .value("Ladevorgänge", entry.count),
                        y: .value("Station", entry.name)
                    )
                    .foregroundStyle(Color("Electric Blue").gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 1)) { value in
                        AxisValueLabel {
                            if let count = value.as(Int.self) {
                                Text("\(count)x")
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: CGFloat(min(stationUsage.prefix(5).count, 5)) * 44 + 20)
            }
            .padding(.horizontal)
        }

        // Ø-Energie pro Sitzung
        ChartCard(title: "Ø Energie pro Sitzung", icon: "bolt.badge.checkmark.fill") {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(averageEnergy.formatted(.number.precision(.fractionLength(1))))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("Amber Energy"))
                    Text("kWh Ø")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Min: \(finishedSessions.map(\.energyKwh).min()?.formatted(.number.precision(.fractionLength(1))) ?? "-") kWh")
                    Text("Max: \(finishedSessions.map(\.energyKwh).max()?.formatted(.number.precision(.fractionLength(1))) ?? "-") kWh")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }
}

// MARK: - MonthPickerView

private struct MonthPickerView: View {
    @Binding var selectedMonth: Date
    let availableMonths: [Date]

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(availableMonths, id: \.self) { month in
                    let isSelected = Calendar.current.isDate(month, equalTo: selectedMonth, toGranularity: .month)
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMonth = month
                        }
                    } label: {
                        Text(Self.monthFormatter.string(from: month))
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? Color.accentColor : Color.secondary.opacity(0.12),
                                in: Capsule()
                            )
                            .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3), value: isSelected)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let unit {
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - ChartCard

private struct ChartCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - EmptyStatisticsView

private struct EmptyStatisticsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Keine Ladevorgänge")
                .font(.headline)
            Text("Im gewählten Monat wurden keine abgeschlossenen Ladevorgänge gefunden.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Previews

#Preview("Sample Data", traits: .modifier(SampleDataPersistencePreview())) {
    StatisticsView()
}

#Preview("Empty", traits: .modifier(EmptyPersistencePreview())) {
    StatisticsView()
}
