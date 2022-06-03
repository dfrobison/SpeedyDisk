//
//  Constants.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

let diskInfoFile = ".speedydisk"

enum SpeedyDiskError: Error {
    case noName
    case exists
    case invalidSize
    case failed
}
