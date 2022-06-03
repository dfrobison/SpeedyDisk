//
//  SpeedyDiskController.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import AppKit
import SwiftUI
import ServiceManagement
import ComposableArchitecture
import Combine

class SpeedyDiskController {
    private let store: Store<SpeedyDiskState, SpeedyDiskAction>
    private let viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>
    private var cancellable: AnyCancellable?
    private var statusItem = NSStatusBar.system.statusItem(withLength: 28.0)
    private var statusMenu = NSMenu()
    private var currentTmpDisksMenu: NSMenu = NSMenu()
    private let launcherAppId = "com.imothee.TmpDiskLauncher"
    private let windowManager: WindowManager
    private let currentTmpDisksItem = NSMenuItem(title: NSLocalizedString("Current Speedy Disks", comment: ""), action: nil, keyEquivalent: "")
    
    init(store: Store<SpeedyDiskState, SpeedyDiskAction>) {
        self.store = store
        viewStore = ViewStore(self.store)
        windowManager = WindowManager(store: self.store)
        createMainMenu()
    }
    
    func createMainMenu() {
        // Check to see the app is in the login items
        let jobDicts = SMCopyAllJobDictionaries( kSMDomainUserLaunchd ).takeRetainedValue() as NSArray as! [[String:AnyObject]]
        let startOnLogin = jobDicts.filter { $0["Label"] as! String == self.launcherAppId }.isEmpty == false
        
        // Create the menu
        if let statusBarButton = statusItem.button {
            statusBarButton.image = NSImage(systemSymbolName: "hare.fill", accessibilityDescription: nil)
            statusBarButton.image?.size = NSSize(width: 18.0, height: 18.0)
        }
        
        // New TmpDisk section
        let newRAMDiskItem = NSMenuItem(title: NSLocalizedString("New Speedy Disk", comment: ""), action: #selector(newRAMDisk(sender:)), keyEquivalent: "n")
        newRAMDiskItem.target = self
        statusMenu.addItem(newRAMDiskItem)
        
        // Rebuild the current TmpDisk
        buildCurrentTmpDiskMenu()
        
        statusMenu.addItem(NSMenuItem.separator())
        
        // Existing TmpDisk section
        statusMenu.addItem(currentTmpDisksItem)
        statusMenu.setSubmenu(self.currentTmpDisksMenu, for: currentTmpDisksItem)
        
        // Recreate All
        let recreateAllItem = NSMenuItem(title: NSLocalizedString("Recreate All", comment: ""), action: #selector(recreateAll(sender:)), keyEquivalent: "")
        recreateAllItem.target = self
        statusMenu.addItem(recreateAllItem)
        
        // AutocreateManager
        let autoCreateManagerItem = NSMenuItem(title: NSLocalizedString("AutoCreate Manager", comment: ""), action: #selector(autoCreateManager(sender:)), keyEquivalent: "")
        autoCreateManagerItem.target = self
        statusMenu.addItem(autoCreateManagerItem)
        
        // Separator
        statusMenu.addItem(NSMenuItem.separator())
        
        // Settings section
        let startLoginItem = NSMenuItem(title: NSLocalizedString("Always Start on Login", comment: ""), action: #selector(toggleStartOnLogin(sender:)), keyEquivalent: "")
        startLoginItem.target = self
        startLoginItem.state = startOnLogin ? .on : .off
        
        statusMenu.addItem(startLoginItem)
        
        // Separator
        statusMenu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: #selector(quit(sender:)), keyEquivalent: "q")
        quitItem.target = self
        statusMenu.addItem(quitItem)
        
        // Add the menu to the item
        statusItem.menu = statusMenu
        
        cancellable = viewStore.publisher.rebuildMenu
            .sink(receiveValue: { rebuildDiskMenu in
                if rebuildDiskMenu {
                    self.buildCurrentTmpDiskMenu()
                }
            })
    }
    
    func windowWillClose(window: NSWindowController) {
        
    }
    
    // MARK: - Internal
    
    func confirmEject(volume: SpeedyDiskVolume) -> Bool {
        if (volume.showWarning()) {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Volume contains files, are you sure you want to eject?", comment: "")
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            return alert.runModal() == .alertFirstButtonReturn
        }
        return true
    }
    
    private func buildCurrentTmpDiskMenu() {
        self.currentTmpDisksMenu.removeAllItems()
        
        for volume in viewStore.volumes {
            let volumeItem = SpeedyDiskMenuItem.init(title: volume.name, action: nil, keyEquivalent: "", clickHandler: {
                NSWorkspace.shared.open(volume.URL())
                self.statusMenu.cancelTracking()
            }, recreateHandler: {
                if self.confirmEject(volume: volume) {
                    self.viewStore.send(.ejectSpeedyDisksWithName(names: [volume.name], recreate: true))
                }
                self.statusMenu.cancelTracking()
            }, ejectHandler: {
                if self.confirmEject(volume: volume) {
                    self.viewStore.send(.ejectSpeedyDisksWithName(names: [volume.name], recreate: false))
                }
                self.statusMenu.cancelTracking()
            })
            volumeItem.target = self
            self.currentTmpDisksMenu.addItem(volumeItem)
        }
        
        currentTmpDisksItem.isEnabled = viewStore.count > 0
        viewStore.send(.rebuildMenuCompeleted)
    }
    
    // MARK: - Actions
    
    @objc func newRAMDisk(sender: AnyObject) {
        windowManager.showNewSpeedyDiskWindow()
    }
    
    @objc func recreateAll(sender: AnyObject) {
        SpeedyDiskManager.shared.ejectAllSpeedyDisks(recreate: true)
    }
    
    @objc func autoCreateManager(sender: AnyObject) {
        windowManager.showAutoCreateManagerWindow()
    }
    
    @objc func toggleStartOnLogin(sender: AnyObject) {
        if let menuItem = sender as? NSMenuItem {
            if menuItem.state == .on {
                SMLoginItemSetEnabled(self.launcherAppId as CFString, false)
                menuItem.state = .off
            } else {
                SMLoginItemSetEnabled(self.launcherAppId as CFString, true)
                menuItem.state = .on
            }
        }
    }
    
    @objc func quit(sender: AnyObject) {
        NSApp.terminate(nil)
    }
}
