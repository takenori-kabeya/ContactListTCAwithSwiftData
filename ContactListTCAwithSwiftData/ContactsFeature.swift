//
//  ContactFeature.swift
//  ContactListTCAwithSwiftData
//
//  Created by Takenori Kabeya on 2024/12/18.
//

import Foundation
import ComposableArchitecture
import SwiftData
import SwiftUI



@Reducer
struct ContactsFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var addContact: ContactFeature.State?
        @Presents var editContact: ContactFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
        var nextSequenceNo: Int = 0
        var contacts: IdentifiedArrayOf<Contact> = []
    }
    
    enum Action {
        case addButtonTapped
        case editButtonTapped(id: Contact.ID)
        case deleteButtonTapped(id: Contact.ID)
        
        case addContact(PresentationAction<ContactFeature.Action>)
        case editContact(PresentationAction<ContactFeature.Action>)
        case alert(PresentationAction<Alert>)
        case deleteContact(id: Contact.ID)
        
        case didAdd(contact: Contact)
        case didEdit(contact: Contact)
        case didDelete(id: Contact.ID)
        
        case onAppear
        case didLoad(loadedContacts: [Contact])
        
        enum Alert: Equatable {
            case confirmDeletion(id: Contact.ID)
        }
    }
    
    @Dependency(\.uuid) var uuid
    @Dependency(\.swiftDataClient) var client
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                return handleAddButtonTapped(state: &state)
                
            case let .editButtonTapped(id: id):
                return handleEditButtonTapped(state: &state, id: id)
                
            case let .deleteButtonTapped(id: id):
                return handleDeleteButtonTapped(state: &state, id: id)
                
            case let .addContact(.presented(.delegate(.saveContact(contact)))):
                return handleAddContact(contact: contact)
                
            case .addContact:
                return .none
                
            case let .didAdd(contact: contact):
                return handleDidAdd(state: &state, contact: contact)
            
            case let .editContact(.presented(.delegate(.saveContact(contact)))):
                return handleEditContact(contact: contact)
                
            case .editContact:
                return .none
            
            case let .didEdit(contact: contact):
                return handleDidEdit(state: &state, contact: contact)
            
            case let .deleteContact(id: id):
                return handleDeleteContact(id: id)
                
            case let .didDelete(id: id):
                return handleDidDelete(state: &state, id: id)
            
            case let .alert(.presented(.confirmDeletion(id: id))):
                return handleAlert(state: &state, id: id)
                
            case .alert:
                return .none
                
            case .onAppear:
                return handleOnAppear()
                
            case let .didLoad(loadedContacts: loadedContacts):
                return handleDidLoad(state: &state, loadedContacts: loadedContacts)
            }
        }
        .ifLet(\.$addContact, action: \.addContact) {
            ContactFeature()
        }
        .ifLet(\.$editContact, action: \.editContact) {
            ContactFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    func handleAddButtonTapped(state: inout Self.State) -> Effect<Self.Action> {
        state.addContact = ContactFeature.State(contact: Contact(id: self.uuid(), name: "", sequenceNo: state.nextSequenceNo))
        return .none
    }
    
    func handleEditButtonTapped(state: inout Self.State, id: Contact.ID) -> Effect<Self.Action> {
        guard let contact = state.contacts.first(where: { $0.id == id }) else {
            return .none
        }
        state.editContact = ContactFeature.State(contact: Contact(id: contact.id, name: contact.name, sequenceNo: contact.sequenceNo))
        return .none
    }
    
    func handleDeleteButtonTapped(state: inout Self.State, id: Contact.ID) -> Effect<Self.Action> {
        state.alert = AlertState.deleteConfirmation(id: id)
        return .none
    }
    
    func handleAddContact(contact: Contact) -> Effect<Self.Action> {
        return .run { send in
            do {
                try await self.client.contacts.insert(contact, forceSave: true)
                await send(.didAdd(contact: contact))
            }
            catch {
                print("error: \(error.localizedDescription)")
            }
        }
    }
    
    func handleDidAdd(state: inout Self.State, contact: Contact) -> Effect<Self.Action> {
        state.contacts.append(contact)
        state.nextSequenceNo = max(state.nextSequenceNo, contact.sequenceNo + 1)
        return .none
    }
    
    func handleEditContact(contact: Contact) -> Effect<Self.Action> {
        return .run { send in
            do {
                let id = contact.id
                guard let modelIdentifier = try await self.client.contacts.fetchIdentifier(predicate: #Predicate { $0.id == id }) else {
                    return
                }
                try await self.client.contacts.update(id: modelIdentifier, contact, forceSave: true)
                await send(.didEdit(contact: contact))
            }
            catch {
                print("error: \(error.localizedDescription)")
            }
        }
    }
    
    func handleDidEdit(state: inout Self.State, contact: Contact) -> Effect<Self.Action> {
        guard let idx = state.contacts.index(id: contact.id) else {
            return .none
        }
        state.contacts[idx] = contact
        state.nextSequenceNo = max(state.nextSequenceNo, contact.sequenceNo + 1)
        return .none
    }
    
    func handleDeleteContact(id: Contact.ID) -> Effect<Self.Action> {
        return .run { send in
            do {
                guard let modelIdentifier = try await self.client.contacts.fetchIdentifier(predicate: #Predicate { $0.id == id }) else {
                    return
                }
                try await self.client.contacts.delete(id: modelIdentifier, forceSave: true)
                await send(.didDelete(id: id))
            }
            catch {
                print("error: \(error.localizedDescription)")
            }
        }
    }
    
    func handleDidDelete(state: inout Self.State, id: Contact.ID) -> Effect<Self.Action> {
        state.contacts.remove(id: id)
        return .none
    }
    
    func handleAlert(state: inout Self.State, id: Contact.ID) -> Effect<Self.Action> {
        return .run { send in
            await send(.deleteContact(id: id))
        }
    }
    
    func handleOnAppear() -> Effect<Self.Action> {
        return .run { send in
            do {
                let loadedContacts = try await self.client.contacts.fetch(sortBy: [SortDescriptor(\PersistentContact.sequenceNo)])
                await send(.didLoad(loadedContacts: loadedContacts))
            }
            catch {
                print("error: \(error.localizedDescription)")
            }
        }
    }
    
    func handleDidLoad(state: inout Self.State, loadedContacts: [Contact]) -> Effect<Self.Action> {
        state.contacts.removeAll()
        state.contacts.append(contentsOf: loadedContacts)
        state.nextSequenceNo = state.contacts.reduce(0) { max($0, $1.sequenceNo + 1) }
        return .none
    }
}

