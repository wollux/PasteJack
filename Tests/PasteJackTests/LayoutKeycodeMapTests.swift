import Carbon.HIToolbox
import CoreGraphics
import Testing
@testable import PasteJack

@Suite("LayoutKeycodeMap Tests")
struct LayoutKeycodeMapTests {

    // MARK: - Auto layout

    @Test("Auto layout returns nil for all characters")
    func autoReturnsNil() {
        #expect(LayoutKeycodeMap.keycode(for: "a", layout: .auto) == nil)
        #expect(LayoutKeycodeMap.keycode(for: "Z", layout: .auto) == nil)
        #expect(LayoutKeycodeMap.keycode(for: "@", layout: .auto) == nil)
        #expect(LayoutKeycodeMap.keycode(for: "5", layout: .auto) == nil)
    }

    // MARK: - US layout

    @Test("US layout maps lowercase letters")
    func usLowercaseLetters() {
        let result = LayoutKeycodeMap.keycode(for: "a", layout: .us)
        #expect(result != nil)
        #expect(result?.keyCode == CGKeyCode(kVK_ANSI_A))
        #expect(result?.modifiers == [])
    }

    @Test("US layout maps uppercase letters with shift")
    func usUppercaseLetters() {
        let result = LayoutKeycodeMap.keycode(for: "A", layout: .us)
        #expect(result != nil)
        #expect(result?.keyCode == CGKeyCode(kVK_ANSI_A))
        #expect(result?.modifiers == .maskShift)
    }

    @Test("US layout maps digits")
    func usDigits() {
        for digit: Character in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"] {
            let result = LayoutKeycodeMap.keycode(for: digit, layout: .us)
            #expect(result != nil, "Missing mapping for \(digit)")
            #expect(result?.modifiers == [])
        }
    }

    @Test("US layout maps shifted number symbols")
    func usShiftedNumberSymbols() {
        let symbols: [Character] = ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"]
        for sym in symbols {
            let result = LayoutKeycodeMap.keycode(for: sym, layout: .us)
            #expect(result != nil, "Missing mapping for \(sym)")
            #expect(result?.modifiers == .maskShift)
        }
    }

    @Test("US layout maps common symbols")
    func usCommonSymbols() {
        let unshifted: [Character] = [" ", "-", "=", "[", "]", "\\", ";", "'", ",", ".", "/", "`"]
        for sym in unshifted {
            #expect(LayoutKeycodeMap.keycode(for: sym, layout: .us) != nil, "Missing mapping for \(sym)")
        }
        let shifted: [Character] = ["_", "+", "{", "}", "|", ":", "\"", "<", ">", "?", "~"]
        for sym in shifted {
            let result = LayoutKeycodeMap.keycode(for: sym, layout: .us)
            #expect(result != nil, "Missing mapping for \(sym)")
            #expect(result?.modifiers == .maskShift)
        }
    }

    // MARK: - DE layout

    @Test("DE layout swaps Y and Z")
    func deYZSwap() {
        let y = LayoutKeycodeMap.keycode(for: "y", layout: .de)
        let z = LayoutKeycodeMap.keycode(for: "z", layout: .de)
        #expect(y?.keyCode == CGKeyCode(kVK_ANSI_Z))
        #expect(z?.keyCode == CGKeyCode(kVK_ANSI_Y))
    }

    @Test("DE layout uppercase Y/Z swap")
    func deUppercaseYZSwap() {
        let bigY = LayoutKeycodeMap.keycode(for: "Y", layout: .de)
        let bigZ = LayoutKeycodeMap.keycode(for: "Z", layout: .de)
        #expect(bigY?.keyCode == CGKeyCode(kVK_ANSI_Z))
        #expect(bigY?.modifiers == .maskShift)
        #expect(bigZ?.keyCode == CGKeyCode(kVK_ANSI_Y))
        #expect(bigZ?.modifiers == .maskShift)
    }

    @Test("DE layout @ is Alt+L")
    func deAtSign() {
        let result = LayoutKeycodeMap.keycode(for: "@", layout: .de)
        #expect(result?.keyCode == CGKeyCode(kVK_ANSI_L))
        #expect(result?.modifiers == .maskAlternate)
    }

    @Test("DE layout { is Alt+8")
    func deLeftBrace() {
        let result = LayoutKeycodeMap.keycode(for: "{", layout: .de)
        #expect(result?.keyCode == CGKeyCode(kVK_ANSI_8))
        #expect(result?.modifiers == .maskAlternate)
    }

    @Test("DE layout } is Alt+9")
    func deRightBrace() {
        let result = LayoutKeycodeMap.keycode(for: "}", layout: .de)
        #expect(result?.keyCode == CGKeyCode(kVK_ANSI_9))
        #expect(result?.modifiers == .maskAlternate)
    }

    @Test("DE layout [ is Alt+5")
    func deLeftBracket() {
        let result = LayoutKeycodeMap.keycode(for: "[", layout: .de)
        #expect(result?.keyCode == CGKeyCode(kVK_ANSI_5))
        #expect(result?.modifiers == .maskAlternate)
    }

    @Test("DE layout | is Alt+7")
    func dePipe() {
        let result = LayoutKeycodeMap.keycode(for: "|", layout: .de)
        #expect(result?.keyCode == CGKeyCode(kVK_ANSI_7))
        #expect(result?.modifiers == .maskAlternate)
    }

    @Test("DE layout maps digits without modifiers")
    func deDigits() {
        for digit: Character in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"] {
            let result = LayoutKeycodeMap.keycode(for: digit, layout: .de)
            #expect(result != nil, "Missing DE mapping for \(digit)")
            #expect(result?.modifiers == [])
        }
    }

    // MARK: - UK layout

    @Test("UK layout has # on backslash key")
    func ukHash() {
        let result = LayoutKeycodeMap.keycode(for: "#", layout: .uk)
        #expect(result?.keyCode == CGKeyCode(kVK_ANSI_Backslash))
        #expect(result?.modifiers == [])
    }

    // MARK: - FR layout

    @Test("FR layout swaps A/Q and W/Z")
    func frAZERTYSwaps() {
        let a = LayoutKeycodeMap.keycode(for: "a", layout: .fr)
        let q = LayoutKeycodeMap.keycode(for: "q", layout: .fr)
        let w = LayoutKeycodeMap.keycode(for: "w", layout: .fr)
        let z = LayoutKeycodeMap.keycode(for: "z", layout: .fr)

        #expect(a?.keyCode == CGKeyCode(kVK_ANSI_Q))
        #expect(q?.keyCode == CGKeyCode(kVK_ANSI_A))
        #expect(w?.keyCode == CGKeyCode(kVK_ANSI_Z))
        #expect(z?.keyCode == CGKeyCode(kVK_ANSI_W))
    }

    @Test("FR layout digits require shift")
    func frDigitsNeedShift() {
        for digit: Character in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] {
            let result = LayoutKeycodeMap.keycode(for: digit, layout: .fr)
            #expect(result != nil, "Missing FR mapping for \(digit)")
            #expect(result?.modifiers == .maskShift)
        }
    }

    // MARK: - Unmapped characters

    @Test("Non-ASCII characters return nil for all layouts")
    func nonASCIIReturnsNil() {
        let layouts: [TargetLayout] = [.us, .de, .uk, .fr]
        for layout in layouts {
            #expect(LayoutKeycodeMap.keycode(for: "\u{00FC}", layout: layout) == nil) // ü
            #expect(LayoutKeycodeMap.keycode(for: "\u{20AC}", layout: layout) == nil) // €
        }
    }
}
