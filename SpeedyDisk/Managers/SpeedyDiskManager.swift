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
    let lock = NSLock()
    var volumes: IdentifiedArrayOf<SpeedyDiskVolume> = []
    enum Eject {
        case noDiskFound
        case ejected
        case busy
        case undefined
    }
    
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
    func contains(volumeId: UUID) -> Bool {
        self.volumes.contains(where: {volumeId == $0.id})
    }
    
    func getVolume(volumeId: UUID) -> SpeedyDiskVolume? {
        volumes.first(where: {$0.id == volumeId})
    }
    
    func getVolume(name: String) -> SpeedyDiskVolume? {
        volumes.first(where: {$0.name == name})
    }

    
    func restoreAutoCreateVolumes() {
        if let autoCreate = UserDefaults.standard.object(forKey: Constants.autoCreate) as? [Dictionary<String, Any>] {
            for vol in autoCreate {
                if let name = vol["name"] as? String, let size = vol["size"] as? UInt, let spotLight = vol["spotLight"] as? Bool {
                    if !self.volumes.contains(where: {$0.name == name}) {
                        let warnOnEject = vol["warnOnEject"] as? Bool ?? false
                        let folders = vol["folders"] as? String ?? ""
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
    
    func setFolders(volumeId: UUID, value: String) {
        self.volumes[id: volumeId]?.folders = value
    }
    
    func setDiskSize(volumeId: UUID, diskSize: UInt) {
        self.volumes[id: volumeId]?.size = diskSize
    }
    
    func setWarnOnEject(volumeId: UUID, value: Bool) {
        self.volumes[id: volumeId]?.warnOnEject = value
    }
    
    func setSpotLight(volumeId: UUID, value: Bool) {
        self.volumes[id: volumeId]?.spotLight = value
        self.indexVolume(volume: self.volumes[id: volumeId], state: value)
    }
    
    func setAutoCreate(volumeId: UUID, value: Bool) {
        self.volumes[id: volumeId]?.autoCreate = value
        self.saveAutoCreateVolumes()
    }
    
    func deleteVolume(volume: SpeedyDiskVolume) {
        self.volumes.remove(volume)
        self.volumeDeleted()
    }
    
    func volumeDeleted() {
        self.saveAutoCreateVolumes()
    }
    
    private func saveAutoCreateVolumes() {
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
            
            self.lock.lock()
            self.volumes.append(volume)
            self.volumes.sort(by: \.name)
            self.lock.unlock()
            
            self.createFolders(volume: volume)
            
            if let jsonData = try? JSONEncoder().encode(volume) {
                let jsonString = String(data: jsonData, encoding: .utf8)!
                try? jsonString.write(toFile: "\(volume.path())/\(AppConstants.diskInfoFile)", atomically: true, encoding: .utf8)
            }
            
            if volume.spotLight {
                self.indexVolume(volume: volume, state: true)
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
    
    func ejectSpeedyDisksWithName(name: String, recreate: Bool, completion: @escaping (Result<Eject, Error>) -> Void) {
        guard let volume = self.getVolume(name: name) else {
            completion(.success(.noDiskFound))
            return
        }
        
        Task {
            let unmountTask = Task.detached(
                priority: .userInitiated,
                operation: { [volume] in
                    try NSWorkspace().unmountAndEjectDevice(at: volume.URL())
                }
            )
            
            let volumeEjected = {
                self.lock.lock()
                self.volumes.remove(id: volume.id)
                self.lock.unlock()
                
                if recreate {
                    self.createSpeedyDisk(volume: volume, onCreate: {_ in })
                }
                completion(.success(.ejected))
            }
            
            do {
                try await unmountTask.value
                volumeEjected()
            } catch {
                if error.localizedDescription.contains("-47") {
                    completion(.success(.busy))
                } else {
                    completion(.success(.undefined))
                }
            }
            
        }
    }
    
    func ejectSpeedyDisksWithName(name: String, recreate: Bool) async throws -> Eject {
        return try await withCheckedThrowingContinuation { continuation in
            ejectSpeedyDisksWithName(name: name, recreate: recreate) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /*
     diskEjected takes a path and checks to see if it's a SpeedyDisk
     If it is, remove it from the volumes and return
     */
    func diskEjected(path: String) -> SpeedyDiskVolume? {
        guard let volume = self.volumes.first(where: {$0.path() == path}) else {
            return nil
        }
        
        self.lock.lock()
        self.volumes.remove(volume)
        self.lock.unlock()
        return volume
    }
    
    // MARK: - Helper functions
    func createSpeedyDisk(volume: SpeedyDiskVolume) -> Process {
        let task = Process()
        let diskSize = volume.size * 2048
        //let command = "diskutil partitionDisk `hdiutil attach -nomount ram://\(diskSize)` 1 GPTFormat APFS \"\(volume.name)\" \"100%\""
        let command = "diskutil eraseVolume HFS+ \"\(volume.name)\" `hdiutil attach -nomount ram://\(diskSize)`"
        task.arguments = ["-c", command]
        task.launchPath = Constants.shell
        
        return task
    }
    
    func createFolders(volume: SpeedyDiskVolume) {
        for folder in volume.folders.components(separatedBy: ",") {
            let path = "\(volume.path())/\(folder)"
            if !FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }
    
    func indexVolume(volume: SpeedyDiskVolume?, state: Bool) {
        guard let volume = volume else {
            return
        }

        let task = Process()
        task.launchPath = Constants.shell
        
        let command = "mdutil -i \(state ? "on" : "off") \(volume.path())"
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
