import Foundation
import SwiftData

@Model
class Vehicle: Identifiable {
    var id: UUID
    var brand: String
    var model: String
    var odometerKm: Int
    var batteryCapacityKwh: Double
    var chargeSessions: [ChargeSession]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(brand: String, model: String, odometerKm: Int, batteryCapacityKwh: Double) {
        self.id = UUID()
        self.brand = brand
        self.model = model
        self.odometerKm = odometerKm
        self.batteryCapacityKwh = batteryCapacityKwh
        self.chargeSessions = []
        self.createdAt = .now
        self.updatedAt = .now
    }
}

extension Vehicle {
    var displayName: String { "\(brand) \(model)" }

    static var sampleData: [Vehicle] {
        [
            Vehicle(brand: "Tesla", model: "Model 3 Long Range", odometerKm: 34_500, batteryCapacityKwh: 82.0),
            Vehicle(brand: "VW", model: "ID.4 Pro", odometerKm: 18_200, batteryCapacityKwh: 77.0),
            Vehicle(brand: "BMW", model: "iX1 xDrive30", odometerKm: 7_300, batteryCapacityKwh: 64.7),
        ]
    }
}
