//
//  SpeedyDiskReducer.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import ComposableArchitecture

func selectVolume(state: inout SpeedyDiskState, volumeId: UUID) {
    if state.selectedVolumeId != volumeId {
        if let volume = SpeedyDiskManager.shared.getVolume(volumeId: volumeId) {
            state.diskSize = String(volume.size)
            state.folders = volume.folders
            state.autoCreate = volume.autoCreate
            state.spotLight = volume.spotLight
            state.warnOnEject = volume.warnOnEject
            state.selectedVolumeId = volumeId
            state.diskButtonPressed = false
        }
    }
}


let speedyDiskReducer = Reducer<SpeedyDiskState, SpeedyDiskAction, SpeedyDiskEnvironment> { state, action, environment in
    switch action {
        case .binding:
            return .none
            
        case .recreateVolume(let volumeId):
            if let volume = SpeedyDiskManager.shared.getVolume(volumeId: volumeId) {
                SpeedyDiskManager.shared.setDiskSize(volumeId: volumeId, diskSize: state.getDiskSize)
                SpeedyDiskManager.shared.setAutoCreate(volumeId: volumeId, value: state.autoCreate)
                SpeedyDiskManager.shared.setWarnOnEject(volumeId: volumeId, value: state.warnOnEject)
                SpeedyDiskManager.shared.setSpotLight(volumeId: volumeId, value: state.spotLight)
                SpeedyDiskManager.shared.setFolders(volumeId: volumeId, value: state.folders)
                
                return Effect<SpeedyDiskAction, Never>(value: .ejectSpeedyDisksWithName(names: [volume.name], recreate: true))
            }
            
            return .none
            
        case .toggleSpotLight(let volumeId):
            selectVolume(state: &state, volumeId: volumeId)
            state.spotLight.toggle()
            return .none
            
        case .toggleWarnOnEject(let volumeId):
            selectVolume(state: &state, volumeId: volumeId)
            state.warnOnEject.toggle()
            return .none
            
        case .toggleAutoCreate(let volumeId):
            selectVolume(state: &state, volumeId: volumeId)
            state.autoCreate.toggle()
            return .none
            
        case .setButtonState(let keyPath, let value):
            state[keyPath: keyPath] = value
            return .none
            
        case .volumeSelected(let volumeId):
            selectVolume(state: &state, volumeId: volumeId)
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
