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
    @StateObject private var themeManager = ColorThemeManager.shared
    @StateObject private var labelManager = LabelManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
                .themeAware()
                .onAppear {
                    labelManager.loadLabels(context: persistenceController.container.viewContext)
                    initializeAppData()
                }
        }
    }
    
    private func initializeAppData() {
        let context = persistenceController.container.viewContext
        
        // Initialize built-in task templates if needed
        TaskTemplateManager.shared.initializeBuiltInTemplates(context: context)
    }
}
