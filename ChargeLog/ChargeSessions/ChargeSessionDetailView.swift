import SwiftUI

struct ChargeSessionDetailView: View {
    let session: ChargeSession
    
    var body: some View {
        Text(session.chargingStation.name)
    }
}
