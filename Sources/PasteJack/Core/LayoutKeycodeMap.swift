import Carbon.HIToolbox
import CoreGraphics

/// Target keyboard layout for remote consoles that ignore Unicode payloads.
enum TargetLayout: String, CaseIterable, Identifiable {
    case auto = "auto"    // keyboardSetUnicodeString (current behavior)
    case us = "us"        // US ANSI
    case de = "de"        // German QWERTZ
    case uk = "uk"        // UK
    case fr = "fr"        // French AZERTY
    var id: String { rawValue }
}

/// Maps printable ASCII characters to virtual keycodes + modifiers for specific keyboard layouts.
/// Used when targeting remote consoles (iDRAC/IPMI/RDP) that only see virtual keycodes.
enum LayoutKeycodeMap {

    /// Returns keyCode + modifiers for a character in the given layout.
    /// Returns nil if no mapping exists (fallback to keyboardSetUnicodeString).
    static func keycode(for char: Character, layout: TargetLayout) -> (keyCode: CGKeyCode, modifiers: CGEventFlags)? {
        switch layout {
        case .auto:
            return nil
        case .us:
            return usMap[char]
        case .de:
            return deMap[char]
        case .uk:
            return ukMap[char]
        case .fr:
            return frMap[char]
        }
    }

    // MARK: - US ANSI Layout

