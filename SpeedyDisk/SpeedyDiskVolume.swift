//
//  SpeedyDiskVolume.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//
import Foundation

struct SpeedyDiskVolume: Equatable, Codable, Identifiable {
    let id = UUID()
    var name: String = ""
    var size: UInt = 64
    var autoCreate: Bool = false
    var spotLight: Bool = false
    var warnOnEject: Bool = false
    var folders: String = ""
    
    enum CodingKeys: String, CodingKey {
        case name
        case size
        case autoCreate
        case spotLight
        case warnOnEject
        case folders
    }

    func path() -> String {
        "\(AppConstants.drivePathVolumes)/\(name)"
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
                if !files.filter({ ![Constants.dsStore, "\(AppConstants.diskInfoFile)", Constants.fsEvent].contains($0) }).isEmpty {
                    return true
                }
            }
        }
        return false
    }
}

extension SpeedyDiskVolume {
    struct Constants {
        static let dsStore = ".DS_Store"
        static let fsEvent = ".fseventsd"
    }
}

