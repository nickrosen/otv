//
//  otvApp.swift
//  otv
//
//  Created by Nick Rosen on 1/13/24.
//

import SwiftUI

@main
struct otvApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
