import AppKit
import CoreGraphics

final class KeyboardListener {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var localMonitor: Any?
    var onKeyDown: ((Bool) -> Void)?
    var onUnavailable: (() -> Void)?

    var hasPermission: Bool { CGPreflightListenEventAccess() }
    var isListening: Bool { tap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false }

    func requestPermission() { _ = CGRequestListenEventAccess() }

    func start() -> Bool {
        stop()
        guard hasPermission else { return false }
        let mask = CGEventMask(1) << CGEventType.keyDown.rawValue
        guard let newTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .tailAppendEventTap, options: .listenOnly, eventsOfInterest: mask, callback: { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let owner = Unmanaged<KeyboardListener>.fromOpaque(context).takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if owner.hasPermission, let tap = owner.tap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                } else {
                    DispatchQueue.main.async { owner.onUnavailable?() }
                }
            } else if type == .keyDown {
                // Deliberately never read characters, key codes or the foreground app.
                owner.onKeyDown?(event.getIntegerValueField(.keyboardEventAutorepeat) != 0)
            }
            return Unmanaged.passUnretained(event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return false }
        guard let newSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0) else {
            CFMachPortInvalidate(newTap)
            return false
        }
        tap = newTap
        source = newSource
        CFRunLoopAddSource(CFRunLoopGetMain(), newSource, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)
        return isListening
    }

    /// Gives the in-app typing area useful feedback before global permission is granted.
    func startLocalPreview() {
        stop()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.onKeyDown?(event.isARepeat)
            return event
        }
    }

    func stop() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        localMonitor = nil
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        source = nil
        tap = nil
    }

    deinit { stop() }
}
