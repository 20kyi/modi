//
//  MODIApp.swift
//  MODI
//
//  Created by 김영임 on 7/8/26.
//

import SwiftData
import SwiftUI

@main
struct MODIApp: App {

    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([MODIRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
