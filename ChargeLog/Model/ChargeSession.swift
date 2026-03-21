import Foundation
import SwiftData

@Model
class ChargeSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var odometerKm: Int
    var energyKwh: Double
    var socStart: Double
    var socEnd: Double?
    var billedDate: Date?
    var paymentStatus: PaymentStatus
    var chargingStation: ChargeStation
    var chargeTariff: ChargeTariff
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(odometerKm: Int, socStart: Double, chargingStation: ChargeStation, chargeTariff: ChargeTariff) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.odometerKm = odometerKm
        self.energyKwh = 0.0
        self.socStart = socStart
        self.socEnd = nil
        self.billedDate = nil
        self.paymentStatus = .open
        self.chargingStation = chargingStation
        self.chargeTariff = chargeTariff
        self.createdAt = .now
        self.updatedAt = .now
    }
}

enum PaymentStatus: String, Codable {
    case open, paid
}

extension ChargeSession {
    static var sampleData: [ChargeSession] = {
        let stations = ChargeStation.sampleData
        let tariffs = ChargeTariff.sampleData

        let session1 = ChargeSession(odometerKm: 12400, socStart: 0.18, chargingStation: stations[0], chargeTariff: tariffs[1])
        session1.endTime = Date(timeIntervalSinceNow: -3600 * 24 * 5)
        session1.startTime = Date(timeIntervalSinceNow: -3600 * 24 * 5 - 2700)
        session1.energyKwh = 52.4
        session1.socEnd = 0.85
        session1.paymentStatus = .paid
        session1.billedDate = Date(timeIntervalSinceNow: -3600 * 24 * 3)

        let session2 = ChargeSession(odometerKm: 12850, socStart: 0.22, chargingStation: stations[1], chargeTariff: tariffs[0])
        session2.endTime = Date(timeIntervalSinceNow: -3600 * 24 * 2)
        session2.startTime = Date(timeIntervalSinceNow: -3600 * 24 * 2 - 1800)
        session2.energyKwh = 38.7
        session2.socEnd = 0.79
        session2.paymentStatus = .paid
        session2.billedDate = Date(timeIntervalSinceNow: -3600 * 24 * 1)

        let session3 = ChargeSession(odometerKm: 13200, socStart: 0.31, chargingStation: stations[2], chargeTariff: tariffs[2])
        session3.endTime = Date(timeIntervalSinceNow: -3600 * 5)
        session3.startTime = Date(timeIntervalSinceNow: -3600 * 5 - 3600)
        session3.energyKwh = 61.0
        session3.socEnd = 0.95
        session3.paymentStatus = .open

        let session4 = ChargeSession(odometerKm: 13250, socStart: 0.15, chargingStation: stations[4], chargeTariff: tariffs[4])
        // session4 is still in progress — no endTime, no socEnd

        return [session1, session2, session3, session4]
    }()
}
