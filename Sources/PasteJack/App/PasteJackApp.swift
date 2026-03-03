import SwiftUI

@main
struct PasteJackApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Prevent macOS from restoring windows on launch
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
    }

    var body: some Scene {
        // Menu bar app — no visible scenes, all UI managed via AppDelegate
        Settings {
            EmptyView()
        }
    }
}
