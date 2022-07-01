//
//  AutoCreateSpeedyDiskView.swift
//  SpeedyDisk
//
//  Created by Doug on 6/5/22.
//

import SwiftUI
import ComposableArchitecture

struct AutoCreateSpeedyDiskView: View {
    let store: Store<SpeedyDiskState, SpeedyDiskAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            List {
                ForEach(viewStore.autoCreateVolumes) { volume in
                    Text(volume.name)
                    
                }
            }
        }
    }
}
