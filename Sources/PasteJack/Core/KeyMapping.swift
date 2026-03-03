import Carbon.HIToolbox
import CoreGraphics

/// Maps control characters to virtual keycodes.
/// Printable characters don't need mapping — they use `keyboardSetUnicodeString`.
enum ControlCharMapping {

    static let map: [Character: (keyCode: CGKeyCode, modifiers: CGEventFlags)] = [
        "\n": (CGKeyCode(kVK_Return), []),
        "\r": (CGKeyCode(kVK_Return), []),
        "\t": (CGKeyCode(kVK_Tab), []),
        "\u{1B}": (CGKeyCode(kVK_Escape), []),
        "\u{7F}": (CGKeyCode(kVK_Delete), []),
    ]

    static func isControlCharacter(_ char: Character) -> Bool {
        if let scalar = char.unicodeScalars.first {
            return scalar.value < 32 || scalar.value == 127
        }
        return false
    }
}
