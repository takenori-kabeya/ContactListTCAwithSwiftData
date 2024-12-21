//
//  ContentView.swift
//  ContactListTCAwithSwiftData
//
//  Created by Takenori Kabeya on 2024/12/18.
//

import SwiftUI
import ComposableArchitecture



struct ContentView: View {
    var store: StoreOf<ContactsFeature>
    
    var body: some View {
        ContactsView(store: self.store)
    }
}

#Preview {
    ContentView(store: Store(initialState: ContactsFeature.State()) {
        ContactsFeature()
    })
}