    private static let usMap: [Character: (keyCode: CGKeyCode, modifiers: CGEventFlags)] = {
        var m: [Character: (CGKeyCode, CGEventFlags)] = [:]
        let none: CGEventFlags = []
        let shift: CGEventFlags = .maskShift

        // Letters lowercase
        m["a"] = (CGKeyCode(kVK_ANSI_A), none)
        m["b"] = (CGKeyCode(kVK_ANSI_B), none)
        m["c"] = (CGKeyCode(kVK_ANSI_C), none)
        m["d"] = (CGKeyCode(kVK_ANSI_D), none)
        m["e"] = (CGKeyCode(kVK_ANSI_E), none)
        m["f"] = (CGKeyCode(kVK_ANSI_F), none)
        m["g"] = (CGKeyCode(kVK_ANSI_G), none)
        m["h"] = (CGKeyCode(kVK_ANSI_H), none)
        m["i"] = (CGKeyCode(kVK_ANSI_I), none)
        m["j"] = (CGKeyCode(kVK_ANSI_J), none)
        m["k"] = (CGKeyCode(kVK_ANSI_K), none)
        m["l"] = (CGKeyCode(kVK_ANSI_L), none)
        m["m"] = (CGKeyCode(kVK_ANSI_M), none)
        m["n"] = (CGKeyCode(kVK_ANSI_N), none)
        m["o"] = (CGKeyCode(kVK_ANSI_O), none)
        m["p"] = (CGKeyCode(kVK_ANSI_P), none)
        m["q"] = (CGKeyCode(kVK_ANSI_Q), none)
        m["r"] = (CGKeyCode(kVK_ANSI_R), none)
        m["s"] = (CGKeyCode(kVK_ANSI_S), none)
        m["t"] = (CGKeyCode(kVK_ANSI_T), none)
        m["u"] = (CGKeyCode(kVK_ANSI_U), none)
        m["v"] = (CGKeyCode(kVK_ANSI_V), none)
        m["w"] = (CGKeyCode(kVK_ANSI_W), none)
        m["x"] = (CGKeyCode(kVK_ANSI_X), none)
        m["y"] = (CGKeyCode(kVK_ANSI_Y), none)
        m["z"] = (CGKeyCode(kVK_ANSI_Z), none)

        // Letters uppercase
        m["A"] = (CGKeyCode(kVK_ANSI_A), shift)
        m["B"] = (CGKeyCode(kVK_ANSI_B), shift)
        m["C"] = (CGKeyCode(kVK_ANSI_C), shift)
        m["D"] = (CGKeyCode(kVK_ANSI_D), shift)
        m["E"] = (CGKeyCode(kVK_ANSI_E), shift)
        m["F"] = (CGKeyCode(kVK_ANSI_F), shift)
        m["G"] = (CGKeyCode(kVK_ANSI_G), shift)
        m["H"] = (CGKeyCode(kVK_ANSI_H), shift)
        m["I"] = (CGKeyCode(kVK_ANSI_I), shift)
        m["J"] = (CGKeyCode(kVK_ANSI_J), shift)
        m["K"] = (CGKeyCode(kVK_ANSI_K), shift)
        m["L"] = (CGKeyCode(kVK_ANSI_L), shift)
        m["M"] = (CGKeyCode(kVK_ANSI_M), shift)
        m["N"] = (CGKeyCode(kVK_ANSI_N), shift)
        m["O"] = (CGKeyCode(kVK_ANSI_O), shift)
        m["P"] = (CGKeyCode(kVK_ANSI_P), shift)
        m["Q"] = (CGKeyCode(kVK_ANSI_Q), shift)
        m["R"] = (CGKeyCode(kVK_ANSI_R), shift)
        m["S"] = (CGKeyCode(kVK_ANSI_S), shift)
        m["T"] = (CGKeyCode(kVK_ANSI_T), shift)
        m["U"] = (CGKeyCode(kVK_ANSI_U), shift)
        m["V"] = (CGKeyCode(kVK_ANSI_V), shift)
        m["W"] = (CGKeyCode(kVK_ANSI_W), shift)
        m["X"] = (CGKeyCode(kVK_ANSI_X), shift)
        m["Y"] = (CGKeyCode(kVK_ANSI_Y), shift)
        m["Z"] = (CGKeyCode(kVK_ANSI_Z), shift)

        // Numbers
        m["0"] = (CGKeyCode(kVK_ANSI_0), none)
        m["1"] = (CGKeyCode(kVK_ANSI_1), none)
        m["2"] = (CGKeyCode(kVK_ANSI_2), none)
        m["3"] = (CGKeyCode(kVK_ANSI_3), none)
        m["4"] = (CGKeyCode(kVK_ANSI_4), none)
        m["5"] = (CGKeyCode(kVK_ANSI_5), none)
        m["6"] = (CGKeyCode(kVK_ANSI_6), none)
        m["7"] = (CGKeyCode(kVK_ANSI_7), none)
        m["8"] = (CGKeyCode(kVK_ANSI_8), none)
        m["9"] = (CGKeyCode(kVK_ANSI_9), none)

        // Shift+number symbols
        m["!"] = (CGKeyCode(kVK_ANSI_1), shift)
        m["@"] = (CGKeyCode(kVK_ANSI_2), shift)
        m["#"] = (CGKeyCode(kVK_ANSI_3), shift)
        m["$"] = (CGKeyCode(kVK_ANSI_4), shift)
        m["%"] = (CGKeyCode(kVK_ANSI_5), shift)
        m["^"] = (CGKeyCode(kVK_ANSI_6), shift)
        m["&"] = (CGKeyCode(kVK_ANSI_7), shift)
        m["*"] = (CGKeyCode(kVK_ANSI_8), shift)
        m["("] = (CGKeyCode(kVK_ANSI_9), shift)
        m[")"] = (CGKeyCode(kVK_ANSI_0), shift)

        // Symbols
        m[" "] = (CGKeyCode(kVK_Space), none)
        m["-"] = (CGKeyCode(kVK_ANSI_Minus), none)
        m["="] = (CGKeyCode(kVK_ANSI_Equal), none)
        m["["] = (CGKeyCode(kVK_ANSI_LeftBracket), none)
        m["]"] = (CGKeyCode(kVK_ANSI_RightBracket), none)
        m["\\"] = (CGKeyCode(kVK_ANSI_Backslash), none)
        m[";"] = (CGKeyCode(kVK_ANSI_Semicolon), none)
        m["'"] = (CGKeyCode(kVK_ANSI_Quote), none)
        m[","] = (CGKeyCode(kVK_ANSI_Comma), none)
        m["."] = (CGKeyCode(kVK_ANSI_Period), none)
        m["/"] = (CGKeyCode(kVK_ANSI_Slash), none)
        m["`"] = (CGKeyCode(kVK_ANSI_Grave), none)

        // Shift+symbol
        m["_"] = (CGKeyCode(kVK_ANSI_Minus), shift)
        m["+"] = (CGKeyCode(kVK_ANSI_Equal), shift)
        m["{"] = (CGKeyCode(kVK_ANSI_LeftBracket), shift)
        m["}"] = (CGKeyCode(kVK_ANSI_RightBracket), shift)
        m["|"] = (CGKeyCode(kVK_ANSI_Backslash), shift)
        m[":"] = (CGKeyCode(kVK_ANSI_Semicolon), shift)
        m["\""] = (CGKeyCode(kVK_ANSI_Quote), shift)
        m["<"] = (CGKeyCode(kVK_ANSI_Comma), shift)
        m[">"] = (CGKeyCode(kVK_ANSI_Period), shift)
        m["?"] = (CGKeyCode(kVK_ANSI_Slash), shift)
        m["~"] = (CGKeyCode(kVK_ANSI_Grave), shift)

        return m
    }()

