//
//  SpeedyDiskApp.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import SwiftUI
import ComposableArchitecture

@main
struct RAMdiskApp: App {
    
    // swiftlint:disable:next weak_delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// Our AppDelegae will handle our menu
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusBar: SpeedyDiskController!
    private let store = Store(
            initialState: SpeedyDiskState(),
            reducer: speedyDiskReducer,
            environment: .init())
    var viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>!
    
    // The NSStatusBar manages a collection of status items displayed within a system-wide menu bar.
    //lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    // A new menu instance ready to add items to

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBar = SpeedyDiskController(store: store)
        viewStore = ViewStore(store)
        
        NotificationCenter.default.addObserver(forName: .speedyDiskMounted, object: nil, queue: .main) { [weak self] notification in
            self?.viewStore.send(.rebuildMenu)
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didUnmountNotification, object: nil, queue: .main) { [weak self] notification in
           self?.viewStore.send(.diskEjected(path: notification.userInfo?["NSDevicePath"] as? String))
        }
        
        // Kill the launcher app if it's around
        let launcherAppId = "com.RobisonSoftwareDevelopment.SpeedyDiskLauncher"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }

    }
}
