import Cocoa
import Carbon

// MARK: - InputBlocker
//
// Архитектура:
// - Session tap (.cgSessionEventTap) — клавиатура + мышь + трекинг ⌘
// - HID tap (.cghidEventTap)         — ТОЛЬКО gesture raw values (жесты тачпада)
// - HID tap НЕ трогает клавиатуру — иначе session tap не увидит ⌘
//
// Выход: удержать Left⌘ (keyCode 55) + Right⌘ (keyCode 54) одновременно 3 секунды
//
// Ключевое исправление "зависания" кнопок:
// НЕ используем event.flags.contains(.maskCommand) для определения isDown —
// когда зажаты обе ⌘ и отпускаешь одну, .maskCommand всё ещё присутствует
// (вторая ⌘ ещё зажата) → isDown = true для уже отпущенной → зависание.
//
// Решение: CGEventFlags содержит device-specific биты:
//   Left  ⌘ = 0x08  (NX_DEVICELCMDKEYMASK)
//   Right ⌘ = 0x10  (NX_DEVICERCMDKEYMASK)
// Эти биты независимы — каждый отвечает только за свою физическую клавишу.

final class InputBlocker {

    // Singleton-ссылка для C-callbacks (глобальные функции не могут захватить self)
    static var shared: InputBlocker?

    // MARK: - Event Taps
    var sessionTap: CFMachPort?
    var sessionSource: CFRunLoopSource?
    var hidTap: CFMachPort?
    var hidSource: CFRunLoopSource?

    // MARK: - Dependencies
    private weak var appState: AppState?
    private var exitCallback: (() -> Void)?

    // MARK: - ⌘ Hold State
    private var leftCmdDown  = false
    private var rightCmdDown = false
    private var holdTimer: Timer?
    private var holdStart: Date?
    private let holdDuration: TimeInterval = 3.0

    // MARK: - Init / Deinit

    init(appState: AppState, onExit: @escaping () -> Void) {
        self.appState     = appState
        self.exitCallback = onExit
        InputBlocker.shared = self
    }

    deinit {
        if InputBlocker.shared === self {
            InputBlocker.shared = nil
        }
    }

    // MARK: - Public API

    func start() {
        startSessionTap()
        startGestureTap()
        print("✅ InputBlocker started")
    }

    func stop() {
        stopHold()
        stopTap(&sessionTap, source: &sessionSource)
        stopTap(&hidTap,     source: &hidSource)
        // Сбрасываем состояние кнопок при остановке
        leftCmdDown  = false
        rightCmdDown = false
        DispatchQueue.main.async { [weak self] in
            self?.appState?.leftCmdPressed  = false
            self?.appState?.rightCmdPressed = false
            self?.appState?.exitProgress    = 0
        }
        print("🛑 InputBlocker stopped")
    }

    // MARK: - Session Tap (клавиатура + мышь)

    private func startSessionTap() {
        let types: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged,
            .leftMouseDown,  .leftMouseUp,  .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .otherMouseDragged,
            .mouseMoved, .scrollWheel
        ]
        var mask: CGEventMask = 0
        for t in types { mask |= (1 << t.rawValue) }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: sessionCallback,
            userInfo: nil
        ) else {
            print("⚠️ Session tap failed — проверь Accessibility в System Settings")
            return
        }

        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)!
        sessionTap    = tap
        sessionSource = src
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("✅ Session tap active")
    }

    // MARK: - Gesture Tap (только жесты тачпада, HID уровень)

    private func startGestureTap() {
        // ВАЖНО: только gesture raw values 20-31
        // НЕ добавляем keyDown/keyUp/flagsChanged — иначе сломаем ⌘ detection!
        var mask: CGEventMask = 0
        for raw: UInt64 in 20...31 { mask |= (1 << raw) }

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: gestureCallback,
            userInfo: nil
        ) else {
            print("⚠️ Gesture tap failed — жесты могут не блокироваться")
            return
        }

        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)!
        hidTap    = tap
        hidSource = src
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("✅ Gesture tap active (Mission Control / Spaces заблокированы)")
    }

    private func stopTap(_ tap: inout CFMachPort?, source: inout CFRunLoopSource?) {
        if let t = tap { CGEvent.tapEnable(tap: t, enable: false) }
        if let s = source { CFRunLoopRemoveSource(CFRunLoopGetMain(), s, .commonModes) }
        tap    = nil
        source = nil
    }

    // MARK: - Event Processing

    func processEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {

        // ── flagsChanged: отслеживаем Left⌘ и Right⌘ ──────────────────────
        if type == .flagsChanged {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

            if keyCode == 55 || keyCode == 54 {
                // Device-specific биты в CGEventFlags.rawValue:
                //   0x08 = NX_DEVICELCMDKEYMASK → Left  ⌘
                //   0x10 = NX_DEVICERCMDKEYMASK → Right ⌘
                //
                // Эти биты независимы друг от друга:
                // если зажаты обе ⌘ и отпускаешь Left⌘ →
                //   0x08 становится 0, 0x10 остаётся 1
                // Нет зависания!
                let rawFlags = event.flags.rawValue

                if keyCode == 55 {
                    leftCmdDown  = (rawFlags & 0x08) != 0
                } else {
                    rightCmdDown = (rawFlags & 0x10) != 0
                }

                updateCmdUI()

                if leftCmdDown && rightCmdDown {
                    startHold()
                } else {
                    cancelHold()
                }
            }

            return nil // блокируем modifier-событие
        }

        // ── Всё остальное блокируем ────────────────────────────────────────
        return nil
    }

    // MARK: - UI Update

    private func updateCmdUI() {
        let left  = leftCmdDown
        let right = rightCmdDown
        // Уже на main thread (RunLoop.main обрабатывает tap)
        appState?.leftCmdPressed  = left
        appState?.rightCmdPressed = right
    }

    // MARK: - Hold Logic

    private func startHold() {
        guard holdStart == nil else { return } // уже идёт
        holdStart = Date()
        appState?.exitProgress = 0
        print("⏱ Hold started — держи 3 секунды")

        let timer = Timer(timeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.tickHold()
        }
        RunLoop.main.add(timer, forMode: .common)
        holdTimer = timer
    }

    private func tickHold() {
        guard let start = holdStart else { return }
        let elapsed  = Date().timeIntervalSince(start)
        let progress = min(elapsed / holdDuration, 1.0)

        appState?.exitProgress = progress

        if progress >= 1.0 {
            print("🔓 Exit triggered!")
            holdTimer?.invalidate()
            holdTimer = nil
            holdStart = nil

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.exitCallback?()
            }
        }
    }

    private func cancelHold() {
        guard holdStart != nil || holdTimer != nil else { return }
        holdTimer?.invalidate()
        holdTimer = nil
        holdStart = nil
        // Сбрасываем только прогресс — состояние кнопок НЕ трогаем!
        // Кнопки обновляются только через processEvent по реальным событиям.
        appState?.exitProgress = 0
        print("⏱ Hold cancelled")
    }

    private func stopHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdStart = nil
    }
}

// MARK: - C-compatible Callbacks
// Глобальные функции — единственный способ использовать CGEvent.tapCreate

private func sessionCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    // Tap отключился по таймауту macOS → немедленно включаем обратно
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = InputBlocker.shared?.sessionTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passRetained(event)
    }

    guard let blocker = InputBlocker.shared else {
        return Unmanaged.passRetained(event)
    }

    return blocker.processEvent(type: type, event: event)
}

private func gestureCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = InputBlocker.shared?.hidTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passRetained(event)
    }

    // Блокируем все gesture-события (Mission Control, Spaces, Exposé и т.д.)
    return nil
}
