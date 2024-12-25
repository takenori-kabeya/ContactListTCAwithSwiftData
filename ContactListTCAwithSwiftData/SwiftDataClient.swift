//
//  SwiftDataClient.swift
//  ContactListTCAwithSwiftData
//
//  Created by Takenori Kabeya on 2024/12/18.
//

import Foundation
import ComposableArchitecture
import SwiftData


protocol PersistentMapping {
    associatedtype InMemoryType
    
    func extract() -> InMemoryType
    
    func updateFrom(_ inMemoryObject: InMemoryType)
    static func createFrom(_ inMemoryObject: InMemoryType) -> Self
}



@ModelActor
actor TableActor<ModelT> where ModelT : PersistentModel, ModelT : PersistentMapping {
    @MainActor
    func fetchIdentifiers(_ descriptor: FetchDescriptor<ModelT>) throws -> [PersistentIdentifier] {
        return try self.modelContainer.mainContext.fetchIdentifiers(descriptor)
    }
    
    func fetchIdentifiersInBackground(_ descriptor: FetchDescriptor<ModelT>) throws -> [PersistentIdentifier] {
        let context = ModelContext(self.modelContainer)
        return try context.fetchIdentifiers(descriptor)
    }
    
//    @MainActor
//    func fetchModel(_ identifer: PersistentIdentifier) -> ModelT? {
//        return self.modelContainer.mainContext.model(for: identifer) as? ModelT
//    }
//    
//    func fetchModelInBackground(_ identifer: PersistentIdentifier) -> ModelT? {
//        let context = ModelContext(self.modelContainer)
//        return context.model(for: identifer) as? ModelT
//    }
    
    @MainActor
    func fetchIdentifiers(predicate: Predicate<ModelT>, sortBy: [SortDescriptor<ModelT>] = []) throws -> [PersistentIdentifier] {
        let descriptor = FetchDescriptor<ModelT>(predicate: predicate, sortBy: sortBy)
        return try self.fetchIdentifiers(descriptor)
    }
    
    func fetchIdentifiersInBackground(predicate: Predicate<ModelT>, sortBy: [SortDescriptor<ModelT>] = []) throws -> [PersistentIdentifier] {
        let descriptor = FetchDescriptor<ModelT>(predicate: predicate, sortBy: sortBy)
        return try self.fetchIdentifiersInBackground(descriptor)
    }
    
    @MainActor
    func fetchIdentifier(_ descriptor: FetchDescriptor<ModelT>) throws -> PersistentIdentifier? {
        return try self.modelContainer.mainContext.fetchIdentifiers(descriptor).first
    }
    
    func fetchIdentifierInBackground(_ descriptor: FetchDescriptor<ModelT>) throws -> PersistentIdentifier? {
        let context = ModelContext(self.modelContainer)
        return try context.fetchIdentifiers(descriptor).first
    }
    
    @MainActor
    func fetchIdentifier(predicate: Predicate<ModelT>, sortBy: [SortDescriptor<ModelT>] = []) throws -> PersistentIdentifier? {
        let descriptor = FetchDescriptor<ModelT>(predicate: predicate, sortBy: sortBy)
        return try self.fetchIdentifier(descriptor)
    }
    
    func fetchIdentifierInBackground(predicate: Predicate<ModelT>, sortBy: [SortDescriptor<ModelT>] = []) throws -> PersistentIdentifier? {
        let descriptor = FetchDescriptor<ModelT>(predicate: predicate, sortBy: sortBy)
        return try self.fetchIdentifierInBackground(descriptor)
    }
    
    @MainActor
    func fetch(_ descriptor: FetchDescriptor<ModelT>) throws -> [ModelT.InMemoryType] {
        let models = try self.modelContainer.mainContext.fetch(descriptor)
        return models.map { $0.extract() }
    }
    
    func fetchInBackground(_ descriptor: FetchDescriptor<ModelT>) throws -> [ModelT.InMemoryType] {
        let context = ModelContext(self.modelContainer)
        let models = try context.fetch(descriptor)
        return models.map { $0.extract() }
    }
    
    @MainActor
    func fetch(predicate: Predicate<ModelT>? = nil, sortBy: [SortDescriptor<ModelT>] = []) throws -> [ModelT.InMemoryType] {
        let descriptor = FetchDescriptor<ModelT>(predicate: predicate, sortBy: sortBy)
        return try self.fetch(descriptor)
    }
    
    func fetchInBackground(predicate: Predicate<ModelT>? = nil, sortBy: [SortDescriptor<ModelT>] = []) throws -> [ModelT.InMemoryType] {
        let descriptor = FetchDescriptor<ModelT>(predicate: predicate, sortBy: sortBy)
        return try self.fetchInBackground(descriptor)
    }
    
    @MainActor
    func fetchCount(_ descriptor: FetchDescriptor<ModelT>) throws -> Int {
        return try self.modelContainer.mainContext.fetchCount(descriptor)
    }
    
    func fetchCountInBackground(_ descriptor: FetchDescriptor<ModelT>) throws -> Int {
        let context = ModelContext(self.modelContainer)
        return try context.fetchCount(descriptor)
    }
    
    @MainActor
    func fetchCount(predicate: Predicate<ModelT>? = nil, sortBy: [SortDescriptor<ModelT>] = []) throws -> Int {
        let descriptor = FetchDescriptor<ModelT>(predicate: predicate, sortBy: sortBy)
        return try self.fetchCount(descriptor)
    }
    
    func fetchCountInBackground(predicate: Predicate<ModelT>? = nil, sortBy: [SortDescriptor<ModelT>] = []) throws -> Int {
        let descriptor = FetchDescriptor<ModelT>(predicate: predicate, sortBy: sortBy)
        return try self.fetchCountInBackground(descriptor)
    }
    
    @MainActor
    func insert(_ inMemoryObject: ModelT.InMemoryType, forceSave: Bool = false) throws -> Void {
        let modelObject = ModelT.createFrom(inMemoryObject)
        self.modelContainer.mainContext.insert(modelObject)
        if forceSave {
            print("SAVE! insert")
            try self.modelContainer.mainContext.save()
        }
    }
    
    func insertInBackground(_ inMemoryObject: ModelT.InMemoryType, forceSave: Bool = false) throws -> Void {
        let modelObject = ModelT.createFrom(inMemoryObject)
        let context = ModelContext(self.modelContainer)
        context.insert(modelObject)
        if forceSave {
            try context.save()
        }
    }
    
    @MainActor
    func update(id: PersistentIdentifier, _ inMemoryObject: ModelT.InMemoryType, forceSave: Bool = false) throws -> Void {
        guard let modelObject = self.modelContainer.mainContext.model(for: id) as? ModelT else {
            return
        }
        modelObject.updateFrom(inMemoryObject)
        if forceSave {
            try self.modelContainer.mainContext.save()
        }
    }
    
    func updateInBackground(id: PersistentIdentifier, _ inMemoryObject: ModelT.InMemoryType, forceSave: Bool = false) throws -> Void {
        let context = ModelContext(self.modelContainer)
        guard let modelObject = context.model(for: id) as? ModelT else {
            return
        }
        modelObject.updateFrom(inMemoryObject)
        if forceSave {
            try context.save()
        }
    }
    
    @MainActor
    func upsert(_ descriptor: FetchDescriptor<ModelT>, _ inMemoryObject: ModelT.InMemoryType, forceSave: Bool = false) throws -> Void {
        if let modelObject = try self.modelContainer.mainContext.fetch(descriptor).first {
            modelObject.updateFrom(inMemoryObject)
            if forceSave {
                try self.modelContainer.mainContext.save()
            }
        }
        else {
            try insert(inMemoryObject, forceSave: forceSave)
        }
    }
    
    func upsertInBackground(_ descriptor: FetchDescriptor<ModelT>, _ inMemoryObject: ModelT.InMemoryType, forceSave: Bool = false) throws -> Void {
        let context = ModelContext(self.modelContainer)
        if let modelObject = try context.fetch(descriptor).first {
            modelObject.updateFrom(inMemoryObject)
            if forceSave {
                try context.save()
            }
        }
        else {
            let modelObject = ModelT.createFrom(inMemoryObject)
            context.insert(modelObject)
            if forceSave {
                try context.save()
            }
        }
    }
    
    
    @MainActor
    func upsert(predicate: Predicate<ModelT>, sortBy: [SortDescriptor<ModelT>] = [], _ inMemoryObject: ModelT.InMemoryType, forceSave: Bool = false) throws -> Void {
        let descriptor = FetchDescriptor<ModelT>(predicate: predicate, sortBy: sortBy)
        try upsert(descriptor, inMemoryObject, forceSave: forceSave)
    }
    
    func upsertInBackground(predicate: Predicate<ModelT>, sortBy: [SortDescriptor<ModelT>] = [], _ inMemoryObject: ModelT.InMemoryType, forceSave: Bool = false) throws -> Void {
        let descriptor = FetchDescriptor<ModelT>(predicate: predicate, sortBy: sortBy)
        try upsertInBackground(descriptor, inMemoryObject, forceSave: forceSave)
    }
    
    @MainActor
    func delete(id: PersistentIdentifier, forceSave: Bool = false) throws -> Void {
        let modelObject = self.modelContainer.mainContext.model(for: id)
        self.modelContainer.mainContext.delete(modelObject)
        if forceSave {
            try self.modelContainer.mainContext.save()
        }
    }
    
    func deleteInBackground(id: PersistentIdentifier, forceSave: Bool = false) throws -> Void {
        let context = ModelContext(self.modelContainer)
        let modelObject = context.model(for: id)
        context.delete(modelObject)
        if forceSave {
            try context.save()
        }
    }
    
    @MainActor
    func save() throws -> Void {
        try self.modelContainer.mainContext.save()
    }
    
    func saveInBackground() throws -> Void {
        let context = ModelContext(self.modelContainer)
        try context.save()
    }
}




