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

    /// Type a character with adaptive speed — measures post duration and adjusts delay.
    /// Returns the actual delay used (in microseconds).
    func typeCharacterAdaptive(_ char: Character, baseDelay: UInt32, currentDelay: UInt32) -> UInt32 {
        let utf16 = Array(String(char).utf16)

        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false) else {
            return currentDelay
        }

        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)

        let start = DispatchTime.now()
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
        let elapsedMicros = UInt32(elapsed / 1000)

        // If posting took longer than expected, slow down
        var adjustedDelay = currentDelay
        if elapsedMicros > baseDelay * 2 {
            adjustedDelay = min(currentDelay + baseDelay / 2, baseDelay * 5)
        } else if currentDelay > baseDelay {
            // Gradually recover toward base speed
            adjustedDelay = max(currentDelay - baseDelay / 10, baseDelay)
        }

        usleep(adjustedDelay)
        return adjustedDelay
    }

    /// Adaptive version of typeControlCharacter.
    func typeControlCharacterAdaptive(_ keyCode: CGKeyCode, modifiers: CGEventFlags = [], baseDelay: UInt32, currentDelay: UInt32) -> UInt32 {
        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: false) else {
            return currentDelay
        }

        keyDown.flags = modifiers
        keyUp.flags = modifiers

        let start = DispatchTime.now()
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
        let elapsedMicros = UInt32(elapsed / 1000)

        var adjustedDelay = currentDelay
        if elapsedMicros > baseDelay * 2 {
            adjustedDelay = min(currentDelay + baseDelay / 2, baseDelay * 5)
        } else if currentDelay > baseDelay {
            adjustedDelay = max(currentDelay - baseDelay / 10, baseDelay)
        }

        usleep(adjustedDelay)
        return adjustedDelay
    }

    /// Simulate Cmd+C to copy selected text.
    func simulateCopy() {
        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false) else {
            return
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
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
