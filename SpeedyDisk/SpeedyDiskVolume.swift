//
//  SpeedyDiskVolume.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import Foundation

struct SpeedyDiskVolume: Hashable, Codable {
    var name: String = ""
    var size: UInt = 64
    var autoCreate: Bool = false
    var spotLight: Bool = false
    var warnOnEject: Bool = false
    var folders: [String] = []
    
    func path() -> String {
        "/Volumes/\(name)"
    }
    
    func URL() -> URL {
        return NSURL.fileURL(withPath: self.path())
    }
    
    func dictionary() -> Dictionary<String, Any> {
        return [
            "name": name,
            "size": size,
            "spotLight": spotLight,
            "warnOnEject": warnOnEject,
            "folders": folders
        ]
    }
    
    func showWarning() -> Bool {
        if warnOnEject {
            if let files = try? FileManager.default.contentsOfDirectory(atPath: self.path()) {
                if !files.filter({ ![".DS_Store", "\(diskInfoFile)", ".fseventsd"].contains($0) }).isEmpty {
                    return true
                }
            }
        }
        return false
    }
}

