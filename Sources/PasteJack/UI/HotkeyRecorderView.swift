import SwiftUI
import Carbon.HIToolbox

/// A view that records a global hotkey combination.
/// Shows current hotkey as badges. Click "Record" to capture the next key combo.
struct HotkeyRecorderView: View {

    @Binding var keyCode: Int
    @Binding var modifiers: Int
    let defaultKeyCode: Int
    let defaultModifiers: Int

    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            // Display current hotkey
            HotkeyBadgeDisplay(keyCode: keyCode, modifiers: modifiers)

            Spacer()

            if isRecording {
                Text("Press keys…")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.indigo)

                Button("Cancel") {
                    stopRecording()
                }
                .controlSize(.mini)
            } else {
                Button("Record") {
                    startRecording()
                }
                .controlSize(.mini)

                if keyCode != defaultKeyCode || modifiers != defaultModifiers {
                    Button("Reset") {
                        keyCode = defaultKeyCode
                        modifiers = defaultModifiers
                    }
                    .controlSize(.mini)
                }
            }
        }
    }

    private func startRecording() {
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Require at least one modifier
            let mods = event.modifierFlags.intersection([.control, .shift, .option, .command])
            guard !mods.isEmpty else { return event }

            let carbonMods = carbonModifiers(from: mods)
            self.keyCode = Int(event.keyCode)
            self.modifiers = Int(carbonMods)
            stopRecording()
            return nil // consume the event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// Convert NSEvent modifier flags to Carbon modifier mask.
    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        return result
    }
}

/// Displays a hotkey combination as keyboard badges.
struct HotkeyBadgeDisplay: View {
    let keyCode: Int
    let modifiers: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(modifierSymbols + [keySymbol], id: \.self) { key in
                Text(key)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .frame(minWidth: 22, minHeight: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(.tertiary, lineWidth: 0.5)
                    )
            }
        }
    }

    private var modifierSymbols: [String] {
        var symbols: [String] = []
        if modifiers & Int(controlKey) != 0 { symbols.append("⌃") }
        if modifiers & Int(shiftKey) != 0 { symbols.append("⇧") }
        if modifiers & Int(optionKey) != 0 { symbols.append("⌥") }
        if modifiers & Int(cmdKey) != 0 { symbols.append("⌘") }
        return symbols
    }

    private var keySymbol: String {
        Self.keyCodeToString(UInt16(keyCode))
    }

    static func keyCodeToString(_ keyCode: UInt16) -> String {
        let mapping: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
            38: "J", 40: "K", 45: "N", 46: "M",
        ]
        return mapping[keyCode] ?? "?"
    }
}
