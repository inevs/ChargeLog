import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    MainView()
}
