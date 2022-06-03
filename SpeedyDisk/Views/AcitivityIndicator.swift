//
//  AcitivityIndicator.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import SwiftUI
import AppKit

struct ActivityIndicator: NSViewRepresentable {
    typealias NSViewType = NSProgressIndicator
    
    func makeNSView(context: Context) -> NSProgressIndicator {
        let view = NSProgressIndicator()
        view.style = .spinning
        view.startAnimation(nil)
        return view
    }
    
    func updateNSView(_ uiView: NSProgressIndicator, context: Context) {}
}
