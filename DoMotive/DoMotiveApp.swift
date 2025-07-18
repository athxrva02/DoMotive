//
//  DoMotiveApp.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI

@main
struct DoMotiveApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
