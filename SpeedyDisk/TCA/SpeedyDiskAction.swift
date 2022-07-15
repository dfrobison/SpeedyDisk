//
//  SpeedyDiskAction.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//
import ComposableArchitecture
import Foundation

enum SpeedyDiskAction: BindableAction, Equatable {
    case binding(BindingAction<SpeedyDiskState>)
    case incrementSpeedyDiskSize
    case decrementSpeedyDiskSize
    case createSpeedyDisk
    case createSpeedyDiskStatus(SpeedyDiskError?)
    case alertDismissedTapped
    case rebuildMenuCompeleted
    case rebuildMenu
    case openCreateSpeedyDiskWindow
    case ejectSpeedyDisksWithName(name: String, recreate: Bool, delete: Bool = false)
    case diskEjected(path: String?)
    case deleteVolume(volumeId: UUID)
    case volumeDeleted
    case recreateVolume(volumeId: UUID)
    case toggleAutoCreate(volumeId: UUID)
    case toggleWarnOnEject(volumeId: UUID)
    case toggleSpotLight(volumeId: UUID)
    case prepareForEdit
    case diskSizeChanged(String, UUID)
    case foldersChanged(String, UUID)
    case cantDeleteVolume
    case resignFirstReponderCompleted
    case volumeEjected(delete: Bool)
    case volumeBusyError
    case volumeOperationError
    
}
