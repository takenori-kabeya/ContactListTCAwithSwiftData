//
//  ContactListTCAwithSwiftDataApp.swift
//  ContactListTCAwithSwiftData
//
//  Created by Takenori Kabeya on 2024/12/18.
//

import SwiftUI
import ComposableArchitecture



@main
struct ContactListTCAwithSwiftDataApp: App {
    static let store = Store(initialState: ContactsFeature.State()) {
        ContactsFeature()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: ContactListTCAwithSwiftDataApp.store)
        }
    }
}
