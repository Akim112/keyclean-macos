import SwiftUI

@main
struct KeyCleanApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 520, minHeight: 440)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 560, height: 480)
        .commands {
            CommandGroup(replacing: .appInfo) {}
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .undoRedo) {}
        }
    }
}