    // MARK: - German QWERTZ Layout

    private static let deMap: [Character: (keyCode: CGKeyCode, modifiers: CGEventFlags)] = {
        var m: [Character: (CGKeyCode, CGEventFlags)] = [:]
        let none: CGEventFlags = []
        let shift: CGEventFlags = .maskShift
        let alt: CGEventFlags = .maskAlternate
        let shiftAlt: CGEventFlags = [.maskShift, .maskAlternate]

        // Letters — Y/Z swapped
        m["a"] = (CGKeyCode(kVK_ANSI_A), none)
        m["b"] = (CGKeyCode(kVK_ANSI_B), none)
        m["c"] = (CGKeyCode(kVK_ANSI_C), none)
        m["d"] = (CGKeyCode(kVK_ANSI_D), none)
        m["e"] = (CGKeyCode(kVK_ANSI_E), none)
        m["f"] = (CGKeyCode(kVK_ANSI_F), none)
        m["g"] = (CGKeyCode(kVK_ANSI_G), none)
        m["h"] = (CGKeyCode(kVK_ANSI_H), none)
        m["i"] = (CGKeyCode(kVK_ANSI_I), none)
        m["j"] = (CGKeyCode(kVK_ANSI_J), none)
        m["k"] = (CGKeyCode(kVK_ANSI_K), none)
        m["l"] = (CGKeyCode(kVK_ANSI_L), none)
        m["m"] = (CGKeyCode(kVK_ANSI_M), none)
        m["n"] = (CGKeyCode(kVK_ANSI_N), none)
        m["o"] = (CGKeyCode(kVK_ANSI_O), none)
        m["p"] = (CGKeyCode(kVK_ANSI_P), none)
        m["q"] = (CGKeyCode(kVK_ANSI_Q), none)
        m["r"] = (CGKeyCode(kVK_ANSI_R), none)
        m["s"] = (CGKeyCode(kVK_ANSI_S), none)
        m["t"] = (CGKeyCode(kVK_ANSI_T), none)
        m["u"] = (CGKeyCode(kVK_ANSI_U), none)
        m["v"] = (CGKeyCode(kVK_ANSI_V), none)
        m["w"] = (CGKeyCode(kVK_ANSI_W), none)
        m["x"] = (CGKeyCode(kVK_ANSI_X), none)
        m["y"] = (CGKeyCode(kVK_ANSI_Z), none)  // Y/Z swapped
        m["z"] = (CGKeyCode(kVK_ANSI_Y), none)  // Y/Z swapped

        m["A"] = (CGKeyCode(kVK_ANSI_A), shift)
        m["B"] = (CGKeyCode(kVK_ANSI_B), shift)
        m["C"] = (CGKeyCode(kVK_ANSI_C), shift)
        m["D"] = (CGKeyCode(kVK_ANSI_D), shift)
        m["E"] = (CGKeyCode(kVK_ANSI_E), shift)
        m["F"] = (CGKeyCode(kVK_ANSI_F), shift)
        m["G"] = (CGKeyCode(kVK_ANSI_G), shift)
        m["H"] = (CGKeyCode(kVK_ANSI_H), shift)
        m["I"] = (CGKeyCode(kVK_ANSI_I), shift)
        m["J"] = (CGKeyCode(kVK_ANSI_J), shift)
        m["K"] = (CGKeyCode(kVK_ANSI_K), shift)
        m["L"] = (CGKeyCode(kVK_ANSI_L), shift)
        m["M"] = (CGKeyCode(kVK_ANSI_M), shift)
        m["N"] = (CGKeyCode(kVK_ANSI_N), shift)
        m["O"] = (CGKeyCode(kVK_ANSI_O), shift)
        m["P"] = (CGKeyCode(kVK_ANSI_P), shift)
        m["Q"] = (CGKeyCode(kVK_ANSI_Q), shift)
        m["R"] = (CGKeyCode(kVK_ANSI_R), shift)
        m["S"] = (CGKeyCode(kVK_ANSI_S), shift)
        m["T"] = (CGKeyCode(kVK_ANSI_T), shift)
        m["U"] = (CGKeyCode(kVK_ANSI_U), shift)
        m["V"] = (CGKeyCode(kVK_ANSI_V), shift)
        m["W"] = (CGKeyCode(kVK_ANSI_W), shift)
        m["X"] = (CGKeyCode(kVK_ANSI_X), shift)
        m["Y"] = (CGKeyCode(kVK_ANSI_Z), shift)  // Y/Z swapped
        m["Z"] = (CGKeyCode(kVK_ANSI_Y), shift)  // Y/Z swapped

        // Numbers
        m["0"] = (CGKeyCode(kVK_ANSI_0), none)
        m["1"] = (CGKeyCode(kVK_ANSI_1), none)
        m["2"] = (CGKeyCode(kVK_ANSI_2), none)
        m["3"] = (CGKeyCode(kVK_ANSI_3), none)
        m["4"] = (CGKeyCode(kVK_ANSI_4), none)
        m["5"] = (CGKeyCode(kVK_ANSI_5), none)
        m["6"] = (CGKeyCode(kVK_ANSI_6), none)
        m["7"] = (CGKeyCode(kVK_ANSI_7), none)
        m["8"] = (CGKeyCode(kVK_ANSI_8), none)
        m["9"] = (CGKeyCode(kVK_ANSI_9), none)

        // Shift+number on DE layout
        m["!"] = (CGKeyCode(kVK_ANSI_1), shift)
        m["\""] = (CGKeyCode(kVK_ANSI_2), shift)
        m["$"] = (CGKeyCode(kVK_ANSI_4), shift)
        m["%"] = (CGKeyCode(kVK_ANSI_5), shift)
        m["&"] = (CGKeyCode(kVK_ANSI_6), shift)
        m["/"] = (CGKeyCode(kVK_ANSI_7), shift)
        m["("] = (CGKeyCode(kVK_ANSI_8), shift)
        m[")"] = (CGKeyCode(kVK_ANSI_9), shift)
        m["="] = (CGKeyCode(kVK_ANSI_0), shift)

        // Special chars via Alt on DE
        m["@"] = (CGKeyCode(kVK_ANSI_L), alt)
        m["{"] = (CGKeyCode(kVK_ANSI_8), alt)
        m["}"] = (CGKeyCode(kVK_ANSI_9), alt)
        m["["] = (CGKeyCode(kVK_ANSI_5), alt)
        m["]"] = (CGKeyCode(kVK_ANSI_6), alt)
        m["\\"] = (CGKeyCode(kVK_ANSI_7), shiftAlt)
        m["|"] = (CGKeyCode(kVK_ANSI_7), alt)
        m["~"] = (CGKeyCode(kVK_ANSI_N), alt)

        // Common symbols
        m[" "] = (CGKeyCode(kVK_Space), none)
        m["-"] = (CGKeyCode(kVK_ANSI_Slash), none)  // DE: - is on /
        m["+"] = (CGKeyCode(kVK_ANSI_RightBracket), none)
        m["*"] = (CGKeyCode(kVK_ANSI_RightBracket), shift)
        m["#"] = (CGKeyCode(kVK_ANSI_Backslash), none)
        m["'"] = (CGKeyCode(kVK_ANSI_Backslash), shift)
        m[","] = (CGKeyCode(kVK_ANSI_Comma), none)
        m["."] = (CGKeyCode(kVK_ANSI_Period), none)
        m[";"] = (CGKeyCode(kVK_ANSI_Comma), shift)
        m[":"] = (CGKeyCode(kVK_ANSI_Period), shift)
        m["_"] = (CGKeyCode(kVK_ANSI_Slash), shift)
        m["<"] = (CGKeyCode(kVK_ANSI_Grave), none)
        m[">"] = (CGKeyCode(kVK_ANSI_Grave), shift)
        m["?"] = (CGKeyCode(kVK_ANSI_Minus), shift)
        m["`"] = (CGKeyCode(kVK_ANSI_Equal), shift)  // DE: ` is Shift+Akzent
        m["^"] = (CGKeyCode(kVK_ANSI_6), none)  // DE dead key but sends keycode

        return m
    }()

