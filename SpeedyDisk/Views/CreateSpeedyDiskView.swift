//
//  CreateSpeedyDiskView.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import SwiftUI
import ComposableArchitecture

struct CreateSpeedyDiskView: View {
    private let columns: [GridItem] = [
        GridItem(.fixed(70)),
        GridItem(.flexible(minimum: 250))
    ]
    
    let store: Store<SpeedyDiskState, SpeedyDiskAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            LazyVGrid( columns: columns, alignment: .leading) {
                Text("Disk Name:")
                TextField("You must enter a disk name", text: viewStore.binding(\.$diskName))
                    .textFieldStyle(.roundedBorder)
                
                Text("Disk Size:")
                HStack {
                    Stepper(
                        onIncrement: {viewStore.send(.incrementSpeedyDiskSize)},
                        onDecrement: {viewStore.send(.decrementSpeedyDiskSize)}) {}
                    
                    TextField(
                      "",
                      text: viewStore.binding(\.$diskSize)
                    )
                    .frame(width: 50, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
                    
                    Text( "MB")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Text("Folders:")
                TextField("Comma separated folder names", text: viewStore.binding(\.$folders))
                    .textFieldStyle(.roundedBorder)
                
                Group {
                    Text("")
                    Toggle("AutoCreate when RAMdisk Starts", isOn: viewStore.binding(\.$autoCreate))
                        .toggleStyle(.checkbox)
                    Text("")
                    Toggle("Spotlight Index Volume", isOn: viewStore.binding(\.$spotLight))
                        .toggleStyle(.checkbox)
                    Text("")
                    Toggle("Warn on eject if RAMdisk has files", isOn: viewStore.binding(\.$warnOnEject))
                        .toggleStyle(.checkbox)
                }
            }
            .padding([.top], 15)
            .padding([.bottom], 5)
            .padding([.leading, .trailing], 15)
            .if(viewStore.showActivityIndicator) { view in
                view.overlay(ActivityIndicator())
            }
            .disabled(viewStore.showActivityIndicator)
            
            Button("Create Speedy Disk") {viewStore.send(.createSpeedyDisk)}
            .disabled(!viewStore.canCreate)
            .alert(
                self.store.scope(state: \.alert),
                dismiss: .alertDismissedTapped
              )
            Spacer()
        }
    }
}
