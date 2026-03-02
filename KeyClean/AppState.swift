import SwiftUI
import Combine

class AppState: ObservableObject {

    // MARK: - Published State
    @Published var isCleaning:        Bool   = false
    @Published var exitProgress:      Double = 0.0
    @Published var leftCmdPressed:    Bool   = false
    @Published var rightCmdPressed:   Bool   = false
    @Published var cleaningStartTime: Date?  = nil
    @Published var hasPermission:     Bool   = false

    // MARK: - Private
    private var inputBlocker: InputBlocker?
    private var permissionTimer: Timer?

    // MARK: - Init
    init() {
        checkPermissions()
        startPermissionPolling()
        observeAppActivation()
    }

    deinit {
        permissionTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Permissions

    private func startPermissionPolling() {
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkPermissions()
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    private func observeAppActivation() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkPermissions()
        }
    }

    func checkPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if hasPermission != trusted {
            hasPermission = trusted
        }
    }

    func requestPermissions() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Cleaning Mode

    func startCleaning() {
        guard !isCleaning else { return }

        // Проверка разрешений
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            requestPermissions()
            return
        }

        // Сброс состояния
        exitProgress    = 0
        leftCmdPressed  = false
        rightCmdPressed = false
        cleaningStartTime = Date()

        // Переходим в режим очистки
        isCleaning = true

        // Разворачиваем окно
        enterFullscreen()

        // Запускаем блокировку СРАЗУ (без задержки — задержка была причиной проблем)
        let blocker = InputBlocker(appState: self) { [weak self] in
            DispatchQueue.main.async {
                self?.stopCleaning()
            }
        }
        blocker.start()
        inputBlocker = blocker
    }

    func stopCleaning() {
        guard isCleaning else { return }

        // Сначала останавливаем блокировку
        inputBlocker?.stop()
        inputBlocker = nil

        // Выходим из полного экрана
        exitFullscreen()

        // Сбрасываем состояние
        isCleaning        = false
        cleaningStartTime = nil
        exitProgress      = 0
        leftCmdPressed    = false
        rightCmdPressed   = false

        // Показываем курсор
        NSCursor.unhide()
    }

    // MARK: - Window Management

    private func enterFullscreen() {
        guard let window = NSApplication.shared.windows.first else { return }
        guard let screen = NSScreen.main else { return }

        // Скрываем Menu Bar и Dock
        NSApplication.shared.presentationOptions = [
            .hideDock,
            .hideMenuBar,
            .disableForceQuit,      // блокирует Cmd+Option+Esc
            .disableSessionTermination,
            .disableHideApplication
        ]

        // Поднимаем окно поверх всего
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        window.collectionBehavior = [.fullScreenPrimary, .ignoresCycle]
        window.styleMask = [.borderless]
        window.setFrame(screen.frame, display: true, animate: false)
        window.makeKeyAndOrderFront(nil)

        // Скрываем курсор
        NSCursor.hide()
    }

    private func exitFullscreen() {
        guard let window = NSApplication.shared.windows.first else { return }

        // Восстанавливаем presentation
        NSApplication.shared.presentationOptions = []

        // Возвращаем нормальный уровень
        window.level = .normal
        window.collectionBehavior = []
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]

        // Восстанавливаем нормальный размер
        let size = CGSize(width: 860, height: 580)
        if let screen = NSScreen.main {
            let origin = CGPoint(
                x: (screen.frame.width  - size.width)  / 2,
                y: (screen.frame.height - size.height) / 2
            )
            window.setFrame(CGRect(origin: origin, size: size), display: true, animate: true)
        }

        // Восстанавливаем title bar
        window.title = "KeyClean"
    }
}
