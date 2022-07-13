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
    private var autoCreateManagerWindow: NSWindowController? = nil
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
            window.title = Constants.createSpeedyDisk
            newSpeedyDiskWindow = NSWindowController(window: window)
            newSpeedyDiskWindow?.window?.delegate = self
        }
        
        newSpeedyDiskWindow?.showWindow(nil)
        newSpeedyDiskWindow?.window?.makeKey()
        autoCreateManagerWindow?.close()
    }
    
    func showAutoCreateManagerWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        viewStore.send(.prepareForEdit)
        
        if autoCreateManagerWindow == nil {
            let contentView = SpeedyDiskManagerView(store: store)
            let hostingCtrl = NSHostingController(rootView: contentView.frame(minWidth: 825, minHeight: 215))
            let window = NSWindow(contentViewController: hostingCtrl)
            window.title = Constants.speedyDiskManager
            autoCreateManagerWindow = NSWindowController(window: window)
            autoCreateManagerWindow?.window?.delegate = self
        }
        
        autoCreateManagerWindow?.showWindow(nil)
        autoCreateManagerWindow?.window?.makeKey()
    }
    
    func endEditing(view: NSView) {
        for subView in view.subviews {
            if let s = subView as? NSTextField {
                s.endEditing(NSText())
            } else {
                endEditing(view: subView)
            }
        }
    }
    
    // The only way I can figure out how to stop the edit fields from being
    // activity is to first each one and tell it to stop editing. This
    // effective resigns the first responder.
    func resignFirstReponder() {
        if autoCreateManagerWindow != nil {
            if let subViews = autoCreateManagerWindow?.window?.contentView?.subviews {
                for subView in subViews {
                    endEditing(view: subView)
                }
            }
        }
        
        viewStore.send(.resignFirstReponderCompleted)
    }
}

extension WindowManager {
    struct Constants {
        static let speedyDiskManager = "Speedy Disks"
        static let createSpeedyDisk = "Create Speedy Disk"
    }
}
