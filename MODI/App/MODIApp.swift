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

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // 스키마 변경으로 마이그레이션이 실패하면 저장소를 초기화하고 재시도합니다.
            Self.removePersistentStore(for: configuration)
            return try! ModelContainer(for: schema, configurations: [configuration])
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }

    private static func removePersistentStore(for configuration: ModelConfiguration) {
        let url = configuration.url
        let fileManager = FileManager.default
        let relatedURLs = [
            url,
            url.appendingPathExtension("wal"),
            url.appendingPathExtension("shm")
        ]
        for storeURL in relatedURLs where fileManager.fileExists(atPath: storeURL.path) {
            try? fileManager.removeItem(at: storeURL)
        }
    }
}
