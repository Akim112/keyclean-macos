import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color(nsColor: NSColor(red: 0.03, green: 0.03, blue: 0.06, alpha: 1.0))
                .ignoresSafeArea()

            if appState.isCleaning {
                CleaningView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                MainView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appState.isCleaning)
    }
}
