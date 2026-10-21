import SwiftUI

@main
struct NewtonUnlockApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // -showPicker / -showAbout open those overlays at launch, for screenshots
            let args = ProcessInfo.processInfo.arguments
            ContentView(pickerOpen: args.contains("-showPicker"), aboutOpen: args.contains("-showAbout"))
            #else
            ContentView()
            #endif
        }
    }
}