    // MARK: - UK Layout

    private static let ukMap: [Character: (keyCode: CGKeyCode, modifiers: CGEventFlags)] = {
        // UK is mostly like US with a few differences
        var m = usMap
        let none: CGEventFlags = []
        let shift: CGEventFlags = .maskShift
        let alt: CGEventFlags = .maskAlternate

        // UK differences from US
        m["\""] = (CGKeyCode(kVK_ANSI_2), shift)    // Shift+2 = "
        m["@"] = (CGKeyCode(kVK_ANSI_Quote), none)  // @ is where ' is in US (unshifted)
        m["'"] = (CGKeyCode(kVK_ANSI_Quote), none)   // Keep same as US actually
        // UK has a dedicated # key (kVK_ISO_Section area) - simplified mapping:
        m["#"] = (CGKeyCode(kVK_ANSI_Backslash), none)  // # key on UK
        m["~"] = (CGKeyCode(kVK_ANSI_Backslash), shift)
        m["\\"] = (CGKeyCode(kVK_ANSI_Grave), none)     // \ on UK is near left shift
        m["|"] = (CGKeyCode(kVK_ANSI_Grave), shift)
        m["`"] = (CGKeyCode(kVK_ANSI_Grave), alt)

        return m
    }()

    // MARK: - French AZERTY Layout

