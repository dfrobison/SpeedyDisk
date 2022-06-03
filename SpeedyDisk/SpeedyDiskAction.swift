//
//  SpeedyDiskAction.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//
import ComposableArchitecture

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
    case ejectSpeedyDisksWithName(names: [String], recreate: Bool)
    case diskEjected(path: String?)
}
