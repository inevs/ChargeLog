import Foundation
import Testing
@testable import ChargeLog

struct ChargeLogTests {
    @Test func sessionAmountIncludesBasePrice() {
        let tariff = ChargeTariff(name: "Testtarif", pricePerKwh: 0.59, basePrice: 1.50)
        let station = ChargeStation(name: "Teststation", locationLat: 0, locationLong: 0, type: .fastDC)
        let session = ChargeSession(
            odometerKm: 12_345,
            socStart: 0.25,
            chargingStation: station,
            chargeTariff: tariff
        )

        session.energyKwh = 10

        #expect(abs(session.amount - 7.4) < 0.000_001)
    }

    @Test func csvExportIncludesBasePriceAndTotalAmount() throws {
        let tariff = ChargeTariff(name: "Testtarif", pricePerKwh: 0.59, basePrice: 1.50)
        let station = ChargeStation(name: "Teststation", locationLat: 48.1351, locationLong: 11.5820, type: .fastDC)
        let vehicle = Vehicle(brand: "Test", model: "EV", odometerKm: 12_345, batteryCapacityKwh: 77)
        let session = ChargeSession(
            odometerKm: 12_345,
            socStart: 0.25,
            chargingStation: station,
            chargeTariff: tariff,
            vehicle: vehicle
        )

        session.endTime = session.startTime.addingTimeInterval(60 * 45)
        session.energyKwh = 10
        session.socEnd = 0.8
        session.sessionStatus = .finished

        let csv = CSVExporter.csv(from: [session])
        let csvString = try #require(String(data: csv.data, encoding: .utf8))

        #expect(csvString.contains("Grundpreis (EUR)"))
        #expect(csvString.contains("1,50"))
        #expect(csvString.contains("7,40"))
    }
}
