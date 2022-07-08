//
//  SpeedyDiskReducer.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import ComposableArchitecture

func selectVolume(state: inout SpeedyDiskState, volumeId: UUID)  {
    if state.selectedVolumeId != volumeId {
        if state.editAutoCreateVolumes.first(where: {$0.id == volumeId}) != nil {
            state.selectedVolumeId = volumeId
        }
    }
}


let speedyDiskReducer = Reducer<SpeedyDiskState, SpeedyDiskAction, SpeedyDiskEnvironment> { state, action, environment in
    switch action {
        case .binding:
            return .none
            
        case .prepareForEdit:
            state.editAutoCreateVolumes = state.autoCreateVolumes
            return .none
            
        case .foldersChanged(let folders, let volumeId):
            selectVolume(state: &state, volumeId: volumeId)
            guard let selectedVolumeId = state.selectedVolumeId else { return .none }
            state.editAutoCreateVolumes[id: selectedVolumeId]?.folders = folders
            return .none

            
        case .diskSizeChanged(let diskSize, let volumeId):
            selectVolume(state: &state, volumeId: volumeId)
            guard let diskSize = UInt(diskSize), let selectedVolumeId = state.selectedVolumeId else { return .none }
            let minDiskSize = diskSize < 10 ? 10 : diskSize
            
            state.editAutoCreateVolumes[id: selectedVolumeId]?.size = minDiskSize
            return .none
            
        case .recreateVolume(let volumeId):
            selectVolume(state: &state, volumeId: volumeId)
            if let volume = SpeedyDiskManager.shared.getVolume(volumeId: volumeId), let editVolume = state.editAutoCreateVolumes.first(where: {$0.id == volumeId}) {
                SpeedyDiskManager.shared.setDiskSize(volumeId: volumeId, diskSize: editVolume.size)
                SpeedyDiskManager.shared.setAutoCreate(volumeId: volumeId, value: editVolume.autoCreate)
                SpeedyDiskManager.shared.setWarnOnEject(volumeId: volumeId, value: editVolume.warnOnEject)
                SpeedyDiskManager.shared.setSpotLight(volumeId: volumeId, value: editVolume.spotLight)
                SpeedyDiskManager.shared.setFolders(volumeId: volumeId, value: editVolume.folders)
                
                return Effect<SpeedyDiskAction, Never>(value: .ejectSpeedyDisksWithName(names: [volume.name], recreate: true))
            }
            
            return .none
            
        case .toggleSpotLight(let volumeId):
            selectVolume(state: &state, volumeId: volumeId)
            state.editAutoCreateVolumes[id: volumeId]?.spotLight.toggle()

            return .none
            
        case .toggleWarnOnEject(let volumeId):
            selectVolume(state: &state, volumeId: volumeId)
            state.editAutoCreateVolumes[id: volumeId]?.warnOnEject.toggle()
            
            return .none

        case .toggleAutoCreate(let volumeId):
            selectVolume(state: &state, volumeId: volumeId)
            state.editAutoCreateVolumes[id: volumeId]?.autoCreate.toggle()
            return .none
            
        case .diskEjected(let path):
            if let path = path, let volume = SpeedyDiskManager.shared.diskEjected(path: path) {
                return Effect<SpeedyDiskAction, Never>(value: .ejectSpeedyDisksWithName(names: [volume.name], recreate: false))
            }
            return .none
            
        case .ejectSpeedyDisksWithName(let names, let recreate):
            SpeedyDiskManager.shared.ejectSpeedyDisksWithName(names: names, recreate: recreate)
            state.rebuildMenu = true
            return .none
            
        case .openCreateSpeedyDiskWindow:
            state.closeCreateSpeedyDiskWindow = false
            return .none
            
        case .rebuildMenuCompeleted:
            state.rebuildMenu = false
            return .none
            
        case .rebuildMenu:
            state.rebuildMenu = true
            return .none
            
        case .incrementSpeedyDiskSize:
            let exponent = floor(log2((Double(state.getDiskSize))))
            let value = UInt(pow(2, (exponent > 18 ? 18 : exponent) + 1))
            
            state.diskSize = String(value > 0 ? value : 1)
            return .none
            
        case .decrementSpeedyDiskSize:
            let exponent = floor(log2((Double(state.getDiskSize))))
            
            state.diskSize = String(UInt(pow(2, (exponent < 1 ? 1 : exponent) - 1)))
            return .none
            
        case .createSpeedyDisk:
            state.showActivityIndicator = true
            state.rebuildMenu = false
            state.closeCreateSpeedyDiskWindow = false
            let volume = SpeedyDiskVolume(name: state.diskName,
                                          size: state.getDiskSize,
                                          autoCreate: state.autoCreate,
                                          spotLight: state.spotLight,
                                          warnOnEject: state.warnOnEject,
                                          folders: state.folders)
            
            return Effect.future { callback in
                SpeedyDiskManager.shared.createSpeedyDisk(volume: volume) { diskCreateError in
                    callback(.success(diskCreateError))
                }
            }
            .receive(on: RunLoop.main)
            .eraseToEffect()
            .map { status in .createSpeedyDiskStatus(status) }
            
        case .alertDismissedTapped:
            state.alert = nil
            return .none
            
        case .createSpeedyDiskStatus(let status):
            state.showActivityIndicator = false
            
            switch status {
                case .none:
                    state.rebuildMenu = true
                    state.closeCreateSpeedyDiskWindow = true
                    state.reset()
                    return .none
                    
                case .some(let failure):
                    var message: String
                    
                    switch failure {
                        case .noName:
                            message = "Your Speedy Disk must have a name"
                        case .exists:
                            message = "A volume with this name already exists"
                        case .invalidSize:
                            message = "Size must be a number of megabytes > 0"
                        case .failed:
                            message = "Failed to create \(state.diskName)"
                    }
                    
                    state.alert = .init(title: TextState("Speedy Disk Creation Error"), message: TextState(message))
                    
                    return .none
            }
        case .deleteVolume(let volume):
            SpeedyDiskManager.shared.ejectSpeedyDisksWithName(names: [volume.name], recreate: false)
            SpeedyDiskManager.shared.deleteVolume(volume: volume)
            state.rebuildMenu = true
            return .none
    }
}
.binding()
