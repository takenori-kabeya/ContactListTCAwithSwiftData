//
//  SwiftDataClient.swift
//  ContactListTCAwithSwiftData
//
//  Created by Takenori Kabeya on 2024/12/18.
//

import Foundation
import ComposableArchitecture
import SwiftData



func createModelContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
    let schema = Schema([
        PersistentContact.self,
        PersistentPhoneNumber.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    catch {
        fatalError("Could not create ModelContainer: \(error.localizedDescription)")
    }
}

let liveModelContainer: ModelContainer = {
    return createModelContainer(isStoredInMemoryOnly: false)
}()

let testModelContainer: ModelContainer = {
    return createModelContainer(isStoredInMemoryOnly: true)
}()



extension DependencyValues {
    var swiftDataClient: SwiftDataClient {
        get { self[SwiftDataClient.self] }
        set { self[SwiftDataClient.self] = newValue }
    }
}

struct SwiftDataClient {
    var contacts: TableActor<PersistentContact>
    var phoneNumbers: TableActor<PersistentPhoneNumber>
}

extension SwiftDataClient: DependencyKey {
    static func createValue(modelContainer: ModelContainer) -> Self {
        return Self(contacts:TableActor<PersistentContact>(modelContainer: modelContainer),
                    phoneNumbers: TableActor<PersistentPhoneNumber>(modelContainer: modelContainer))
    }
    
    static let liveValue = createValue(modelContainer: liveModelContainer)
    static let testValue = createValue(modelContainer: testModelContainer)
    static let previewValue = createValue(modelContainer: testModelContainer)
}
