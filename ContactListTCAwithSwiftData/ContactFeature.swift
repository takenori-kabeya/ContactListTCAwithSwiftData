//
//  ContactFeature.swift
//  ContactListTCAwithSwiftData
//
//  Created by Takenori Kabeya on 2024/12/19.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import SwiftData


@Model
final class PersistentContact: PersistentMapping {
    @Attribute(.unique) var stateId: UUID
    var name: String
    var sequenceNo: Int
    
    @Relationship(deleteRule: .nullify, inverse: .none) var phoneNumbers: [PersistentPhoneNumber]
    var nextSequenceNoOfPhoneNumbers: Int
    
    init(stateId: UUID, name: String, sequenceNo: Int, phoneNumbers: [PersistentPhoneNumber], nextSequenceNoOfPhoneNumbers: Int) {
        self.stateId = stateId
        self.name = name
        self.sequenceNo = sequenceNo
        self.phoneNumbers = phoneNumbers
        self.nextSequenceNoOfPhoneNumbers = nextSequenceNoOfPhoneNumbers
    }
    
    func extract() -> ContactFeature.State {
        return ContactFeature.State(id: self.stateId, name: self.name, sequenceNo: self.sequenceNo,
                                    phoneNumbers: IdentifiedArrayOf<PhoneNumberFeature.State>(uniqueElements: self.phoneNumbers.map { $0.extract() }),
                                    nextSequenceNoOfPhoneNumbers: self.nextSequenceNoOfPhoneNumbers)
    }
    
    func updateFrom(_ inMemoryObject: ContactFeature.State) {
        self.stateId = inMemoryObject.id
        self.name = inMemoryObject.name
        self.sequenceNo = inMemoryObject.sequenceNo
        self.nextSequenceNoOfPhoneNumbers = inMemoryObject.nextSequenceNoOfPhoneNumbers
        self.phoneNumbers.append(contentsOf: inMemoryObject.phoneNumbers.map { PersistentPhoneNumber.createFrom($0) })
        fatalError("This must not work. Use SwiftDataClient.contacts.updateWithChild() instead.")
    }
    
    static func createFrom(_ inMemoryObject: ContactFeature.State) -> PersistentContact {
        return PersistentContact(stateId: inMemoryObject.id, name: inMemoryObject.name, sequenceNo: inMemoryObject.sequenceNo, phoneNumbers: inMemoryObject.phoneNumbers.map { PersistentPhoneNumber(stateId: $0.id, phoneType: $0.phoneType, number: $0.number, sequenceNo: $0.sequenceNo) }, nextSequenceNoOfPhoneNumbers: inMemoryObject.nextSequenceNoOfPhoneNumbers)
    }
}



extension ContactFeature.State: InMemoryChildContainer {
    typealias InMemoryChildType = PhoneNumberFeature.State
    
    var inMemoryChildren: IdentifiedArrayOf<InMemoryChildType> {
        return self.phoneNumbers
    }
}

extension PersistentContact: PersistentChildContainer {
    typealias PersistentChildType = PersistentPhoneNumber
    
    var persistentChildren: [PersistentPhoneNumber] {
        return self.phoneNumbers
    }
    
    func updateFrom(_ inMemoryObject: ContactFeature.State, withChildren children: [PersistentPhoneNumber]) {
        self.stateId = inMemoryObject.id
        self.name = inMemoryObject.name
        self.sequenceNo = inMemoryObject.sequenceNo
        self.nextSequenceNoOfPhoneNumbers = inMemoryObject.nextSequenceNoOfPhoneNumbers
        self.phoneNumbers = children
    }
    
    static func isMatch(_ persistentChild: PersistentPhoneNumber, _ inMemoryChild: PhoneNumberFeature.State) -> Bool {
        return persistentChild.stateId == inMemoryChild.id
    }
}


@Reducer
struct ContactFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var id: UUID
        var name: String
        var sequenceNo: Int
        
        var phoneNumbers: IdentifiedArrayOf<PhoneNumberFeature.State>
        var nextSequenceNoOfPhoneNumbers: Int
    }
    
    enum Action {
        case cancelButtonTapped
        case delegate(Delegate)
        case saveButtonTapped
        case setName(String)
        
        case addPhoneNumberButtonTapped
        
        @CasePathable
        enum Delegate: Equatable {
            case saveContact(ContactFeature.State)
        }
        
        case phoneNumbers(IdentifiedActionOf<PhoneNumberFeature>)
    }
    
    @Dependency(\.uuid) var uuid
    @Dependency(\.swiftDataClient) var client
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cancelButtonTapped:
                return .run { _ in
                    await self.dismiss()
                }
                
            case .delegate:
                return .none
                
            case .saveButtonTapped:
                return .run { [contact = state] send in
                    await send(.delegate(.saveContact(contact)))
                    //await self.dismiss()
                }
                
            case .setName(let name):
                state.name = name
                return .none
                
            case .phoneNumbers(.element(id: let elementId, action: let childAction)):
                return handleChildAction(state: &state, id: elementId, childAction: childAction)
                
            case .addPhoneNumberButtonTapped:
                return handleAddPhoneNumberButtonTapped(state: &state)
            }
        }
    }
    
    func handleAddPhoneNumberButtonTapped(state: inout Self.State) -> Effect<Self.Action> {
        let phoneNumber = PhoneNumberFeature.State(id: self.uuid(), phoneType: .home, number: "", sequenceNo: state.nextSequenceNoOfPhoneNumbers)
        state.phoneNumbers.append(phoneNumber)
        state.nextSequenceNoOfPhoneNumbers = max(state.nextSequenceNoOfPhoneNumbers, phoneNumber.sequenceNo) + 1
        return .none
    }
    
    func handleChildAction(state: inout Self.State, id: PhoneNumberFeature.State.ID, childAction: PhoneNumberFeature.Action) -> Effect<Self.Action> {
        
        switch childAction {
        case .deleteButtonTapped:
            state.phoneNumbers.remove(id: id)
            return .none
        case .setPhoneType(let phoneType):
            state.phoneNumbers[id: id]?.phoneType = phoneType
            return .none
        case .setNumber(let number):
            state.phoneNumbers[id: id]?.number = number
            return .none
        }
    }
}



struct ContactView: View {
    @Bindable var store: StoreOf<ContactFeature>
    @State var name: String = ""
    
    var body: some View {
        Form {
            Section("Contact Information") {
                TextField("Name", text: $name)
            }
            .textCase(.none)
            Section("Phone") {
                PhoneNumbersView(store: self.store)
            }
            .textCase(.none)
        }
        .isEditing(true)
        .onAppear {
            self.name = self.store.name
        }
        .onChange(of: name) { (oldValue, newValue) in
            let _ = store.send(.setName(newValue))
        }
        .toolbar {
            ToolbarItem {
                Button("Cancel") {
                    store.send(.cancelButtonTapped)
                }
            }
            ToolbarItem {
                Button("Save") {
                    store.send(.saveButtonTapped)
                }
            }
        }
    }
}


#Preview {
    @Dependency(\.uuid) var uuid
    
    NavigationStack {
        ContactView(
            store: Store(
                initialState: ContactFeature.State(
                    id: uuid(), name: "Jennifer Parker", sequenceNo: 0, phoneNumbers: [], nextSequenceNoOfPhoneNumbers: 0
                )
            ) {
                ContactFeature()
            }
        )
    }
}
