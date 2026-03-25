import Foundation
import SwiftData
import SwiftUI

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
    var sessionStatus: SessionStatus
    var chargingStation: ChargeStation
    var chargeTariff: ChargeTariff
    var vehicle: Vehicle?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(odometerKm: Int, socStart: Double, chargingStation: ChargeStation, chargeTariff: ChargeTariff, vehicle: Vehicle? = nil) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.odometerKm = odometerKm
        self.energyKwh = 0.0
        self.socStart = socStart
        self.socEnd = nil
        self.billedDate = nil
        self.sessionStatus = .running
        self.chargingStation = chargingStation
        self.chargeTariff = chargeTariff
        self.vehicle = vehicle
        self.createdAt = .now
        self.updatedAt = .now
    }
    
    @Transient var amount: Double {
        self.energyKwh * self.chargeTariff.pricePerKwh
    }
}

enum SessionStatus: String, Codable {
    case running, finished, paid
    
    var name: String {
        switch self {
        case .running: "laufend"
        case .finished: "beendet"
        case .paid: "bezahlt"
        }
    }
    
    var foregroundStyle: Color {
        switch self {
        case .running: Color.accentColor
        case .finished: Color.secondary
        case .paid: Color("Growth Green")
        }
    }

    var backgroundFill: Color {
        switch self {
        case .running: Color.accentColor.opacity(0.15)
        case .finished: Color.secondary.opacity(0.12)
        case .paid: Color("Growth Green").opacity(0.15)
        }
    }

    var backgroundOverlay: Color {
        switch self {
        case .running: Color.accentColor.opacity(0.55)
        case .finished: Color.secondary.opacity(0.45)
        case .paid: Color("Growth Green").opacity(0.55)
        }
    }
}

extension ChargeSession {
    static var sampleData: [ChargeSession] {
        let stations = ChargeStation.sampleData
        let tariffs = ChargeTariff.sampleData
        let vehicles = Vehicle.sampleData

        let session1 = ChargeSession(odometerKm: 34_100, socStart: 0.18, chargingStation: stations[0], chargeTariff: tariffs[1], vehicle: vehicles[0])
        session1.endTime = Date(timeIntervalSinceNow: -3600 * 24 * 5)
        session1.startTime = Date(timeIntervalSinceNow: -3600 * 24 * 5 - 2700)
        session1.energyKwh = 52.4
        session1.socEnd = 0.85
        session1.sessionStatus = .paid
        session1.billedDate = Date(timeIntervalSinceNow: -3600 * 24 * 3)

        let session2 = ChargeSession(odometerKm: 34_350, socStart: 0.22, chargingStation: stations[1], chargeTariff: tariffs[0], vehicle: vehicles[0])
        session2.endTime = Date(timeIntervalSinceNow: -3600 * 24 * 2)
        session2.startTime = Date(timeIntervalSinceNow: -3600 * 24 * 2 - 1800)
        session2.energyKwh = 38.7
        session2.socEnd = 0.79
        session2.sessionStatus = .paid
        session2.billedDate = Date(timeIntervalSinceNow: -3600 * 24 * 1)

        let session3 = ChargeSession(odometerKm: 17_900, socStart: 0.12, chargingStation: stations[2], chargeTariff: tariffs[2], vehicle: vehicles[1])
        session3.endTime = Date(timeIntervalSinceNow: -3600 * 5)
        session3.startTime = Date(timeIntervalSinceNow: -3600 * 5 - 3600)
        session3.energyKwh = 61.0
        session3.socEnd = 0.95
        session3.sessionStatus = .finished

        let session4 = ChargeSession(odometerKm: 34_500, socStart: 0.15, chargingStation: stations[4], chargeTariff: tariffs[4], vehicle: vehicles[0])
        // session4 is still in progress — no endTime, no socEnd

        return [session1, session2, session3, session4]
    }
}
