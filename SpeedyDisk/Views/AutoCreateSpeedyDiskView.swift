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
    let columns = [
        GridItem(.flexible(), alignment: .topLeading),
        GridItem(.flexible(minimum: 150), alignment: .topLeading),
        GridItem(.flexible(), alignment: .topLeading),
        GridItem(.flexible(), alignment: .topLeading),
    ]
    
    
    var body: some View {
        WithViewStore(store) { viewStore in
            LazyVGrid(columns: columns) {
                
                // headers
                Group {
                    Text("Name")
                    Text("Size")
                    Text("Folders")
                    Text("")
                }
                .font(.headline)
                
                ForEach(viewStore.autoCreateVolumes) { volume in
                    HStack {
                        Text(volume.name)
                        Text(String(volume.size))
                        Text(volume.folders.joined(separator: ","))
                        Button("Delete") {
                            
                        }
                    }
                }
                
                
            }
            .padding()
            
            //            List {
            //                ForEach(viewStore.autoCreateVolumes) { volume in
            //                    HStack {
            //                        Text(volume.name)
            //                        Text(String(volume.size))
            //                        Text(volume.folders.joined(separator: ","))
            //                    }
            //
            //                }
            //            }
        }
    }
}
