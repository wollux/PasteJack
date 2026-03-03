import Carbon.HIToolbox
import CoreGraphics

/// Manages global hotkey registration using the Carbon Event API.
/// Carbon hotkeys are the most reliable way to register system-wide shortcuts on macOS.
final class HotkeyManager {

    typealias Handler = () -> Void

    private var hotKeyRef: EventHotKeyRef?
    private var handler: Handler?
    private var eventHandlerRef: EventHandlerRef?

    /// Register a global hotkey. Default: Ctrl+Shift+V
    func register(
        keyCode: UInt32 = Constants.defaultHotkeyKeyCode,
        modifiers: UInt32 = Constants.defaultHotkeyModifiers,
        handler: @escaping Handler
    ) {
        unregister()
        self.handler = handler

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handler?()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        let hotkeyID = EventHotKeyID(signature: OSType(0x504A), id: 1) // "PJ"
        RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
    }

    deinit {
        unregister()
    }
}