    private static let frMap: [Character: (keyCode: CGKeyCode, modifiers: CGEventFlags)] = {
        var m: [Character: (CGKeyCode, CGEventFlags)] = [:]
        let none: CGEventFlags = []
        let shift: CGEventFlags = .maskShift
        let alt: CGEventFlags = .maskAlternate

        // AZERTY: A/Q swapped, W/Z swapped, M moved
        m["a"] = (CGKeyCode(kVK_ANSI_Q), none)  // A is on Q key
        m["b"] = (CGKeyCode(kVK_ANSI_B), none)
        m["c"] = (CGKeyCode(kVK_ANSI_C), none)
        m["d"] = (CGKeyCode(kVK_ANSI_D), none)
        m["e"] = (CGKeyCode(kVK_ANSI_E), none)
        m["f"] = (CGKeyCode(kVK_ANSI_F), none)
        m["g"] = (CGKeyCode(kVK_ANSI_G), none)
        m["h"] = (CGKeyCode(kVK_ANSI_H), none)
        m["i"] = (CGKeyCode(kVK_ANSI_I), none)
        m["j"] = (CGKeyCode(kVK_ANSI_J), none)
        m["k"] = (CGKeyCode(kVK_ANSI_K), none)
        m["l"] = (CGKeyCode(kVK_ANSI_L), none)
        m["m"] = (CGKeyCode(kVK_ANSI_Semicolon), none)  // M is on ; key
        m["n"] = (CGKeyCode(kVK_ANSI_N), none)
        m["o"] = (CGKeyCode(kVK_ANSI_O), none)
        m["p"] = (CGKeyCode(kVK_ANSI_P), none)
        m["q"] = (CGKeyCode(kVK_ANSI_A), none)  // Q is on A key
        m["r"] = (CGKeyCode(kVK_ANSI_R), none)
        m["s"] = (CGKeyCode(kVK_ANSI_S), none)
        m["t"] = (CGKeyCode(kVK_ANSI_T), none)
        m["u"] = (CGKeyCode(kVK_ANSI_U), none)
        m["v"] = (CGKeyCode(kVK_ANSI_V), none)
        m["w"] = (CGKeyCode(kVK_ANSI_Z), none)  // W is on Z key
        m["x"] = (CGKeyCode(kVK_ANSI_X), none)
        m["y"] = (CGKeyCode(kVK_ANSI_Y), none)
        m["z"] = (CGKeyCode(kVK_ANSI_W), none)  // Z is on W key

        m["A"] = (CGKeyCode(kVK_ANSI_Q), shift)
        m["B"] = (CGKeyCode(kVK_ANSI_B), shift)
        m["C"] = (CGKeyCode(kVK_ANSI_C), shift)
        m["D"] = (CGKeyCode(kVK_ANSI_D), shift)
        m["E"] = (CGKeyCode(kVK_ANSI_E), shift)
        m["F"] = (CGKeyCode(kVK_ANSI_F), shift)
        m["G"] = (CGKeyCode(kVK_ANSI_G), shift)
        m["H"] = (CGKeyCode(kVK_ANSI_H), shift)
        m["I"] = (CGKeyCode(kVK_ANSI_I), shift)
        m["J"] = (CGKeyCode(kVK_ANSI_J), shift)
        m["K"] = (CGKeyCode(kVK_ANSI_K), shift)
        m["L"] = (CGKeyCode(kVK_ANSI_L), shift)
        m["M"] = (CGKeyCode(kVK_ANSI_Semicolon), shift)
        m["N"] = (CGKeyCode(kVK_ANSI_N), shift)
        m["O"] = (CGKeyCode(kVK_ANSI_O), shift)
        m["P"] = (CGKeyCode(kVK_ANSI_P), shift)
        m["Q"] = (CGKeyCode(kVK_ANSI_A), shift)
        m["R"] = (CGKeyCode(kVK_ANSI_R), shift)
        m["S"] = (CGKeyCode(kVK_ANSI_S), shift)
        m["T"] = (CGKeyCode(kVK_ANSI_T), shift)
        m["U"] = (CGKeyCode(kVK_ANSI_U), shift)
        m["V"] = (CGKeyCode(kVK_ANSI_V), shift)
        m["W"] = (CGKeyCode(kVK_ANSI_Z), shift)
        m["X"] = (CGKeyCode(kVK_ANSI_X), shift)
        m["Y"] = (CGKeyCode(kVK_ANSI_Y), shift)
        m["Z"] = (CGKeyCode(kVK_ANSI_W), shift)

        // Numbers on AZERTY are Shift+number row (number row has symbols by default)
        m["1"] = (CGKeyCode(kVK_ANSI_1), shift)
        m["2"] = (CGKeyCode(kVK_ANSI_2), shift)
        m["3"] = (CGKeyCode(kVK_ANSI_3), shift)
        m["4"] = (CGKeyCode(kVK_ANSI_4), shift)
        m["5"] = (CGKeyCode(kVK_ANSI_5), shift)
        m["6"] = (CGKeyCode(kVK_ANSI_6), shift)
        m["7"] = (CGKeyCode(kVK_ANSI_7), shift)
        m["8"] = (CGKeyCode(kVK_ANSI_8), shift)
        m["9"] = (CGKeyCode(kVK_ANSI_9), shift)
        m["0"] = (CGKeyCode(kVK_ANSI_0), shift)

        // Number row unshifted = symbols
        m["&"] = (CGKeyCode(kVK_ANSI_1), none)
        m["@"] = (CGKeyCode(kVK_ANSI_0), alt)      // @ via Alt+0 or Alt+Shift+2
        m["#"] = (CGKeyCode(kVK_ANSI_3), alt)       // # via Alt+3

        // Common symbols
        m[" "] = (CGKeyCode(kVK_Space), none)
        m[","] = (CGKeyCode(kVK_ANSI_M), none)       // FR: , is on M key
        m[";"] = (CGKeyCode(kVK_ANSI_Comma), none)    // FR: ; is on , key
        m[":"] = (CGKeyCode(kVK_ANSI_Period), none)    // FR: : is on . key
        m["!"] = (CGKeyCode(kVK_ANSI_Slash), none)     // FR: ! is on / key
        m["."] = (CGKeyCode(kVK_ANSI_Comma), shift)    // FR: . is Shift+,
        m["/"] = (CGKeyCode(kVK_ANSI_Period), shift)   // FR: / is Shift+:
        m["?"] = (CGKeyCode(kVK_ANSI_M), shift)        // FR: ? is Shift+M key area
        m["-"] = (CGKeyCode(kVK_ANSI_6), none)         // FR: - is on 6 key
        m["_"] = (CGKeyCode(kVK_ANSI_8), none)         // FR: _ is on 8 key
        m["("] = (CGKeyCode(kVK_ANSI_5), none)         // FR: ( is on 5 key
        m[")"] = (CGKeyCode(kVK_ANSI_Minus), none)     // FR: ) is on - key
        m["["] = (CGKeyCode(kVK_ANSI_5), alt)
        m["]"] = (CGKeyCode(kVK_ANSI_Minus), alt)
        m["{"] = (CGKeyCode(kVK_ANSI_5), alt)
        m["}"] = (CGKeyCode(kVK_ANSI_Minus), alt)
        m["\\"] = (CGKeyCode(kVK_ANSI_Period), alt)
        m["|"] = (CGKeyCode(kVK_ANSI_L), alt)
        m["~"] = (CGKeyCode(kVK_ANSI_N), alt)
        m["`"] = (CGKeyCode(kVK_ANSI_Grave), none)

        return m
    }()
}
