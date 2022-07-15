//
//  SpeedyDiskReducer.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import ComposableArchitecture
import AppKit

let speedyDiskReducer = Reducer<SpeedyDiskState, SpeedyDiskAction, SpeedyDiskEnvironment> { state, action, environment in
    switch action {
        case .binding:
            return .none
            
        case .prepareForEdit:
            state.editVolumes = state.volumes
            return .none
            
        case .foldersChanged(let folders, let volumeId):
            state.editVolumes[id: volumeId]?.folders = folders
            return .none

        case .diskSizeChanged(let diskSize, let volumeId):
            guard let diskSize = UInt(diskSize) else { return .none }
            let minDiskSize = diskSize < 1 ? 1 : diskSize
            
            state.editVolumes[id: volumeId]?.size = minDiskSize
            return .none
            
        case .recreateVolume(let volumeId):
            state.resignFirstResponder = true
            
            if let volume = SpeedyDiskManager.shared.getVolume(volumeId: volumeId), let editVolume = state.editVolumes.first(where: {$0.id == volumeId}) {
                SpeedyDiskManager.shared.setDiskSize(volumeId: volumeId, diskSize: editVolume.size)
                SpeedyDiskManager.shared.setAutoCreate(volumeId: volumeId, value: editVolume.autoCreate)
                SpeedyDiskManager.shared.setWarnOnEject(volumeId: volumeId, value: editVolume.warnOnEject)
                SpeedyDiskManager.shared.setSpotLight(volumeId: volumeId, value: editVolume.spotLight)
                SpeedyDiskManager.shared.setFolders(volumeId: volumeId, value: editVolume.folders)
                
                return Effect<SpeedyDiskAction, Never>(value: .ejectSpeedyDisksWithName(name: volume.name, recreate: true))
            }
            
            return .none
            
        case .toggleSpotLight(let volumeId):
            state.editVolumes[id: volumeId]?.spotLight.toggle()
            guard let volume = state.editVolumes[id: volumeId] else {
                return .none
            }
            SpeedyDiskManager.shared.setSpotLight(volumeId: volumeId, value: volume.spotLight)

            return .none
            
        case .toggleWarnOnEject(let volumeId):
            state.editVolumes[id: volumeId]?.warnOnEject.toggle()
            guard let volume = state.editVolumes[id: volumeId] else {
                return .none
            }
            SpeedyDiskManager.shared.setWarnOnEject(volumeId: volumeId, value: volume.warnOnEject)
            return .none

        case .toggleAutoCreate(let volumeId):
            state.editVolumes[id: volumeId]?.autoCreate.toggle()
            guard let volume = state.editVolumes[id: volumeId] else {
                return .none
            }
            SpeedyDiskManager.shared.setAutoCreate(volumeId: volumeId, value: volume.autoCreate)
            return .none
            
        case .diskEjected(let path):
            if let path = path, let volume = SpeedyDiskManager.shared.diskEjected(path: path) {
                return Effect<SpeedyDiskAction, Never>(value: .ejectSpeedyDisksWithName(name: volume.name, recreate: false))
            }
            return .none
            
        case .volumeEjected(let delete):
            state.volumeBeingEjected = nil
            state.rebuildMenu = true
            return delete ? Effect<SpeedyDiskAction, Never>(value: .volumeDeleted) : .none
            
        case .volumeBusyError:
            state.volumeBeingEjected = nil
            return Effect<SpeedyDiskAction, Never>(value: .cantDeleteVolume)
            
        case .volumeOperationError:
            state.volumeBeingEjected = nil
            state.alert = .init(title: TextState("Speedy Disk Error"), message: TextState("Operation can't be performed"))
            return .none
            
        case .ejectSpeedyDisksWithName(let name, let recreate, let delete):
            if let volumeBeingEject = state.volumeBeingEjected, volumeBeingEject == name {
                return .none
            }
                
            state.volumeBeingEjected = name
            
            return Effect.task {
                do {
                    let result = try await SpeedyDiskManager.shared.ejectSpeedyDisksWithName(name: name, recreate: recreate)
                    
                    switch result {
                        case .ejected:
                            return .volumeEjected(delete: delete)
                        case .noDiskFound, .undefined:
                            return .volumeOperationError
                        case .busy:
                            return .volumeBusyError
                    }
                } catch {
                    return .volumeOperationError
                }
            }
            
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
            state.resignFirstResponder = true
            return .none
            
        case .resignFirstReponderCompleted:
            state.resignFirstResponder = false
            return .none
            
        case .createSpeedyDiskStatus(let status):
            state.showActivityIndicator = false
            
            switch status {
                case .none:
                    state.rebuildMenu = true
                    state.closeCreateSpeedyDiskWindow = true
                    state.reset()
                    state.editVolumes = state.volumes
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
            
        case .volumeDeleted:
            SpeedyDiskManager.shared.volumeDeleted()
            return Effect<SpeedyDiskAction, Never>(value: .prepareForEdit)
            
        case .deleteVolume(let volumeId):
            state.resignFirstResponder = true
            
            guard let volume = SpeedyDiskManager.shared.getVolume(volumeId: volumeId) else {
                return .none
            }
            return Effect<SpeedyDiskAction, Never>(value: .ejectSpeedyDisksWithName(name: volume.name, recreate: false, delete: true))
            
        case .cantDeleteVolume:
            state.alert = .init(title: TextState("Speedy Disk Error"), message: TextState("Disk busy -- operation can't be performed"))
            return .none
            
    }
}
.binding()
