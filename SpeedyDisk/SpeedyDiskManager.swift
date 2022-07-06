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
    
    var autoCreateVolumes: [SpeedyDiskVolume] {
        self.volumes.filter { volume in
            volume.autoCreate
        }
    }
    
    private init() {
        // Check for existing SpeedyDisks
        if let vols = try? FileManager.default.contentsOfDirectory(atPath: AppConstants.drivePathVolumes) {
            for vol in vols {
                let speedydiskFilePath = "\(AppConstants.drivePathVolumes)/\(vol)/\(AppConstants.diskInfoFile)"
                if FileManager.default.fileExists(atPath: speedydiskFilePath) {
                    if let jsonData = FileManager.default.contents(atPath: speedydiskFilePath) {
                        if let volume = try? JSONDecoder().decode(SpeedyDiskVolume.self, from: jsonData) {
                            self.volumes.append(volume)
                        }
                    }
                }
            }
            
            if !volumes.isEmpty {
                volumes.sort(by: \.name)
            }
        }
        
        // AutoCreate any saved SpeedyDisks
        restoreAutoCreateVolumes()
    }
    
    // MARK: - SpeedyDiskManager API
    func getVolume(volumeId: UUID) -> SpeedyDiskVolume? {
        volumes.first(where: {$0.id == volumeId})
    }
    
    func restoreAutoCreateVolumes() {
        if let autoCreate = UserDefaults.standard.object(forKey: Constants.autoCreate) as? [Dictionary<String, Any>] {
            for vol in autoCreate {
                if let name = vol["name"] as? String, let size = vol["size"] as? UInt, let spotLight = vol["spotLight"] as? Bool {
                    if !self.volumes.contains(where: {$0.name == name}) {
                        let warnOnEject = vol["warnOnEject"] as? Bool ?? false
                        let folders = vol["folders"] as? [String] ?? []
                        let volume = SpeedyDiskVolume(name: name,
                                                      size: size,
                                                      autoCreate: true,
                                                      spotLight: spotLight,
                                                      warnOnEject: warnOnEject,
                                                      folders: folders)
                        self.createSpeedyDisk(volume: volume) { _ in }
                    }
                }
            }
        }
    }
    
    func setDiskSize(volumeId: UUID, diskSize: UInt) {
        self.volumes[id: volumeId]?.size = diskSize
    }

    
    func toggleWarnOnEject(volume: SpeedyDiskVolume) {
        self.volumes[id: volume.id]?.warnOnEject.toggle()
    }
    
    func toggleSpotLight(volume: SpeedyDiskVolume) {
        self.volumes[id: volume.id]?.spotLight.toggle()
    }
    
    func toggleAutoCreate(volume: SpeedyDiskVolume) {
        self.volumes[id: volume.id]?.autoCreate.toggle()
        self.saveAutoCreateVolumes()
    }
    
    func deleteVolume(volume: SpeedyDiskVolume) {
        self.volumes.remove(volume)
        self.saveAutoCreateVolumes()
    }
    
    func saveAutoCreateVolumes() {
        UserDefaults.standard.set(autoCreateVolumes.map { $0.dictionary() },
                                  forKey: Constants.autoCreate)
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
            
            self.volumes.append(volume)
            self.volumes.sort(by: \.name)
            self.createFolders(volume: volume)

            if let jsonData = try? JSONEncoder().encode(volume) {
                let jsonString = String(data: jsonData, encoding: .utf8)!
                try? jsonString.write(toFile: "\(volume.path())/\(AppConstants.diskInfoFile)", atomically: true, encoding: .utf8)
            }
            
            if volume.spotLight {
                self.indexVolume(volume: volume)
            }
            
            if volume.autoCreate {
                self.saveAutoCreateVolumes()
            }
            
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
        self.ejectSpeedyDisksWithName(names: self.volumes.map( \.name ),
                                      recreate: recreate)
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
    func diskEjected(path: String) -> SpeedyDiskVolume? {
        for volume in self.volumes {
            if volume.path() == path {
                return volume
            }
        }
        
        return nil
    }
    
    // MARK: - Helper functions
    func createSpeedyDisk(volume: SpeedyDiskVolume) -> Process {
        let task = Process()
        let diskSize = volume.size * 2048
        let command = "diskutil partitionDisk `hdiutil attach -nomount ram://\(diskSize)` 1 GPTFormat APFS \"\(volume.name)\" \"100%\""
        
        task.arguments = ["-c", command]
        task.launchPath = Constants.shell

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
        task.launchPath = Constants.shell
        
        let command = "mdutil -i on \(volume.path())"
        task.arguments = ["-c", command]
        task.launch()
    }
    
    func exists(volume: SpeedyDiskVolume) -> Bool {
        FileManager.default.fileExists(atPath: volume.path())
    }
}

extension SpeedyDiskManager {
    struct Constants {
        static let shell = "/bin/zsh"
        static let autoCreate = "autoCreate"
    }
}
