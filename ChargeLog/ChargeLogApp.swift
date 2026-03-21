import SwiftUI
import SwiftData

@main
struct ChargeLogApp: App {
    let persistenceManager = PersistenceManager()
    
    init() {
        if let url = persistenceManager.modelContainer.configurations.first?.url {
            print("Database location: \(url.path)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
            .environment(persistenceManager)
            .modelContainer(persistenceManager.modelContainer)
        }
    }
}
