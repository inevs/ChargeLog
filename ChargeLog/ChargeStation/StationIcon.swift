import SwiftUI

struct StationIcon: View {
    let type: ChargeStationType

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(type.backgroundColor))
                .frame(width: 48, height: 48)
            Image(systemName: type.symbolName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
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
