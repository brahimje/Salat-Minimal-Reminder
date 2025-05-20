import SwiftUI
import AppKit
import Adhan

@main
@MainActor
class SalatApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var prayerTimeManager: PrayerTimeManager!
    private var timer: Timer?
    private let settingsWindowController = SettingsWindowController()
    
    static func main() {
        let app = NSApplication.shared
        let delegate = SalatApp()
        app.delegate = delegate
        app.run()
    }
    
    override init() {
        super.init()
        prayerTimeManager = PrayerTimeManager()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupTimer()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        prayerTimeManager.cleanup()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "moon.stars", accessibilityDescription: "Salat")
            button.action = #selector(toggleMenu)
            button.target = self
        }
        
        updateMenuItems()
    }
    
    @objc private func toggleMenu() {
        updateMenuItems()
        statusItem.button?.performClick(nil)
    }
    
    @MainActor
    private func updateMenuItems() {
        let menu = NSMenu()
        
        // Add prayer times
        for prayer in Prayer.allCases.filter({ $0 != .sunrise }) {
            if let time = prayerTimeManager.prayerTimes?.time(for: prayer) {
                let timeString = formatTime(time)
                let item = NSMenuItem(title: "\(prayer.name): \(timeString)", action: nil, keyEquivalent: "")
                menu.addItem(item)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Add next prayer info
        if !prayerTimeManager.nextPrayerName.isEmpty {
            let nextPrayerItem = NSMenuItem(title: "Next: \(prayerTimeManager.nextPrayerName) - \(prayerTimeManager.nextPrayerTime)", action: nil, keyEquivalent: "")
            menu.addItem(nextPrayerItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Settings menu item
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        menu.addItem(settingsItem)
        
        // Quit menu item
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc private func openSettings() {
        settingsWindowController.showWindow(with: prayerTimeManager)
    }
    
    private func setupTimer() {
        // Update the menu periodically
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMenuItems()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