extension AlertState where Action == ContactsFeature.Action.Alert {
    static func deleteConfirmation(id: Contact.ID) -> Self {
        Self(title: {
            TextState("Are you sure to delete?")
        }, actions: {
            ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
                TextState("Delete")
            }
        })
    }
}

struct ContactsView: View {
    @Bindable var store: StoreOf<ContactsFeature>
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.contacts) { contact in
                    HStack {
                        Text(contact.name)
                        Spacer()
                        Button(action: {
                            store.send(.editButtonTapped(id: contact.id))
                        }, label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(.blue)
                        })
                        .buttonStyle(.borderless)
                        Button(action: {
                            store.send(.deleteButtonTapped(id: contact.id))
                        }, label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        })
                        .buttonStyle(.borderless)
                    }
                }
                Button(action: {
                    store.send(.addButtonTapped)
                }, label: {
                    Text("Add a new contact")
                })
            }
            .navigationTitle("Contact List")
           
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.addContact, action: \.addContact)) { addContactStore in
            NavigationStack {
                ContactView(store: addContactStore)
            }
        }
        .sheet(item: $store.scope(state: \.editContact, action: \.editContact)) { editContactStore in
            NavigationStack {
                ContactView(store: editContactStore)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}




#Preview {
    do {
        @Dependency(\.uuid) var uuid
        let context = ModelContext(testModelContainer)
        context.insert(PersistentContact(id: uuid(), name: "Marty McFly", sequenceNo: 0))
        context.insert(PersistentContact(id: uuid(), name: "Emmett \"Doc\" Brown", sequenceNo: 1))
        context.insert(PersistentContact(id: uuid(), name: "Biff Tannen", sequenceNo: 2))
        try context.save()
        
        return ContactsView(store: Store(
            initialState: ContactsFeature.State(contacts: [])
        ) {
            ContactsFeature()
        })
    }
    catch {
        print("error: \(error.localizedDescription)")
        return EmptyView()
    }
}
