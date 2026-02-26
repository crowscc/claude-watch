import SwiftUI

@main
struct CCSEAApp: App {
    var body: some Scene {
        MenuBarExtra("CCSEA", systemImage: "gauge.medium") {
            Text("Hello CCSEA")
            Divider()
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
