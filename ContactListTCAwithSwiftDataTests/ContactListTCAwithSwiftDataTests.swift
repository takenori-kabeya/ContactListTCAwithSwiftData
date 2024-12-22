//
//  ContactListTCAwithSwiftDataTests.swift
//  ContactListTCAwithSwiftDataTests
//
//  Created by Takenori Kabeya on 2024/12/18.
//

import Foundation
import Testing
import ComposableArchitecture
import SwiftData
@testable import ContactListTCAwithSwiftData



struct ContactListTCAwithSwiftDataTests {
    @Test
    func addFlow() async throws {
        let store = await TestStore(initialState: ContactsFeature.State()) {
            ContactsFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.context = .test
        }
        
        @Dependency(\.uuid) var uuid
        @Dependency(\.swiftDataClient) var client
        
        let name = "Rocky Balbore"
        let id = UUID(0)
        let sequenceNo1 = 0
        let sequenceNo2 = sequenceNo1 + 1
        
        await store.send(.addButtonTapped) {
            $0.addContact = ContactFeature.State(id: id, name: "", sequenceNo: sequenceNo1)
        }
        await store.send(\.addContact.setName, name) {
            $0.addContact?.name = name
        }
        await store.send(\.addContact.saveButtonTapped)
        await store.receive(\.addContact.delegate.saveContact, ContactFeature.State(id: id, name: name, sequenceNo: sequenceNo1))
        await store.receive(\.addContact.dismiss) {
            $0.addContact = nil
        }
        
        let savedIdentifier = try await client.contacts.fetchIdentifier(predicate: #Predicate { $0.id == id })
        #expect(savedIdentifier != nil)
        let savedContact = try await client.contacts.fetch(predicate: #Predicate { $0.id == id }).first
        #expect(savedContact?.id == id)
        #expect(savedContact?.name == name)
        await store.receive(\.didAdd, ContactFeature.State(id: id, name: name, sequenceNo: sequenceNo1)) {
            $0.contacts = [ContactFeature.State(id: id, name: name, sequenceNo: sequenceNo1)]
            $0.nextSequenceNo = sequenceNo2
        }
    }
    
    @Test
    func deleteFlow() async throws {
        let store = await TestStore(initialState: ContactsFeature.State()) {
            ContactsFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.context = .test
        }
        
        @Dependency(\.uuid) var uuid
        @Dependency(\.swiftDataClient) var client
        
        let name1 = "Rocky Balbore"
        let name2 = "Apollo Creed"
        let id1 = UUID(0)
        let id2 = UUID(1)
        let sequenceNo1 = 0
        let sequenceNo2 = 3
        let sequenceNo3 = sequenceNo2 + 1
        
        let context = ModelContext(testModelContainer)
        try context.delete(model: PersistentContact.self)
        context.insert(PersistentContact(id: id1, name: name1, sequenceNo: sequenceNo1))
        context.insert(PersistentContact(id: id2, name: name2, sequenceNo: sequenceNo2))
        try context.save()
        
        await store.send(.onAppear)
        await store.receive(\.didLoad) {
            let contact1 = ContactFeature.State(id: id1, name: name1, sequenceNo: sequenceNo1)
            let contact2 = ContactFeature.State(id: id2, name: name2, sequenceNo: sequenceNo2)
            $0.contacts = [contact1, contact2]
            $0.nextSequenceNo = sequenceNo3
        }
        
        await store.send(.deleteButtonTapped(id: id2)) {
            $0.alert = AlertState.deleteConfirmation(id: id2)
        }
        await store.send(.alert(.presented(.confirmDeletion(id: id2)))) {
            $0.alert = nil
        }
        await store.receive(\.deleteContact)
        let savedIdentifier = try await client.contacts.fetchIdentifier(predicate: #Predicate { $0.id == id2 })
        #expect(savedIdentifier == nil)
        await store.receive(\.didDelete) {
            let contact1 = ContactFeature.State(id: id1, name: name1, sequenceNo: sequenceNo1)
            $0.contacts = [contact1]
            $0.nextSequenceNo = sequenceNo3
        }
    }
    
    @Test
    func editFlow() async throws {
        let store = await TestStore(initialState: ContactsFeature.State()) {
            ContactsFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.context = .test
        }
        
        @Dependency(\.uuid) var uuid
        @Dependency(\.swiftDataClient) var client
        
        let name1 = "Rocky Balbore"
        let name2 = "Apollo Creed"
        let name3 = "Robert \"Rocky\" Balboa"
        
        let id1 = UUID(0)
        let id2 = UUID(1)
        
        let sequenceNo1 = 0
        let sequenceNo2 = 3
        let sequenceNo3 = sequenceNo2 + 1
        
        let context = ModelContext(testModelContainer)
        try context.delete(model: PersistentContact.self)
        context.insert(PersistentContact(id: id1, name: name1, sequenceNo: sequenceNo1))
        context.insert(PersistentContact(id: id2, name: name2, sequenceNo: sequenceNo2))
        try context.save()
        
        await store.send(.onAppear)
        await store.receive(\.didLoad) {
            let contact1 = ContactFeature.State(id: id1, name: name1, sequenceNo: sequenceNo1)
            let contact2 = ContactFeature.State(id: id2, name: name2, sequenceNo: sequenceNo2)
            $0.contacts = [contact1, contact2]
            $0.nextSequenceNo = sequenceNo3
        }
        
        await store.send(.editButtonTapped(id: id1)) {
            $0.editContact = ContactFeature.State(id: id1, name: name1, sequenceNo: sequenceNo1)
        }
        await store.send(\.editContact.setName, name3) {
            $0.editContact?.name = name3
        }
        await store.send(\.editContact.saveButtonTapped)
        await store.receive(\.editContact.delegate.saveContact, ContactFeature.State(id: id1, name: name3, sequenceNo: sequenceNo1))
        await store.receive(\.editContact.dismiss) {
            $0.editContact = nil
        }
        let savedIdentifier = try await client.contacts.fetchIdentifier(predicate: #Predicate { $0.id == id1 })
        #expect(savedIdentifier != nil)
        let savedContact = try await client.contacts.fetch(predicate: #Predicate { $0.id == id1 }).first
        #expect(savedContact?.id == id1)
        #expect(savedContact?.name == name3)
        await store.receive(\.didEdit, ContactFeature.State(id: id1, name: name3, sequenceNo: sequenceNo1)) {
            let contact1 = ContactFeature.State(id: id1, name: name3, sequenceNo: sequenceNo1)
            let contact2 = ContactFeature.State(id: id2, name: name2, sequenceNo: sequenceNo2)
            $0.contacts = [contact1, contact2]
        }
    }
}
