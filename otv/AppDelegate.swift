//
//  AppDelegate.swift
//  otv
//
//  Created by Nick Rosen on 2/10/24.
//

import UIKit
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.otv.PlaylistProcessor", using: nil) { task in
            // Ensure you run this part on the main thread if your task requires it
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        return true
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Use Task.init to bridge between BGTask's completion handler and async code
        Task {
//            await PlaylistProcessor.shared.startProcessing()
            PlaylistProcessor.shared.startProcessing { success in
                // Handle completion
                print("Doooone")
//                DispatchQueue.main.async {
//                    // Ensure you're on the main thread if you're updating any UI components
//                    self.done = true
//                }
            }
            task.setTaskCompleted(success: true) // Assuming success for simplicity
        }
        
        scheduleAppRefresh() // Consider scheduling the next refresh after completion if needed
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.otv.PlaylistProcessor")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60) // Adjust timing as needed
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}


