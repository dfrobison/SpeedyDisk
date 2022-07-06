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
                    .underline()
                Text("Size")
                    .underline()
                Text("Folders")
                    .underline()
                Text("AutoCreate")
                    .underline()
                Text("WarnOnEject")
                    .underline()
                Text("Spotlight")
                    .underline()
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
    private enum Field: Int, Hashable {
        case diskSize
    }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        WithViewStore(store) { viewStore in
            ForEach(viewStore.autoCreateVolumes) { volume in
                Text(volume.name)
                diskSizeView(viewStore: viewStore, volume: volume)
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
    
    func isView(viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>, volume: SpeedyDiskVolume) -> Bool {
        guard let selectedVolumeId = viewStore.selectedVolumeId else {
            print("selectedVolume is nil")
            return false
        }

        print("Volume ID = \(volume.id) Selected = \(selectedVolumeId)")

        return selectedVolumeId == volume.id
    }
    
    @ViewBuilder func diskSizeView(viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>, volume: SpeedyDiskVolume) -> some View {
        if isView(viewStore: viewStore, volume: volume) {
            TextField(
              "",
              text: viewStore.binding(
                get: {$0.diskSize},
                send: SpeedyDiskAction.diskSizeChanged
              )
            )
            .focused($focusedField, equals: .diskSize)
            .onSubmit {
                focusedField = nil
                viewStore.send(.resizeVolume(volume.id))
            }

        } else {
            Button {
                focusedField = .diskSize
                viewStore.send(.volumeSelected(volume.id))
            } label: {
                Text("\(volume.size) MB")
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
