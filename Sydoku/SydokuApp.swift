//
//  SydokuApp.swift
//  Sydoku
//
//  Created by Wayne Mock on 12/14/25.
//

import SwiftUI
import SwiftData

/// The main entry point for the Sydoku application.
///
/// This app provides a Sudoku game experience with SwiftData persistence
/// for storing game history, statistics, and syncing via CloudKit.
@main
struct SydokuApp: App {
    /// The shared model container for SwiftData persistence with CloudKit sync.
    ///
    /// Configures the data schema and storage location for the app's persistent data.
    /// CloudKit sync is enabled to keep data synchronized across the user's devices.
    /// If the container cannot be created, the app will terminate with a fatal error.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            GameStatistics.self,
            SavedGameState.self,
            UserSettings.self,
        ])
        
        // Enable CloudKit sync with automatic migration
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // CloudKit schema is automatically initialized when using .cloudKitDatabase: .automatic
            // The record types will be created in CloudKit on first sync
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)
    }
}
