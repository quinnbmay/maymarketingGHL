//
//  Jarvis2_0App.swift
//  Jarvis2.0
//
//  Created by Quinn May on 7/25/25.
//

import SwiftUI

@main
struct Jarvis2_0App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
