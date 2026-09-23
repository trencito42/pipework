import SwiftUI

@main
struct PipeworkApp: App {
    init() {
        #if DEBUG
        _ = EngineTests.runAll()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
