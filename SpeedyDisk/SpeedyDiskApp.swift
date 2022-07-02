//
//  SpeedyDiskApp.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import SwiftUI
import ComposableArchitecture

@main
struct SpeedyDiskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// Our AppDelegae will handle our menu
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: SpeedyDiskController!
    private let store = Store(
            initialState: SpeedyDiskState(),
            reducer: speedyDiskReducer,
            environment: .init())
    var viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBar = SpeedyDiskController(store: store)
        viewStore = ViewStore(store)
        
        NotificationCenter.default.addObserver(forName: .speedyDiskMounted, object: nil, queue: .main) { [weak self] notification in
            self?.viewStore.send(.rebuildMenu)
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didUnmountNotification, object: nil, queue: .main) { [weak self] notification in
            self?.viewStore.send(.diskEjected(path: notification.userInfo?[AppConstants.devicePath] as? String))
        }
        
        // Kill the launcher app if it's around
        let launcherAppId = AppConstants.launcherAppId
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }
    }
}
