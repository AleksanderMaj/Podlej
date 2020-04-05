//
//  PlantDetails.swift
//  PlantDetails
//
//  Created by Aleksander Maj on 23/03/2020.
//  Copyright © 2020 AleksanderMaj. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import CloudKit
import Combine
import Models

public struct State: Equatable {
    public var plant: NewPlant
    public var isPresented: Bool

    public init(
        plant: NewPlant,
        isPresented: Bool
    ) {
        self.plant = plant
        self.isPresented = isPresented
    }
}

public enum Action: Equatable {
    case start
    case create
    case nameChanged(String)
    case speciesChanged(String)
    case addSuccess
    case addFailure
}

public struct Environment {
    public init() {}
}

public let reducer: Reducer<State, Action, Environment> = {state, action, _ in
    switch action {
    case .start:
        state.plant = NewPlant()
        return []
    case .nameChanged(let name):
        state.plant.name = name
        return []
    case .speciesChanged(let species):
        return []
    case .create:
        return [add(plant: state.plant)]
    case .addSuccess:
        state.isPresented = false
        return []
    case .addFailure:
        return []
    }
}

public struct PlantDetailsView: View {

    @ObservedObject var store: Store<State, Action>
    @SwiftUI.State private var name = ""
    @SwiftUI.State private var species = ""

    public init(store: Store<State, Action>) {
        self.store = store
    }

    public var body: some View {
        let nameBinding = Binding<String>(
            get: { self.name },
            set: {
                self.name = $0
                self.store.send(.nameChanged($0))
            }
        )

        let speciesBinding = Binding<String>(
            get: { self.species },
            set: {
                self.species = $0
                self.store.send(.speciesChanged($0))
            }
        )
        return NavigationView {
            Form {
                Section {
                    TextField("Nazwa", text: nameBinding)
                    TextField("Gatunek", text: speciesBinding)
                }
                Section {
                    Button("Gotowe", action: { self.store.send(.create) })
                }
            }
            .navigationBarTitle("Dodaj roślinę")
        }
    }
}

private func add(plant: NewPlant) -> Effect<Action> {
    Deferred {
        Future<Action, Never> { callback in
            let plantRecordID = CKRecord.ID(recordName: plant.name)
            let plantRecord = CKRecord(recordType: "Plant", recordID: plantRecordID)
            plantRecord["name"] = plant.name

            let container = CKContainer.init(identifier: "iCloud.com.aleksandermaj.podlej-test")
            let db = container.privateCloudDatabase

            db.save(plantRecord) { (record, error) in
                if let error = error {
                    print(error)
                    callback(.success(Action.addFailure))
                } else if let record = record {
                    print(record)
                    callback(.success(Action.addSuccess))
                } else {
                    fatalError()
                }
            }

        }
    }
    .receive(on: DispatchQueue.main)
    .eraseToEffect()
}
