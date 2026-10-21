import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    // macOS 11 has no single-window Window scene, so quit when the window closes.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct NewtonUnlockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Newton Unlock") {
            ContentView()
        }
        // Tell SwiftUI there's no title bar, so it sizes the window to the
        // content alone (otherwise it adds 28 pixels for a hidden title bar)
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) {}   // one window only
        }
    }
}
