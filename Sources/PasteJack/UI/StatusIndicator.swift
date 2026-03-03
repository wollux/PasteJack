import AppKit

/// Manages the menu bar icon state (idle/typing/error).
enum StatusIndicator {

    enum IconState {
        case idle
        case countdown
        case typing
        case completed
        case error
    }

    /// Returns the SF Symbol name for the given state.
    static func symbolName(for state: IconState) -> String {
        switch state {
        case .idle:
            return "keyboard.badge.ellipsis"
        case .countdown:
            return "timer"
        case .typing:
            return "keyboard.fill"
        case .completed:
            return "checkmark.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }

    /// Update the status item button image for the given state.
    static func update(_ button: NSStatusBarButton?, state: IconState) {
        guard let button else { return }
        button.image = NSImage(
            systemSymbolName: symbolName(for: state),
            accessibilityDescription: Constants.appName
        )
    }
}
