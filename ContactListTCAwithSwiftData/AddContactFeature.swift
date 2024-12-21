//
//  AddContactFeature.swift
//  ContactListTCAwithSwiftData
//
//  Created by Takenori Kabeya on 2024/12/19.
//

import Foundation
import ComposableArchitecture
import SwiftUI



@Reducer
struct AddContactFeature {
    @ObservableState
    struct State: Equatable {
        var contact: Contact
    }
    
    enum Action {
        case cancelButtonTapped
        case delegate(Delegate)
        case saveButtonTapped
        case setName(String)
        
        @CasePathable
        enum Delegate: Equatable {
            case saveContact(Contact)
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
                return .run { [contact = state.contact] send in
                    await send(.delegate(.saveContact(contact)))
                    await self.dismiss()
                }
                
            case let .setName(name):
                state.contact.name = name
                return .none
            }
        }
    }
}



struct AddContactView: View {
    @Bindable var store: StoreOf<AddContactFeature>
    @State var name: String = ""
    
    var body: some View {
        Form {
            Section("Contact Information") {
                TextField("Name", text: $name)
            }
        }
        .onAppear {
            self.name = self.store.contact.name
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
        AddContactView(
            store: Store(
                initialState: AddContactFeature.State(
                    contact: Contact(id: uuid(), name: "Jennifer Parker", sequenceNo: 0)
                )
            ) {
                AddContactFeature()
            }
        )
    }
}
