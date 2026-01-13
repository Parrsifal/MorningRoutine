import SwiftUI

@main
struct MorningRoutineApp: App {
    @StateObject private var storage = LocalStorage()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storage)
        }
    }
}
