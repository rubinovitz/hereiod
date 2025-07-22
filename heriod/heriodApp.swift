//
//  heriodApp.swift
//  heriod
//
//  Created by JB Rubinovitz on 7/21/25.
//

import SwiftUI
import SwiftData
import UserNotifications


@main
struct heriodApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Period.self,
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
            ContentView()
                .onAppear {
                    Task {
                        await NotificationManager.shared.requestPermission()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
