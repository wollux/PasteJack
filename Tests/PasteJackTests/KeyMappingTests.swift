import Testing
@testable import PasteJack

@Suite("KeyMapping Tests")
struct KeyMappingTests {

    @Test("Newline is a control character")
    func newlineIsControlCharacter() {
        #expect(ControlCharMapping.isControlCharacter("\n"))
    }

    @Test("Carriage return is a control character")
    func carriageReturnIsControlCharacter() {
        #expect(ControlCharMapping.isControlCharacter("\r"))
    }

    @Test("Tab is a control character")
    func tabIsControlCharacter() {
        #expect(ControlCharMapping.isControlCharacter("\t"))
    }

    @Test("Escape is a control character")
    func escapeIsControlCharacter() {
        #expect(ControlCharMapping.isControlCharacter("\u{1B}"))
    }

    @Test("Backspace (DEL) is a control character")
    func backspaceIsControlCharacter() {
        #expect(ControlCharMapping.isControlCharacter("\u{7F}"))
    }

    @Test("Regular letters are not control characters")
    func regularLettersAreNotControlCharacters() {
        #expect(!ControlCharMapping.isControlCharacter("a"))
        #expect(!ControlCharMapping.isControlCharacter("Z"))
        #expect(!ControlCharMapping.isControlCharacter("5"))
    }

    @Test("Unicode characters are not control characters")
    func unicodeCharsAreNotControlCharacters() {
        #expect(!ControlCharMapping.isControlCharacter("ü"))
        #expect(!ControlCharMapping.isControlCharacter("€"))
        #expect(!ControlCharMapping.isControlCharacter("日"))
    }

    @Test("Symbols and punctuation are not control characters")
    func symbolsAreNotControlCharacters() {
        #expect(!ControlCharMapping.isControlCharacter("@"))
        #expect(!ControlCharMapping.isControlCharacter("#"))
        #expect(!ControlCharMapping.isControlCharacter(" "))
    }

    @Test("Control character map contains expected keys")
    func mapContainsExpectedKeys() {
        #expect(ControlCharMapping.map["\n"] != nil)
        #expect(ControlCharMapping.map["\r"] != nil)
        #expect(ControlCharMapping.map["\t"] != nil)
        #expect(ControlCharMapping.map["\u{1B}"] != nil)
        #expect(ControlCharMapping.map["\u{7F}"] != nil)
    }

    @Test("Regular characters are not in the control map")
    func regularCharsNotInMap() {
        #expect(ControlCharMapping.map["a"] == nil)
        #expect(ControlCharMapping.map[" "] == nil)
        #expect(ControlCharMapping.map["@"] == nil)
    }

    @Test("NUL character is a control character")
    func nulIsControlCharacter() {
        #expect(ControlCharMapping.isControlCharacter("\0"))
    }

    @Test("Bell character is a control character")
    func bellIsControlCharacter() {
        #expect(ControlCharMapping.isControlCharacter("\u{07}"))
    }
}
