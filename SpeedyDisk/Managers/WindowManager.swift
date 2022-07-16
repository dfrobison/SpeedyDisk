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
import CoreAudio

class WindowManager: NSObject, NSWindowDelegate {
    private var newSpeedyDiskWindow: NSWindowController? = nil
    private var sppeedyDiskManagerWindow: NSWindowController? = nil
    private let store: Store<SpeedyDiskState, SpeedyDiskAction>
    private let viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>
    private var cancellable: AnyCancellable?
    
    var isNewSpeedyDiskWindowVisible: Bool {
        newSpeedyDiskWindow != nil
    }
    
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
                case sppeedyDiskManagerWindow:
                    sppeedyDiskManagerWindow = nil
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
            window.title = Constants.createSpeedyDisk
            newSpeedyDiskWindow = NSWindowController(window: window)
            newSpeedyDiskWindow?.window?.delegate = self
        }
        
        newSpeedyDiskWindow?.showWindow(nil)
        newSpeedyDiskWindow?.window?.makeKey()
        sppeedyDiskManagerWindow?.close()
    }
    
    func showSpeedyDiskManagerWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        viewStore.send(.prepareToShowSpeedyDiskManagerWindow)
        
        if sppeedyDiskManagerWindow == nil {
            let contentView = SpeedyDiskManagerView(store: store)
            let hostingCtrl = NSHostingController(rootView: contentView.frame(minWidth: 890, minHeight: 215))
            let window = NSWindow(contentViewController: hostingCtrl)
            window.title = Constants.speedyDiskManager
            sppeedyDiskManagerWindow = NSWindowController(window: window)
            sppeedyDiskManagerWindow?.window?.delegate = self
        }
        
        sppeedyDiskManagerWindow?.showWindow(nil)
        sppeedyDiskManagerWindow?.window?.makeKey()
    }
    
    func resignFirstReponder() {
        sppeedyDiskManagerWindow?.window?.makeFirstResponder(nil)
        viewStore.send(.resignFirstReponderCompleted)
    }
}

extension WindowManager {
    struct Constants {
        static let speedyDiskManager = "Speedy Disks"
        static let createSpeedyDisk = "Create Speedy Disk"
    }
}
