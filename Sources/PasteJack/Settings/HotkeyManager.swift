import Carbon.HIToolbox
import CoreGraphics

/// Manages global hotkey registration using the Carbon Event API.
/// Carbon hotkeys are the most reliable way to register system-wide shortcuts on macOS.
final class HotkeyManager {

    typealias Handler = () -> Void

    private let hotkeyID: UInt32
    private var hotKeyRef: EventHotKeyRef?
    private var handler: Handler?
    private var eventHandlerRef: EventHandlerRef?

    /// Each HotkeyManager instance needs a unique ID for Carbon to distinguish them.
    init(id: UInt32 = 1) {
        self.hotkeyID = id
    }

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

                // Extract the hotkey ID from the event to route to the correct handler
                var pressedID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &pressedID
                )
                guard status == noErr else { return OSStatus(eventNotHandledErr) }

                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                guard pressedID.id == manager.hotkeyID else { return OSStatus(eventNotHandledErr) }

                manager.handler?()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        let carbonID = EventHotKeyID(signature: OSType(0x504A), id: hotkeyID) // "PJ"
        RegisterEventHotKey(keyCode, modifiers, carbonID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    /// Re-register the hotkey with new key code and modifiers, keeping the same handler.
    func reregister(keyCode: UInt32, modifiers: UInt32) {
        guard let handler else { return }
        register(keyCode: keyCode, modifiers: modifiers, handler: handler)
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
