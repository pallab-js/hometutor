import SwiftUI
import AppKit

@main
struct HomeTutorApp: App {
    // Shared source of truth
    @StateObject private var storageManager = StorageManager.shared
    
    init() {
        // Force the app to register as a GUI app when launched from command line
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            // Focus on the first window
            if let window = NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storageManager)
                .frame(minWidth: 1200, minHeight: 750)
                .onAppear {
                    if storageManager.settings.remindersEnabled {
                        NotificationManager.shared.requestAuthorization()
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
    }
}
