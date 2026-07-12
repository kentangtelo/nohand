//
//  nohandApp.swift
//  nohand
//
//  Created by peanutcookies on 12/07/26.
//

import SwiftUI
import CoreData

@main
struct nohandApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
