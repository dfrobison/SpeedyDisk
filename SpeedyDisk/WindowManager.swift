//
//  WindowManager.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import AppKit
import ComposableArchitecture
import Combine
import SwiftUI

class WindowManager: NSObject, NSWindowDelegate {
    private var newSpeedyDiskWindow: NSWindowController? = nil
    private var autoCreateManagerWindow: NSWindowController? = nil
    private let store: Store<SpeedyDiskState, SpeedyDiskAction>
    private let viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>
    private var cancellable: AnyCancellable?
    
    init(store: Store<SpeedyDiskState, SpeedyDiskAction>) {
        self.store = store
        self.viewStore = ViewStore(self.store)
        super.init()
        setupPublishers()
    }
    
    func setupPublishers() {
        cancellable = self.viewStore.publisher.closeCreateSpeedyDiskWindow
            .sink(receiveValue: { [weak self] closeWindow in
                if closeWindow {
                    self?.newSpeedyDiskWindow?.window?.close()
                }
            })
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            switch window.windowController {
                case newSpeedyDiskWindow:
                    newSpeedyDiskWindow = nil
                    break
                case autoCreateManagerWindow:
                    autoCreateManagerWindow = nil
                    break
                default:
                    return
            }
        }
    }
    
    func showNewSpeedyDiskWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if newSpeedyDiskWindow == nil {
            let contentView = CreateSpeedyDiskView(store: store)
            let hostingCtrl = NSHostingController(rootView: contentView.frame(width: 400, height: 215))
            let window = NSWindow(contentViewController: hostingCtrl)
            window.title = "Create Speedy Disk"
            newSpeedyDiskWindow = NSWindowController(window: window)
            newSpeedyDiskWindow?.window?.delegate = self
        }
        
        newSpeedyDiskWindow?.showWindow(nil)
        newSpeedyDiskWindow?.window?.makeKey()
    }
    
    func showAutoCreateManagerWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if autoCreateManagerWindow == nil {
            let contentView = AutoCreateSpeedyDiskView(store: store)
            let hostingCtrl = NSHostingController(rootView: contentView.frame(width: 800, height: 215))
            let window = NSWindow(contentViewController: hostingCtrl)
            window.title = "AutoCreate Speedy Disks"
            autoCreateManagerWindow = NSWindowController(window: window)
            autoCreateManagerWindow?.window?.delegate = self
        }

        autoCreateManagerWindow?.showWindow(nil)
        autoCreateManagerWindow?.window?.makeKey()
    }
}
