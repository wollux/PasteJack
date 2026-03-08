import AppKit
import Foundation

/// Manages update checks by directing users to the downloads page.
@MainActor
final class UpdateManager: ObservableObject {

    private static let releasesURL = "https://pastejack.app/downloads"

    func checkForUpdates() {
        if let url = URL(string: Self.releasesURL) {
            NSWorkspace.shared.open(url)
        }
    }
}
