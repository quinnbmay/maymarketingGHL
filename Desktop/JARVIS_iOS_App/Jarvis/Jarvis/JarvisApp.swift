//
//  JarvisApp.swift
//  Jarvis
//
//  Created by Quinn May on 7/25/25.
//

import SwiftUI

@main
struct JarvisApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
