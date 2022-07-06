//
//  SpeedyDiskState.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//
import ComposableArchitecture

struct SpeedyDiskState: Equatable {
    var rebuildMenu = false
    var closeCreateSpeedyDiskWindow = false
    var alert: AlertState<SpeedyDiskAction>?
    var showActivityIndicator = false
    var selectedVolumeId: UUID?
    @BindableState var diskName = ""
    @BindableState var folders = ""
    var diskSize = "64"
    @BindableState var autoCreate = false
    @BindableState var warnOnEject = false
    @BindableState var spotLight = false
    
    var getDiskSize: UInt {
        if let diskSize = UInt(self.diskSize) {
            return diskSize
        }
        return 0
    }
    
    var canCreate: Bool {
        !diskName.trimmingCharacters(in: .whitespaces).isEmpty && getDiskSize > 0
    }
    
    var count: Int {
        SpeedyDiskManager.shared.volumes.count
    }
    
    var volumes: IdentifiedArrayOf<SpeedyDiskVolume> {
        return SpeedyDiskManager.shared.volumes
    }
    
    var autoCreateVolumes: IdentifiedArrayOf<SpeedyDiskVolume> {
        return SpeedyDiskManager.shared.volumes.filter { $0.autoCreate }
    }
    
    mutating func reset() {
        diskName = ""
        folders = ""
        diskSize = "64"
        autoCreate = false
        warnOnEject = false
        spotLight = false
    }
}
