//
//  AutoCreateSpeedyDiskView.swift
//  SpeedyDisk
//
//  Created by Doug on 6/5/22.
//

import SwiftUI
import ComposableArchitecture

struct AutoCreateSpeedyDiskHeaderRowView: View {
    let columns: [GridItem]
    
    var body: some View {
        LazyVGrid(columns: columns) {
            Group {
                Text("Name")
                Text("Size")
                Text("Folders")
                Text("AutoCreate")
                Text("WarnOnEject")
                Text("Spotlight")
            }
            .font(.headline)
        }
    }
}

struct AutoCreateSpeedyDiskToggleView: View {
    @State var toggle: Bool
    let toggleAction: (Bool) -> Void
    
    var body: some View {
        Toggle("", isOn: $toggle)
        .toggleStyle(.checkbox)
        .onChange(of: toggle) { value in
            toggleAction(value)
        }
    }
}

struct AutoCreateSpeedyDiskRowsView: View {
    let store: Store<SpeedyDiskState, SpeedyDiskAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            ForEach(viewStore.autoCreateVolumes) { volume in
                Text(volume.name)
                Text("\(volume.size)MB")
                Text(volume.folders.joined(separator: ","))
                
                AutoCreateSpeedyDiskToggleView(toggle: volume.autoCreate) { value in
                    viewStore.send(.toggleAutoCreate(volume: volume))
                }
                
                AutoCreateSpeedyDiskToggleView(toggle: volume.warnOnEject) { value in
                    viewStore.send(.toggleWarnOnEject(volume: volume))
                }
                
                AutoCreateSpeedyDiskToggleView(toggle: volume.spotLight) { value in
                    viewStore.send(.toggleSpotLight(volume: volume))
                }
            }
        }
    }
}

struct AutoCreateSpeedyDiskView: View {
    let store: Store<SpeedyDiskState, SpeedyDiskAction>
    let columns = [
        GridItem(.flexible(), alignment: .topLeading),
        GridItem(.flexible(), alignment: .topLeading),
        GridItem(.flexible(minimum: 150), alignment: .topLeading),
        GridItem(.flexible(), alignment: .topLeading),
        GridItem(.flexible(), alignment: .topLeading),
        GridItem(.flexible(), alignment: .topLeading),
    ]
    
    var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView {
                LazyVGrid(columns: columns, pinnedViews: [.sectionHeaders]) {
                    Section(header: AutoCreateSpeedyDiskHeaderRowView(columns: self.columns)) {
                        AutoCreateSpeedyDiskRowsView(store: store)
                    }
                }
                .padding()
            }
            Spacer()
        }
    }
}
