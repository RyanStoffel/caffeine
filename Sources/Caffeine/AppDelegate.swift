import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var iconView: CoffeeIconView!
    private var caffeinate: Process?
    private var activeStartDate: Date?
    private var lidClosedEnabled = false
    private var disableSleepApplied = false

    private var isActive: Bool { caffeinate?.isRunning ?? false }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 26)
        statusItem.button?.action = #selector(handleClick)
        statusItem.button?.target = self
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        if let button = statusItem.button {
            iconView = CoffeeIconView(frame: button.bounds)
            iconView.autoresizingMask = [.width, .height]
            button.addSubview(iconView)
        }
        updateIcon(animated: false)
    }

    func applicationWillTerminate(_ notification: Notification) {
        stop()
        // Never leave the system permanently unable to sleep.
        if disableSleepApplied {
            _ = setDisableSleep(false)
            disableSleepApplied = false
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        toggle()
        return false
    }

    @objc private func handleClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            toggle()
        }
    }

    private func toggle() {
        isActive ? stop() : start()
        reconcileDisableSleep()
        updateIcon(animated: true)
    }

    // MARK: - Caffeinate

    private func start() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = caffeinateArguments()
        process.terminationHandler = { [weak self, weak process] _ in
            DispatchQueue.main.async {
                guard let self, self.caffeinate === process else { return }
                self.caffeinate = nil
                self.activeStartDate = nil
                self.updateIcon(animated: true)
            }
        }
        do {
            try process.run()
            caffeinate = process
            activeStartDate = Date()
        } catch {
            caffeinate = nil
            activeStartDate = nil
        }
    }

    private func stop() {
        caffeinate?.terminate()
        caffeinate = nil
        activeStartDate = nil
    }

    /// Relaunches caffeinate with up-to-date assertions while preserving the timer.
    private func restartCaffeinate() {
        guard isActive else { return }
        let preservedStart = activeStartDate
        let old = caffeinate
        caffeinate = nil
        old?.terminationHandler = nil
        old?.terminate()
        start()
        activeStartDate = preservedStart
    }

    private func caffeinateArguments() -> [String] {
        // -d prevents display sleep. When keeping the Mac awake with the lid
        // closed we also block idle (-i) and system (-s) sleep so it stays up.
        lidClosedEnabled ? ["-d", "-i", "-s"] : ["-d"]
    }

    // MARK: - Lid-closed mode

    @objc private func toggleLidClosed() {
        let enabling = !lidClosedEnabled
        lidClosedEnabled = enabling
        if enabling && !isActive {
            start()
        }

        // pmset disablesleep requires admin; this prompts for the password.
        if reconcileDisableSleep() {
            restartCaffeinate()
        } else {
            // Cancelled or failed: revert to the previous state.
            lidClosedEnabled = !enabling
            reconcileDisableSleep()
            restartCaffeinate()
        }
        updateIcon(animated: true)
    }

    /// Aligns the system `disablesleep` setting with the current intent,
    /// prompting for admin only when the value actually needs to change.
    @discardableResult
    private func reconcileDisableSleep() -> Bool {
        let desired = isActive && lidClosedEnabled
        guard desired != disableSleepApplied else { return true }
        if setDisableSleep(desired) {
            disableSleepApplied = desired
            return true
        }
        return false
    }

    private func setDisableSleep(_ enabled: Bool) -> Bool {
        let script = "do shell script \"pmset -a disablesleep \(enabled ? 1 : 0)\" with administrator privileges"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    // MARK: - Icon & Menu

    private func updateIcon(animated: Bool) {
        let description: String
        if isActive {
            description = lidClosedEnabled
                ? "Caffeine: Active (awake with lid closed)"
                : "Caffeine: Active (display awake)"
        } else {
            description = "Caffeine: Inactive"
        }
        iconView.setFilled(isActive, animated: animated)
        statusItem.button?.toolTip = description
        statusItem.button?.setAccessibilityLabel(description)
        statusItem.button?.setAccessibilityHelp("Click to toggle keeping your Mac awake")
    }

    private func showMenu() {
        let menu = NSMenu()

        // Status header
        let headerTitle: String
        let headerSymbol: String
        if isActive, let start = activeStartDate {
            let elapsed = Int(Date().timeIntervalSince(start))
            headerTitle = "Active · \(formatDuration(elapsed))"
            headerSymbol = "cup.and.saucer.fill"
        } else {
            headerTitle = "Inactive"
            headerSymbol = "cup.and.saucer"
        }
        let header = NSMenuItem(title: headerTitle, action: nil, keyEquivalent: "")
        header.image = menuSymbol(headerSymbol)
        header.isEnabled = false
        menu.addItem(header)

        menu.addItem(.separator())

        // Toggle active
        let toggleItem = NSMenuItem(
            title: isActive ? "Turn Off" : "Turn On",
            action: #selector(menuToggle),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.image = menuSymbol(isActive ? "moon.zzz.fill" : "bolt.fill")
        menu.addItem(toggleItem)

        // Keep awake with lid closed
        let lidItem = NSMenuItem(
            title: "Keep Awake with Lid Closed",
            action: #selector(toggleLidClosed),
            keyEquivalent: ""
        )
        lidItem.target = self
        lidItem.image = menuSymbol("laptopcomputer")
        lidItem.state = lidClosedEnabled ? .on : .off
        menu.addItem(lidItem)

        menu.addItem(.separator())

        // Launch at Login
        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.image = menuSymbol("power")
        if #available(macOS 13.0, *) {
            loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
        menu.addItem(loginItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Caffeine",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.image = menuSymbol("xmark.circle")
        menu.addItem(quitItem)

        self.statusItem.menu = menu
        self.statusItem.button?.performClick(nil)
        self.statusItem.menu = nil
    }

    @objc private func menuToggle() {
        toggle()
    }

    @objc private func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                print("Failed to toggle launch at login: \(error)")
            }
        }
    }

    private func menuSymbol(_ name: String) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        image?.isTemplate = true
        return image
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let mins = seconds / 60
            return "\(mins)m"
        } else {
            let hrs = seconds / 3600
            let mins = (seconds % 3600) / 60
            return "\(hrs)h \(mins)m"
        }
    }
}
