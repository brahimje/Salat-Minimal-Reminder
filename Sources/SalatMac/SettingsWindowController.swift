import AppKit
import SwiftUI

@MainActor
class SettingsWindowController: NSObject {
    private var settingsWindow: NSWindow?
    
    func showWindow(with prayerTimeManager: PrayerTimeManager) {
        // Create the window if it doesn't exist yet
        if settingsWindow == nil {
            let contentView = NSHostingView(rootView: SettingsView().environmentObject(prayerTimeManager))
            
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            
            settingsWindow?.title = "Prayer Times Settings"
            settingsWindow?.contentView = contentView
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false
        }
        
        // Show the window and bring it to the front
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
