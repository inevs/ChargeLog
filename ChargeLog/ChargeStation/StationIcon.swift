import SwiftUI

struct StationIcon: View {
    let type: ChargeStationType

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(type.backgroundColor))
                .frame(width: 48, height: 48)
            Image(systemName: type.symbolName)
                .foregroundStyle(.white)
                .font(.title3)
        }
    }
}

#Preview {
    Group {
        StationIcon(type: .fastDC)
        StationIcon(type: .powerDC)
        StationIcon(type: .standardAC)
    }
}
