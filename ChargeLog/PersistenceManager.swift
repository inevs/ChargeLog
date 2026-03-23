import SwiftData
import SwiftUI

@Observable
@MainActor
class PersistenceManager {
    let modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    init(isStoredInMemoryOnly: Bool = false, shouldLoadSampleData: Bool = false) {
        let schema = Schema([
            ChargeStation.self,
            ChargeTariff.self,
            ChargeSession.self
        ])
        let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: isStoredInMemoryOnly
                )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        if shouldLoadSampleData {
            Task { await loadSampleData() }
        }
    }
    
    func loadSampleData() async {
        let sessions = ChargeSession.sampleData
        for session in sessions {
            context.insert(session)
        }
        try? context.save()
    }
}

struct EmptyPersistencePreview: PreviewModifier {
    static func makeSharedContext() throws -> PersistenceManager {
        PersistenceManager(isStoredInMemoryOnly: true, shouldLoadSampleData: false)
    }
    
    func body(content: Content, context: PersistenceManager) -> some View {
        content
            .environment(context)
            .modelContainer(context.modelContainer)
    }
}

struct SampleDataPersistencePreview: PreviewModifier {
    static func makeSharedContext() async throws -> PersistenceManager {
        let manager = PersistenceManager(isStoredInMemoryOnly: true, shouldLoadSampleData: false)
        await manager.loadSampleData()
        return manager
    }
    
    func body(content: Content, context: PersistenceManager) -> some View {
        content
            .environment(context)
            .modelContainer(context.modelContainer)
    }
}

