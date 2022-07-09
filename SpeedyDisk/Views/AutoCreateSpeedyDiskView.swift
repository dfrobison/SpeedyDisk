//
//  AutoCreateSpeedyDiskView.swift
//  SpeedyDisk
//
//  Created by Doug on 6/5/22.
//

import SwiftUI
import ComposableArchitecture

struct AutoCreateSpeedyDiskToggleView: View {
    @State var toggle: Bool
    let toggleAction: (Bool) -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Toggle("", isOn: $toggle)
                .toggleStyle(.checkbox)
                .onChange(of: toggle) { value in
                    toggleAction(value)
                }
            Spacer()
        }
    }
}

struct EditDiskSizeView: View {
    let viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>
    let volume: SpeedyDiskVolume
    
    var body: some View {
        HStack {
            TextField(
                "",
                text: viewStore.binding(
                    get: { _ in
                        String(volume.size)
                        
                    },
                    send: { SpeedyDiskAction.diskSizeChanged($0, volume.id) }
                )
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .multilineTextAlignment(.trailing)
            
            Text("MB")
                .padding(.leading, -4)
        }
    }
}

struct EditFolderView: View {
    let viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>
    let volume: SpeedyDiskVolume
    
    var body: some View {
        TextField(
            "",
            text: viewStore.binding(
                get: { _ in volume.folders},
                send: { SpeedyDiskAction.foldersChanged($0, volume.id) }
            ),
            prompt: Text("Comma separated folder names")
        )
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
}

struct AutoCreateSpeedyDiskView: View {
    let store: Store<SpeedyDiskState, SpeedyDiskAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            
            Table(viewStore.editAutoCreateVolumes) {
                TableColumn("Name", value: \.name)
                
                TableColumn("Size") { volume in
                    EditDiskSizeView(viewStore: viewStore, volume: volume)
                }
                
                TableColumn("Folders") { volume in
                    EditFolderView(viewStore: viewStore, volume: volume)
                }
                .width(min: 75, ideal: 220, max: nil)
                
                TableColumn("AutoCreate") { volume in
                    AutoCreateSpeedyDiskToggleView(toggle: volume.autoCreate) { value in
                        viewStore.send(.toggleAutoCreate(volumeId: volume.id))
                    }
                }
                .width(65)
                
                TableColumn("WarnOnEject") { volume in
                    AutoCreateSpeedyDiskToggleView(toggle: volume.warnOnEject) { value in
                        viewStore.send(.toggleWarnOnEject(volumeId: volume.id))
                    }
                }
                .width(80)
                
                TableColumn("SpotLight") { volume in
                    AutoCreateSpeedyDiskToggleView(toggle: volume.spotLight) { value in
                        viewStore.send(.toggleSpotLight(volumeId: volume.id))
                    }
                }
                .width(60)
                
                TableColumn("Actions") { volume in
                    Button {
                        viewStore.send(.recreateVolume(volumeId: volume.id))
                    } label: {
                        Image(systemName: "repeat")
                    }
                }
            }
        }
    }
}
