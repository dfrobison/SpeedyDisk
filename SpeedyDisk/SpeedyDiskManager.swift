//
//  SpeedyDiskManager.swift
//  SpeedyDisk
//
//  Created by Doug on 6/2/22.
//

import Foundation
import AppKit
import IdentifiedCollections

class SpeedyDiskManager {
    
    static let shared: SpeedyDiskManager = SpeedyDiskManager()
    var volumes: IdentifiedArrayOf<SpeedyDiskVolume> = []
    
    private init() {
        // Check for existing SpeedyDisks
        if let vols = try? FileManager.default.contentsOfDirectory(atPath: "/Volumes") {
            for vol in vols {
                let speedydiskFilePath = "/Volumes/\(vol)/\(diskInfoFile)"
                if FileManager.default.fileExists(atPath: speedydiskFilePath) {
                    if let jsonData = FileManager.default.contents(atPath: speedydiskFilePath) {
                        if let volume = try? JSONDecoder().decode(SpeedyDiskVolume.self, from: jsonData) {
                            self.volumes.append(volume)
                        }
                    }
                }
            }
        }
        
        // AutoCreate any saved SpeedyDisks
        for volume in self.getAutoCreateVolumes() {
            self.createSpeedyDisk(volume: volume) { _ in }
        }
        
        volumes.sort(by: \.name)
    }
    
    // MARK: - SpeedyDiskManager API
    
    func getAutoCreateVolumes() -> [SpeedyDiskVolume] {
        var autoCreateVolumes: [SpeedyDiskVolume] = []
        if let autoCreate = UserDefaults.standard.object(forKey: "autoCreate") as? [Dictionary<String, Any>] {
            for vol in autoCreate {
                if let name = vol["name"] as? String, let size = vol["size"] as? UInt, let spotLight = vol["spotLight"] as? Bool {
                    
                    let warnOnEject = vol["warnOnEject"] as? Bool ?? false
                    let folders = vol["folders"] as? [String] ?? []
                    
                    let volume = SpeedyDiskVolume(name: name,
                                               size: size,
                                               spotLight: spotLight,
                                               warnOnEject: warnOnEject,
                                               folders: folders)
                    autoCreateVolumes.append(volume)
                }
            }
        }
        
        return autoCreateVolumes
    }
    
    func addAutoCreateVolume(volume: SpeedyDiskVolume) {
        var autoCreateVolumes = self.getAutoCreateVolumes()
        autoCreateVolumes.append(volume)
        self.saveAutoCreateVolumes(volumes: autoCreateVolumes)
    }
    
    func saveAutoCreateVolumes(volumes: [SpeedyDiskVolume]) {
        let value = volumes.map { $0.dictionary() }
        UserDefaults.standard.set(value, forKey: "autoCreate")
    }
    
    func createSpeedyDisk(volume: SpeedyDiskVolume, onCreate: @escaping (SpeedyDiskError?) -> Void) {
        if volume.name.isEmpty  {
            return onCreate(.noName)
        }
        
        if volume.size <= 0 {
            return onCreate(.invalidSize)
        }
        
        if volumes.contains(where: { $0.name == volume.name }) || self.exists(volume: volume) {
            return onCreate(.exists)
        }
        
        let task: Process?
        task = self.createSpeedyDisk(volume: volume)
        
        guard let task = task else {
            return onCreate(.failed)
        }
        
        task.terminationHandler = { process in
            if process.terminationStatus != 0 {
                return onCreate(.failed)
            }
            
            if let jsonData = try? JSONEncoder().encode(volume) {
                let jsonString = String(data: jsonData, encoding: .utf8)!
                try? jsonString.write(toFile: "\(volume.path())/\(diskInfoFile)", atomically: true, encoding: .utf8)
            }
            
            if volume.spotLight {
                self.indexVolume(volume: volume)
            }
            
            self.createFolders(volume: volume)
            
            if volume.autoCreate {
                self.addAutoCreateVolume(volume: volume)
            }
            
            self.volumes.append(volume)
            self.volumes.sort(by: \.name)
            NotificationCenter.default.post(name: .speedyDiskMounted, object: nil)
            onCreate(nil)
        }
        do {
            try task.run()
        } catch {
            print(error)
        }
    }
    
    func ejectAllSpeedyDisks(recreate: Bool) {
        let names = self.volumes.map( \.name )
        self.ejectSpeedyDisksWithName(names: names, recreate: recreate)
    }
    
    func ejectSpeedyDisksWithName(names: [String], recreate: Bool) {
        let group = DispatchGroup()
        let unmountVolumes = volumes.filter({ names.contains($0.name) })
        
        // There are potential race conditions. Deleting cameras first from
        // master list
        unmountVolumes.forEach {volume in
            volumes.remove(volume)
        }
        
        for volume in unmountVolumes {
            group.enter()
            
            let ws = NSWorkspace()
            do {
                try ws.unmountAndEjectDevice(at: volume.URL())
            } catch {
                print(error)
            }
            
            if recreate {
                createSpeedyDisk(volume: volume, onCreate: {_ in })
            }
            
            group.leave()
        }
    }
    
    /*
     diskEjected takes a path and checks to see if it's a SpeedyDisk
     If it is, remove it from the volumes and return true so we can refresh the menubar
     */
    func diskEjected(path: String) -> Bool {
        for volume in self.volumes {
            if volume.path() == path {
                self.volumes.remove(volume)
                return true
            }
        }
        return false
    }
    
    // MARK: - Helper functions
    func createSpeedyDisk(volume: SpeedyDiskVolume) -> Process {
        let task = Process()
        task.launchPath = "/bin/zsh"
        
        let dSize = UInt64(volume.size) * 2048
        
        let command: String
        
        //command = "diskutil eraseVolume HFS+ \"\(volume.name)\" `hdiutil attach -nomount ram://\(dSize)`"
        command = "diskutil partitionDisk `hdiutil attach -nomount ram://\(dSize)` 1 GPTFormat APFS \"\(volume.name)\" \"100%\""
        
        print(command)
        
        task.arguments = ["-c", command]
        return task
    }
    
    func createFolders(volume: SpeedyDiskVolume) {
        for folder in volume.folders {
            let path = "\(volume.path())/\(folder)"
            if !FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }
    
    func indexVolume(volume: SpeedyDiskVolume) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        
        let command = "mdutil -i on \(volume.path())"
        task.arguments = ["-c", command]
        task.launch()
    }
    
    func exists(volume: SpeedyDiskVolume) -> Bool {
        FileManager.default.fileExists(atPath: volume.path())
    }
}

extension Sequence {
    func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return map { $0[keyPath: keyPath] }
    }
}

extension IdentifiedArray {
    mutating func sort<T: Comparable>(by keyPath: KeyPath<Element, T>) {
        return sort { a, b in
            return a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
}
