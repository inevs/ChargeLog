import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct ChargeSessionsCSV: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { csv in
            csv.data
        }
        .suggestedFileName { _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return "ladevorgaenge-\(formatter.string(from: .now)).csv"
        }
    }
}

enum CSVExporter {
    private static let separator = ";"
    private static let lineBreak = "\r\n"

    private static let header: [String] = [
        "Startzeit",
        "Endzeit",
        "Dauer (Min)",
        "Station",
        "Stationstyp",
        "Breite",
        "Länge",
        "Fahrzeug",
        "Kilometerstand (km)",
        "SoC Start (%)",
        "SoC Ende (%)",
        "Energie (kWh)",
        "Tarif",
        "Preis je kWh (EUR)",
        "Grundpreis (EUR)",
        "Betrag (EUR)",
        "Status",
        "Abrechnungsdatum",
        "Erstellt",
        "Aktualisiert",
    ]

    static func csv(from sessions: [ChargeSession]) -> ChargeSessionsCSV {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]

        var lines: [String] = [header.joined(separator: separator)]

        for session in sessions {
            let durationMinutes: String
            if let endTime = session.endTime {
                let minutes = Int(endTime.timeIntervalSince(session.startTime) / 60)
                durationMinutes = "\(minutes)"
            } else {
                durationMinutes = ""
            }

            let socEndPercent: String
            if let socEnd = session.socEnd {
                socEndPercent = formatted(socEnd * 100, decimals: 1)
            } else {
                socEndPercent = ""
            }

            let billedDateString: String
            if let billedDate = session.billedDate {
                billedDateString = dateFormatter.string(from: billedDate)
            } else {
                billedDateString = ""
            }

            let endTimeString: String
            if let endTime = session.endTime {
                endTimeString = dateFormatter.string(from: endTime)
            } else {
                endTimeString = ""
            }

            let fields: [String] = [
                dateFormatter.string(from: session.startTime),
                endTimeString,
                durationMinutes,
                escaped(session.chargingStation.name),
                session.chargingStation.type.label,
                formatted(session.chargingStation.locationLat, decimals: 6),
                formatted(session.chargingStation.locationLong, decimals: 6),
                escaped(session.vehicle?.displayName ?? ""),
                "\(session.odometerKm)",
                formatted(session.socStart * 100, decimals: 1),
                socEndPercent,
                formatted(session.energyKwh, decimals: 3),
                escaped(session.chargeTariff.name),
                formatted(session.chargeTariff.pricePerKwh, decimals: 4),
                formatted(session.chargeTariff.basePrice, decimals: 2),
                formatted(session.amount, decimals: 2),
                session.sessionStatus.name,
                billedDateString,
                dateFormatter.string(from: session.createdAt),
                dateFormatter.string(from: session.updatedAt),
            ]

            lines.append(fields.joined(separator: separator))
        }

        let csvString = lines.joined(separator: lineBreak) + lineBreak
        // BOM for correct UTF-8 detection in Excel
        let bom = "\u{FEFF}"
        let data = (bom + csvString).data(using: .utf8) ?? Data()
        return ChargeSessionsCSV(data: data)
    }

    /// Wraps a field in double quotes and escapes inner quotes if needed.
    private static func escaped(_ value: String) -> String {
        if value.contains(separator) || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    private static func formatted(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", value).replacingOccurrences(of: ".", with: ",")
    }
}
