import Foundation
import SwiftData

@Model
class ChargeStation {
    var id: UUID
    var name: String
    var locationLat: Double
    var locationLong: Double
    var type: ChargeStationType
    var chargeSessions: [ChargeSession] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(name: String, locationLat: Double, locationLong: Double, type: ChargeStationType) {
        self.id = UUID()
        self.name = name
        self.locationLat = locationLat
        self.locationLong = locationLong
        self.type = type
        self.createdAt = .now
        self.updatedAt = .now
    }
}

enum ChargeStationType: String, Codable, CaseIterable {
    case standardAC, fastDC, powerDC
    
    var symbolName: String {
        switch self {
        case .standardAC: return "powercord"
        case .fastDC: return "bolt"
        case .powerDC: return "bolt.square"
        }
    }
    
    var backgroundColor: String {
        switch self {
        case .powerDC: "Amber Energy"
        case .fastDC:  "Electric Blue"
        case .standardAC: "Growth Green"
        }
    }
}

extension ChargeStation {
    static var sampleData: [ChargeStation] = [
        ChargeStation(name: "Tesla Supercharger Munich", locationLat: 48.1351, locationLong: 11.5820, type: .powerDC),
        ChargeStation(name: "IONITY Hamburg A7", locationLat: 53.5753, locationLong: 9.9345, type: .powerDC),
        ChargeStation(name: "EnBW AC-Charger Berlin", locationLat: 52.5200, locationLong: 13.4050, type: .standardAC),
        ChargeStation(name: "Allego Frankfurt Main", locationLat: 50.1109, locationLong: 8.6821, type: .fastDC),
        ChargeStation(name: "Fastned Cologne", locationLat: 50.9333, locationLong: 6.9500, type: .fastDC),
    ]
}
