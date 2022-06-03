//
//  SpeedyDiskMenuItem.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import Foundation
import AppKit

class SpeedyDiskMenuItem: NSMenuItem {
    let clickHandler: () -> Void
    let recreateHandler: () -> Void
    let ejectHandler: () -> Void
    
    required init(title string: String,
                  action selector: Selector?,
                  keyEquivalent charCode: String,
                  clickHandler: @escaping () -> Void,
                  recreateHandler: @escaping () -> Void,
                  ejectHandler: @escaping () -> Void) {
        self.clickHandler = clickHandler
        self.recreateHandler = recreateHandler
        self.ejectHandler = ejectHandler
        
        super.init(title: string, action: selector, keyEquivalent: charCode)
        
        let view = NSView.init(frame: NSRect(x: 0, y: 0, width: 150, height: 25))

        let label: NSButton = {
            let button = NSButton(frame: NSRect(x: 20, y: 2.5, width: 90, height: 20))
            button.action = #selector(onClick(sender:))
            button.target = self
            button.title = title
            button.isBordered = false
            button.alignment = .left
            return button
        }()
        view.addSubview(label)

        let recreate: NSButton = {
            let button = NSButton(frame: NSRect(x: 110, y: 5, width: 15, height: 15))
            button.action = #selector(onRecreate(sender:))
            button.target = self
            button.image = NSImage(systemSymbolName: "repeat", accessibilityDescription: nil)
            button.imagePosition = .imageOnly
            button.isBordered = false
            return button
        }()
        view.addSubview(recreate)

        let eject: NSButton = {
            let button = NSButton(frame: NSRect(x: 130, y: 5, width: 15, height: 15))
            button.action = #selector(onEject(sender:))
            button.target = self
            button.image = NSImage(systemSymbolName: "eject.fill", accessibilityDescription: nil)
            button.imagePosition = .imageOnly
            button.isBordered = false
            return button
        }()
        view.addSubview(eject)

        self.view = view
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    @objc func onClick(sender: NSButton) {
        self.clickHandler()
    }
    
    @objc func onRecreate(sender: NSButton) {
        self.recreateHandler()
    }
    
    @objc func onEject(sender: NSButton) {
        self.ejectHandler()
    }
}
