//
//  PhoneNumberFeature.swift
//  ContactListTCAwithSwiftDataTests
//
//  Created by Takenori Kabeya on 2024/12/23.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import SwiftData
import PhoneNumberKit



@Model
final class PersistentPhoneNumber: Extractable {
    @Attribute(.unique) var stateId: UUID
    var phoneType: PhoneNumberFeature.PhoneType
    var number: String
    var sequenceNo: Int
    
    init(stateId: UUID, phoneType: PhoneNumberFeature.PhoneType, number: String, sequenceNo: Int) {
        self.stateId = stateId
        self.phoneType = phoneType
        self.number = number
        self.sequenceNo = sequenceNo
    }
    
    func extract() -> PhoneNumberFeature.State {
        return PhoneNumberFeature.State(id: self.stateId, phoneType: self.phoneType, number: self.number, sequenceNo: self.sequenceNo)
    }
    
    func updateFrom(_ extractedObject: PhoneNumberFeature.State) {
        self.stateId = extractedObject.id
        self.phoneType = extractedObject.phoneType
        self.number = extractedObject.number
        self.sequenceNo = extractedObject.sequenceNo
    }
    
    static func createFrom(_ extractedObject: PhoneNumberFeature.State) -> PersistentPhoneNumber {
        return PersistentPhoneNumber(stateId: extractedObject.id, phoneType: extractedObject.phoneType, number: extractedObject.number, sequenceNo: extractedObject.sequenceNo)
    }
}



@Reducer
struct PhoneNumberFeature {
    enum PhoneType: String, Codable, Equatable, CaseIterable, Identifiable {
        var id: Self { return self }
        
        case home
        case office
        case mobile
    }

    @ObservableState
    struct State: Equatable, Identifiable {
        //@Presents var alert: AlertState<Action.Alert>?
        
        var id: UUID
        var phoneType: PhoneType
        var number: String
        var sequenceNo: Int
        
        var persistentIdentifier: PersistentIdentifier? = nil
    }
    
    enum Action {
        case deleteButtonTapped
        
        case setPhoneType(phoneType: PhoneNumberFeature.PhoneType)
        case setNumber(number: String)
    }
    
    @Dependency(\.uuid) var uuid
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none
        }
    }
}



struct PhoneNumberRowView: View {
    @Bindable var store: StoreOf<PhoneNumberFeature>
    @State var number: String = ""
    @State var phoneType: PhoneNumberFeature.PhoneType = .home
    @FocusState var isFocused: Bool
    let phoneNumberUtility = PhoneNumberUtility()
    
    var body: some View {
        HStack {
//            Button(action: {
//                store.send(.deleteButtonTapped)
//            }, label: {
//                Image(systemName: "minus.circle.fill")
//                    .foregroundStyle(.red)
//            })
//            .buttonStyle(.plain)
            Picker("Phone Type", selection: $phoneType) {
                ForEach(PhoneNumberFeature.PhoneType.allCases) { phoneType in
                    Text(phoneType.rawValue)
                }
            }
            .labelsHidden()
            .frame(width: 100)
            Divider()
            TextField("Phone Number", text: $number)
                .focused($isFocused)
        }
        .onAppear {
            self.phoneType = store.phoneType
            self.number = store.number
        }
        .onChange(of: number) { (oldValue, newValue) in
            store.send(.setNumber(number: newValue))
        }
        .onChange(of: phoneType) { (oldValue, newValue) in
            store.send(.setPhoneType(phoneType: newValue))
        }
        .onChange(of: isFocused) { (oldValue, newValue) in
            if newValue {
                return
            }
            do {
                let parsed = try phoneNumberUtility.parse(self.number)
                self.number = self.phoneNumberUtility.format(parsed,
                                                             toType: self.number.starts(with: "+") ? .international : .national)
            }
            catch {
                print("error: \(error.localizedDescription)")
            }
        }
    }
}



struct PhoneNumbersView: View {
    @Bindable var store: StoreOf<ContactFeature>
    
    var body: some View {
        let stores = store.scope(state: \.phoneNumbers, action: \.phoneNumbers)
        ForEachStore(stores) { phoneNumberStore in
            //let _ = print("PhoneNumbersView: \(phoneNumberStore.state)")
            PhoneNumberRowView(store: phoneNumberStore)
        }
        .onDelete { indexSet in
            var ids: [PhoneNumberFeature.State.ID] = []
            for index in indexSet {
                stores.withState { arrayOfPhoneNumberState in
                    ids.append(arrayOfPhoneNumberState.elements[index].id)
                }
            }
            for id in ids {
                store.send(.phoneNumbers(.element(id: id, action: .deleteButtonTapped)))
            }
        }
        Button(action: {
            store.send(.addPhoneNumberButtonTapped)
        }, label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)
                Text("Add a new phone number")
            }
        })
    }
}



#Preview {
    @Dependency(\.uuid) var uuid
    
    Form {
        PhoneNumberRowView(
            store: Store(
                initialState: PhoneNumberFeature.State(
                    id: uuid(), phoneType: .home, number: "", sequenceNo: 0
                )
            ) {
                PhoneNumberFeature()
            }
        )
    }
}
