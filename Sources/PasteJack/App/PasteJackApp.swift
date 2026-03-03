import SwiftUI

@main
struct PasteJackApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar app — no main window, settings managed via AppDelegate
        Settings {
            EmptyView()
        }
    }
}
