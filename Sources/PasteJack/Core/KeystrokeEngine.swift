import CoreGraphics
import Carbon.HIToolbox

/// Simulates keystrokes using CGEvent.
/// Uses `keyboardSetUnicodeString` for printable characters — this bypasses
/// the keyboard layout entirely. Virtual keycodes are only used for control keys.
final class KeystrokeEngine {

    private let eventSource: CGEventSource?

    init() {
        self.eventSource = CGEventSource(stateID: .hidSystemState)
    }

    /// Type a single Unicode character using CGEvent.
    /// Uses keyboardSetUnicodeString which handles all Unicode chars
    /// regardless of keyboard layout.
    func typeCharacter(_ char: Character, delay: UInt32) {
        let utf16 = Array(String(char).utf16)

        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false) else {
            return
        }

        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        usleep(delay)
    }

    /// Special handling for control characters (Return, Tab, Escape, etc.)
    func typeControlCharacter(_ keyCode: CGKeyCode, modifiers: CGEventFlags = [], delay: UInt32) {
        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = modifiers
        keyUp.flags = modifiers

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        usleep(delay)
    }
}
