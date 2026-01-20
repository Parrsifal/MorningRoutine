import SwiftUI

@main
struct MorningRoutineApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var storage = LocalStorage()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(storage)
        }
    }
}
