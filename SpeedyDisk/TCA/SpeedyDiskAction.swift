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
    case openCreateSpeedyDiskWindow
    case ejectSpeedyDisk(volumeId: UUID, recreate: Bool, delete: Bool = false)
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
    case volumeEjected(delete: Bool, volumeId: UUID?)
    case volumeBusyError
    case volumeOperationError
    case prepareToShowSpeedyDiskManagerWindow
    case speedyDiskMounted
    case confirmEjection(volumeId: UUID)
    case confirmEjectTapped(volumeId: UUID)
    case confirmDeletion(volumeId: UUID)
    case confirmDeletionTapped(volumeId: UUID)
    case confirmRecreation(volumeId: UUID)
    case confirmRecreationTapped(volumeId: UUID)

}
