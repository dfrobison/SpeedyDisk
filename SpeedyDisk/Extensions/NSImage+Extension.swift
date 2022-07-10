//
//  NSImage.swift
//  SpeedyDisk
//
//  Created by Doug Robison on 7/9/22.
//

import AppKit

extension NSImage {
    convenience init?(systemSymbol: SFSymbol) {
        self.init(systemSymbolName: systemSymbol.rawValue, accessibilityDescription: nil)
    }
}
