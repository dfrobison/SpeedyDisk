//
//  Image+Extension.swift
//  SpeedyDisk
//
//  Created by Doug Robison on 7/9/22.
//

import SwiftUI

public extension SwiftUI.Image {
    
    /// Creates a instance of `Image` with a system symbol image of the given type.
    ///
    /// - Parameter systemSymbol: The `SFSymbol` describing this image.
    init(systemSymbol: SFSymbol) {
        self.init(systemName: systemSymbol.rawValue)
    }
}
