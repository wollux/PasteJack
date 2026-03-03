import Carbon.HIToolbox

/// Detects the current keyboard input source.
/// Useful for diagnostics and future layout-aware features.
enum KeyboardLayoutDetector {

    /// Get the identifier of the current keyboard input source (e.g. "com.apple.keylayout.US").
    static var currentInputSourceID: String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        guard let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }
        return Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
    }

    /// Get a human-readable name for the current input source (e.g. "U.S.", "German").
    static var currentInputSourceName: String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        guard let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else {
            return nil
        }
        return Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
    }
}
