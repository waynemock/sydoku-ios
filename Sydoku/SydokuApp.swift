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
/// for storing game history and statistics.
@main
struct SydokuApp: App {
    /// The shared model container for SwiftData persistence.
    ///
    /// Configures the data schema and storage location for the app's persistent data.
    /// If the container cannot be created, the app will terminate with a fatal error.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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
