//
//  View+Extension.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            AnyView(content(self))
        } else {
            AnyView(self)
        }
    }
}
