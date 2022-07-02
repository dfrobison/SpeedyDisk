//
//  SpeedyDiskReducer.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import ComposableArchitecture


let speedyDiskReducer = Reducer<SpeedyDiskState, SpeedyDiskAction, SpeedyDiskEnvironment> { state, action, environment in
    
    switch action {
    case .binding:
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
        let exponent = floor(log2((Double(state.diskSize))))
        
        state.diskSize = UInt(pow(2, (exponent > 18 ? 18 : exponent) + 1))
        return .none
        
    case .decrementSpeedyDiskSize:
        let exponent = floor(log2((Double(state.diskSize))))
        
        state.diskSize = UInt(pow(2, (exponent < 1 ? 1 : exponent) - 1))
        return .none
        
    case .createSpeedyDisk:
        state.showActivityIndicator = true
        state.rebuildMenu = false
        state.closeCreateSpeedyDiskWindow = false
        let volume = SpeedyDiskVolume(name: state.diskName,
                                   size: state.diskSize,
                                   autoCreate: state.autoCreate,
                                   spotLight: state.spotLight,
                                   warnOnEject: state.warnOnEject,
                                   folders: state.folders.components(separatedBy: ","))
        
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
            
        case .toggleAutoCreate(let volume):
            SpeedyDiskManager.shared.toggleAutoCreate(volume: volume)
            state.rebuildMenu = true
            return .none
            
        case .toggleWarnOnEject(let volume):
            SpeedyDiskManager.shared.toggleWarnOnEject(volume: volume)
            return .none
            
        case .toggleSpotLight(let volume):
            SpeedyDiskManager.shared.toggleSpotLight(volume: volume)
            return .none
    }
}
.binding()
