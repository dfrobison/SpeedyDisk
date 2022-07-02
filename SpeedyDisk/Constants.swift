//
//  Constants.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//
enum SpeedyDiskError: Error {
    case noName
    case exists
    case invalidSize
    case failed
}

struct AppConstants {
    static let drivePathVolumes = "/Volumes"
    static let diskInfoFile = ".speedydisk"
    static let launcherAppId = "com.RobisonSoftwareDevelopment.SpeedyDiskLauncher"
    static let devicePath = "NSDevicePath"
}
