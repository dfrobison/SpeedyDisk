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
                Text("Action")
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
        case folders
    }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        WithViewStore(store) { viewStore in
            ForEach(viewStore.autoCreateVolumes) { volume in
                let getFromViewStore = isRowSelected(viewStore: viewStore, volume: volume)
                
                Text(volume.name)
                
                diskSizeView(viewStore: viewStore, volume: volume)
                
                folderView(viewStore: viewStore, volume: volume)
                
                AutoCreateSpeedyDiskToggleView(toggle: getFromViewStore ? viewStore.autoCreate : volume.autoCreate) { value in
                    viewStore.send(.toggleAutoCreate(volumeId: volume.id))
                }
                
                AutoCreateSpeedyDiskToggleView(toggle: getFromViewStore ? viewStore.warnOnEject : volume.warnOnEject) { value in
                    viewStore.send(.toggleWarnOnEject(volumeId: volume.id))
                }
                
                AutoCreateSpeedyDiskToggleView(toggle: getFromViewStore ? viewStore.spotLight : volume.spotLight) { value in
                    viewStore.send(.toggleSpotLight(volumeId: volume.id))
                }
                
                Button {
                    viewStore.send(.recreateVolume(volumeId: volume.id))
                } label: {
                    Image(systemName: "repeat")
                }
                .disabled(!getFromViewStore)
            }
        }
    }
    
    private func isRowSelected(viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>, volume: SpeedyDiskVolume) -> Bool {
        guard let selectedVolumeId = viewStore.selectedVolumeId else {
            return false
        }
        
        return selectedVolumeId == volume.id
    }
    
    @ViewBuilder private func diskSizeView(viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>, volume: SpeedyDiskVolume) -> some View {
        if isRowSelected(viewStore: viewStore, volume: volume) && viewStore.diskButtonPressed {
            HStack {
                TextField(
                    "",
                    text: viewStore.binding(\.$diskSize)
                )
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: .diskSize)
                .onSubmit {
                    focusedField = nil
                    viewStore.send(.setButtonState(\.diskButtonPressed, value: false))
                }
                Text("MB")
            }
            
        } else {
            Button {
                focusedField = .diskSize
                viewStore.send(.volumeSelected(volume.id))
                viewStore.send(.setButtonState(\.diskButtonPressed, value: true))
            } label: {
                Text(isRowSelected(viewStore: viewStore, volume: volume) ? "\(viewStore.diskSize) MB" : "\(volume.size) MB")
            }
        }
    }
    
    private func folderName(viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>, volume: SpeedyDiskVolume) -> String {
        let selected = self.isRowSelected(viewStore: viewStore, volume: volume)
        let folders = selected ? "\(viewStore.folders)" : "\(volume.folders)"
        
        return folders.isEmpty ? "Add folders..." : folders
    }
    
    @ViewBuilder private func folderView(viewStore: ViewStore<SpeedyDiskState, SpeedyDiskAction>, volume: SpeedyDiskVolume) -> some View {
        if isRowSelected(viewStore: viewStore, volume: volume) && viewStore.folderButtonPressed {
            TextField(
                "",
                text: viewStore.binding(\.$folders)
            )
            .focused($focusedField, equals: .folders)
            .onSubmit {
                focusedField = nil
                viewStore.send(.setButtonState(\.folderButtonPressed, value: false))
            }
            
        } else {
            Button {
                focusedField = .folders
                viewStore.send(.volumeSelected(volume.id))
                viewStore.send(.setButtonState(\.folderButtonPressed, value: true))
            } label: {
                Text(folderName(viewStore: viewStore, volume: volume))
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
        }
        
        Spacer()
    }
}
