import Foundation
import SwiftData

@Model
class ChargeStation {
    var id: UUID
    var name: String
    var locationLat: Double
    var locationLong: Double
    var chargeSessions: [ChargeSession] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(name: String, locationLat: Double, locationLong: Double) {
        self.id = UUID()
        self.name = name
        self.locationLat = locationLat
        self.locationLong = locationLong
        self.createdAt = .now
        self.updatedAt = .now
    }
}

extension ChargeStation {
    static var sampleData: [ChargeStation] = [
        ChargeStation(name: "Tesla Supercharger Munich", locationLat: 48.1351, locationLong: 11.5820),
        ChargeStation(name: "IONITY Hamburg A7", locationLat: 53.5753, locationLong: 9.9345),
        ChargeStation(name: "EnBW HyperCharger Berlin", locationLat: 52.5200, locationLong: 13.4050),
        ChargeStation(name: "Allego Frankfurt Main", locationLat: 50.1109, locationLong: 8.6821),
        ChargeStation(name: "Fastned Cologne", locationLat: 50.9333, locationLong: 6.9500),
    ]
}
