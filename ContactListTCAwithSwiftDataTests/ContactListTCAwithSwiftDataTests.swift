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
        
        let client = SwiftDataClient.testValue
        
        let name = "Rocky Balbore"
        let id = UUID(0)
        let sequenceNo1 = 0
        let sequenceNo2 = sequenceNo1 + 1
        
        let context = ModelContext(testModelContainer)
        try context.delete(model: PersistentContact.self)
        try context.delete(model: PersistentPhoneNumber.self)
        try context.save()
        
        await store.send(.addButtonTapped) {
            $0.addContact = ContactFeature.State(id: id, name: "", sequenceNo: sequenceNo1, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0)
        }
        await store.send(\.addContact.setName, name) {
            $0.addContact?.name = name
        }
        await store.send(\.addContact.saveButtonTapped)
        let contact1 = ContactFeature.State(id: id, name: name, sequenceNo: sequenceNo1, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0)
        
        await store.receive(\.addContact.delegate.saveContact, contact1)
        await store.receive(\.addContact.dismiss) {
            $0.addContact = nil
        }
        
        let savedIdentifier = try await client.contacts.fetchIdentifier(predicate: #Predicate { $0.id == id })
        #expect(savedIdentifier != nil)
        let savedContact = try await client.contacts.fetch(predicate: #Predicate { $0.id == id }).first
        #expect(savedContact?.id == id)
        #expect(savedContact?.name == name)
        await store.receive(\.didAdd, contact1) {
            $0.contacts = [contact1]
            $0.nextSequenceNo = sequenceNo2
        }
        
        await store.send(.editButtonTapped(contact: contact1)) {
            $0.editContact = contact1
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
        
        let client = SwiftDataClient.testValue
        
        let name1 = "Rocky Balbore"
        let name2 = "Apollo Creed"
        let id1 = UUID(0)
        let id2 = UUID(1)
        let sequenceNo1 = 0
        let sequenceNo2 = 3
        let sequenceNo3 = sequenceNo2 + 1
        
        let context = ModelContext(testModelContainer)
        try context.delete(model: PersistentContact.self)
        try context.delete(model: PersistentPhoneNumber.self)
        try context.save()
        context.insert(PersistentContact(id: id1, name: name1, sequenceNo: sequenceNo1, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0))
        context.insert(PersistentContact(id: id2, name: name2, sequenceNo: sequenceNo2, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0))
        try context.save()
        
        await store.send(.onAppear)
        let contact1 = ContactFeature.State(id: id1, name: name1, sequenceNo: sequenceNo1, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0)
        let contact2 = ContactFeature.State(id: id2, name: name2, sequenceNo: sequenceNo2, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0)
        
        await store.receive(\.didLoad) {
            $0.contacts = [contact1, contact2]
            $0.nextSequenceNo = sequenceNo3
        }
        
        await store.send(.deleteButtonTapped(contact: contact2)) {
            $0.alert = AlertState.deleteConfirmation(contact: contact2)
        }
        await store.send(.alert(.presented(.confirmDeletion(contact: contact2)))) {
            $0.alert = nil
        }
        await store.receive(\.deleteContact)
        let savedIdentifier = try await client.contacts.fetchIdentifier(predicate: #Predicate { $0.id == id2 })
        #expect(savedIdentifier == nil)
        await store.receive(\.didDelete) {
            //let contact1 = ContactFeature.State(id: id1, name: name1, sequenceNo: sequenceNo1, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0)
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
        
        let client = SwiftDataClient.testValue
        
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
        try context.delete(model: PersistentPhoneNumber.self)
        try context.save()
        context.insert(PersistentContact(id: id1, name: name1, sequenceNo: sequenceNo1, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0))
        context.insert(PersistentContact(id: id2, name: name2, sequenceNo: sequenceNo2, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0))
        try context.save()
        
        await store.send(.onAppear)
        let contact1 = ContactFeature.State(id: id1, name: name1, sequenceNo: sequenceNo1, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0)
        let contact2 = ContactFeature.State(id: id2, name: name2, sequenceNo: sequenceNo2, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0)
        await store.receive(\.didLoad) {
            $0.contacts = [contact1, contact2]
            $0.nextSequenceNo = sequenceNo3
        }
        
        await store.send(.editButtonTapped(contact: contact1)) {
            $0.editContact = contact1
        }
        await store.send(\.editContact.setName, name3) {
            $0.editContact?.name = name3
        }
        let contact3 = ContactFeature.State(id: id1, name: name3, sequenceNo: sequenceNo1, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0)
        await store.send(\.editContact.saveButtonTapped)
        await store.receive(\.editContact.delegate.saveContact, contact3)
        await store.receive(\.editContact.dismiss) {
            $0.editContact = nil
        }
        let savedIdentifier = try await client.contacts.fetchIdentifier(predicate: #Predicate { $0.id == id1 })
        #expect(savedIdentifier != nil)
        let savedContact = try await client.contacts.fetch(predicate: #Predicate { $0.id == id1 }).first
        #expect(savedContact?.id == id1)
        #expect(savedContact?.name == name3)
        await store.receive(\.didEdit, contact3) {
            $0.contacts = [contact3, contact2]
        }
        
        await store.send(.editButtonTapped(contact: contact3)) {
            $0.editContact = contact3
        }
    }
    
    @Test
    func addPhoneNumberFlow() async throws {
        let store = await TestStore(initialState: ContactsFeature.State()) {
            ContactsFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.context = .test
        }
        
        let client = SwiftDataClient.testValue
        
        let name1 = "Rocky Balbore"
        
        let id1 = UUID(0)
        
        let sequenceNo1 = 0
        let sequenceNo2 = sequenceNo1 + 1
        
        let context = ModelContext(testModelContainer)
        try context.delete(model: PersistentContact.self)
        try context.delete(model: PersistentPhoneNumber.self)
        try context.save()
        context.insert(PersistentContact(id: id1, name: name1, sequenceNo: sequenceNo1, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0))
        try context.save()
        
        await store.send(.onAppear)
        let contact1 = ContactFeature.State(id: id1, name: name1, sequenceNo: sequenceNo1, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0)
        await store.receive(\.didLoad) {
            $0.contacts = [contact1]
            $0.nextSequenceNo = sequenceNo2
        }
        
        await store.send(.editButtonTapped(contact: contact1)) {
            $0.editContact = contact1
        }
        let id2 = UUID(0)
        let phoneNumber1 = PhoneNumberFeature.State(id: id2, phoneType: .home, number: "", sequenceNo: 0)
        let contact2 = ContactFeature.State(id: id1, name: name1, sequenceNo: sequenceNo1, phoneNumbers: [phoneNumber1], nextSequenceNoOfPhoneNumbers: 1)
        await store.send(\.editContact.addPhoneNumberButtonTapped) {
            $0.editContact = contact2
        }
        
        let phoneNumber2 = PhoneNumberFeature.State(id: id2, phoneType: .office, number: "", sequenceNo: 0)
        let contact3 = ContactFeature.State(id: id1, name: name1, sequenceNo: sequenceNo1, phoneNumbers: [phoneNumber2], nextSequenceNoOfPhoneNumbers: 1)
        let action1: IdentifiedActionOf<PhoneNumberFeature> = .element(id: id2, action: .setPhoneType(phoneType: .office))
        await store.send(\.editContact.phoneNumbers, action1) {
            $0.editContact = contact3
        }
        
        let phoneNumber3 = PhoneNumberFeature.State(id: id2, phoneType: .office, number: "03-1234-5678", sequenceNo: 0)
        let contact4 = ContactFeature.State(id: id1, name: name1, sequenceNo: sequenceNo1, phoneNumbers: [phoneNumber3], nextSequenceNoOfPhoneNumbers: 1)
        let action2: IdentifiedActionOf<PhoneNumberFeature> = .element(id: id2, action: .setNumber(number: "03-1234-5678"))
        await store.send(\.editContact.phoneNumbers, action2) {
            $0.editContact = contact4
        }
        
        await store.send(\.editContact.saveButtonTapped)
        await store.receive(\.editContact.delegate.saveContact, contact4)
        await store.receive(\.editContact.dismiss) {
            $0.editContact = nil
        }
        
        let savedIdentifier = try await client.contacts.fetchIdentifier(predicate: #Predicate { $0.id == id1 })
        #expect(savedIdentifier != nil)
        let savedContact = try await client.contacts.fetch(predicate: #Predicate { $0.id == id1 }).first
        #expect(savedContact?.id == id1)
        #expect(savedContact?.name == name1)
        #expect(savedContact?.sequenceNo == sequenceNo1)
        #expect(savedContact?.phoneNumbers.count == 1)
        #expect(savedContact?.phoneNumbers[0] == phoneNumber3)
        #expect(savedContact?.nextSequenceNoOfPhoneNumbers == 1)
        await store.receive(\.didEdit, contact4) {
            $0.contacts = [contact4]
        }

    }
}
