import Foundation
import SwiftData

@Model
class ChargeTariff {
    var id: UUID
    var name: String
    var pricePerKwh: Double
    var basePrice: Double
    var isFavorite: Bool = false
    var chargeSessions: [ChargeSession] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(name: String, pricePerKwh: Double, basePrice: Double, isFavorite: Bool = false) {
        self.id = UUID()
        self.name = name
        self.pricePerKwh = pricePerKwh
        self.basePrice = basePrice
        self.isFavorite = isFavorite
        self.createdAt = .now
        self.updatedAt = .now
    }
}

extension ChargeTariff {
    static var sampleData: [ChargeTariff] {
        [
            ChargeTariff(name: "IONITY Passport", pricePerKwh: 0.35, basePrice: 0.00, isFavorite: true),
            ChargeTariff(name: "Tesla Charging Basic", pricePerKwh: 0.42, basePrice: 0.00, isFavorite: false),
            ChargeTariff(name: "EnBW mobility+", pricePerKwh: 0.49, basePrice: 4.99, isFavorite: false),
            ChargeTariff(name: "Plugsurfing Power", pricePerKwh: 0.44, basePrice: 0.00, isFavorite: true),
            ChargeTariff(name: "ADAC e-Charge", pricePerKwh: 0.39, basePrice: 0.00, isFavorite: false),
        ]
    }
}
