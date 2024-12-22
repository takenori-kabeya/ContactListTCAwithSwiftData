//
//  AddContactFeature.swift
//  ContactListTCAwithSwiftData
//
//  Created by Takenori Kabeya on 2024/12/19.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import SwiftData



@Model
final class PersistentContact: Extractable {
    var id: UUID
    var name: String
    var sequenceNo: Int
    
    init(id: UUID, name: String, sequenceNo: Int) {
        self.id = id
        self.name = name
        self.sequenceNo = sequenceNo
    }
    
    func extract() -> ContactFeature.State {
        return ContactFeature.State(id: self.id, name: self.name, sequenceNo: self.sequenceNo)
    }
    
    func updateFrom(_ extractedObject: ContactFeature.State) {
        self.id = extractedObject.id
        self.name = extractedObject.name
        self.sequenceNo = extractedObject.sequenceNo
    }
    
    static func createFrom(_ extractedObject: ContactFeature.State) -> PersistentContact {
        return PersistentContact(id: extractedObject.id, name: extractedObject.name, sequenceNo: extractedObject.sequenceNo)
    }
}



@Reducer
struct ContactFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var id: UUID
        var name: String
        var sequenceNo: Int
    }
    
    enum Action {
        case cancelButtonTapped
        case delegate(Delegate)
        case saveButtonTapped
        case setName(String)
        
        @CasePathable
        enum Delegate: Equatable {
            case saveContact(ContactFeature.State)
        }
    }
    
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
                    await self.dismiss()
                }
                
            case let .setName(name):
                state.name = name
                return .none
            }
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
        }
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
                    id: uuid(), name: "Jennifer Parker", sequenceNo: 0
                )
            ) {
                ContactFeature()
            }
        )
    }
}
