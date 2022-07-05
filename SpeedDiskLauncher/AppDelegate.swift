//
//  AppDelegate.swift
//  SpeedyDiskLauncher
//
//  Created by Doug on 7/1/22.
//
import Cocoa
import OSLog

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainAppIdentifier = "com.RobisonSoftwareDevelopment.SpeedyDisk"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainAppIdentifier }.isEmpty
        let logger = Logger(subsystem: "com.RobisonSoftwareDevelopment.SpeedyDiskLauncher", category: "launcher")

        logger.debug("Entered - applicationDidFinishLaunching - isAppRunning = \(isRunning)")
        
        if !isRunning {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.terminate), name: .killLauncher, object: mainAppIdentifier)

            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("SpeedyDisk")

            let newPath = NSString.path(withComponents: components)

            let result = NSWorkspace.shared.launchApplication(newPath)
            
            logger.debug("Launched - (\(result) at location - \(newPath)")

        }
        else {
            logger.debug("Terminated - \(mainAppIdentifier)")
            self.terminate()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @objc func terminate() {
        NSApp.terminate(nil)
    }
}