extension TableActor where ModelT == PersistentContact {
    @MainActor
    func updateWithChild(id: PersistentIdentifier, _ inMemoryObject: ModelT.InMemoryType, forceSave: Bool = false) throws -> Void {
        guard let modelObject = self.modelContainer.mainContext.model(for: id) as? ModelT else {
            return
        }
        var persistentPhoneNumbers: [PersistentPhoneNumber] = []
        let existents = try self.modelContainer.mainContext.fetch(FetchDescriptor<PersistentPhoneNumber>())
        
        for phoneNumber in inMemoryObject.phoneNumbers {
            if let persistentPhoneNumber = existents.first(where: { $0.stateId == phoneNumber.id }) {
                persistentPhoneNumber.phoneType = phoneNumber.phoneType
                persistentPhoneNumber.number = phoneNumber.number
                persistentPhoneNumber.sequenceNo = phoneNumber.sequenceNo
                
                persistentPhoneNumbers.append(persistentPhoneNumber)
            }
            else {
                let persistentPhoneNumber = PersistentPhoneNumber(stateId: phoneNumber.id, phoneType: phoneNumber.phoneType, number: phoneNumber.number, sequenceNo: phoneNumber.sequenceNo)
                self.modelContainer.mainContext.insert(persistentPhoneNumber)
                
                persistentPhoneNumbers.append(persistentPhoneNumber)
            }
        }
        try self.modelContainer.mainContext.save()
        
        modelObject.stateId = inMemoryObject.id
        modelObject.name = inMemoryObject.name
        modelObject.sequenceNo = inMemoryObject.sequenceNo
        modelObject.phoneNumbers = persistentPhoneNumbers
        
        try self.modelContainer.mainContext.save()
    }
}



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
