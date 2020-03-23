//
//  Plants.swift
//  Plants
//
//  Created by Aleksander Maj on 22/03/2020.
//  Copyright © 2020 AleksanderMaj. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import CloudKit
import Combine
import Models
import PlantDetails
import CasePaths

public struct State: Equatable {
    public var plants: [Plant]
    public var isPlantDetailsPresented: Bool
    public var plantDetails: NewPlant

    public init(
        plants: [Plant],
        isPlantDetailsPresented: Bool,
        plantDetails: NewPlant
    ) {
        self.plants = plants
        self.isPlantDetailsPresented = isPlantDetailsPresented
        self.plantDetails = plantDetails
    }
}

extension State {
    var list: ListState {
        get {
            ListState(
                plants: self.plants,
                isPlantDetailsPresented: self.isPlantDetailsPresented
            )
        }
        set {
            plants = newValue.plants
            isPlantDetailsPresented = newValue.isPlantDetailsPresented
        }
    }

    var plantDetailsView: PlantDetails.State {
        get {
            .init(
                plant: plantDetails,
                isPresented: isPlantDetailsPresented
            )
        }
        set {
            self.plantDetails = newValue.plant
            self.isPlantDetailsPresented = newValue.isPresented
        }
    }
}

public struct ListState: Equatable {
    public var plants: [Plant]
    public var isPlantDetailsPresented: Bool
}

public enum Action: Equatable {
    case list(ListAction)
    case plantDetails(PlantDetails.Action)
}

public struct Environment {
    public init() {}
}

public enum ListAction: Equatable {
    case addPlant
    case plantDetailsDismissed
    case fetchPlants
    case fetchPlantsSuccess([Plant])
    case fetchPlantsError
    case plantDetails(PlantDetails.Action)
}


let listReducer: Reducer<ListState, ListAction, Environment> = { state, action, _ in
    switch action {
    case .addPlant:
        state.isPlantDetailsPresented = true
        return []
    case .plantDetailsDismissed:
        state.isPlantDetailsPresented = false
        return [fetchPlants()]
    case .fetchPlants:
        return [fetchPlants()]
    case .fetchPlantsSuccess(let plants):
        state.plants = plants
        return []
    case .fetchPlantsError:
        return []
    case .plantDetails:
        return []
    }
}

public let reducer = combine(
    pullback(listReducer, value: \State.list, action: /Action.list, environment: { $0 }),
    pullback(PlantDetails.reducer, value: \State.plantDetailsView, action: /Action.plantDetails, environment: { _ in PlantDetails.Environment() })
)


public struct PlantsView: View {

    @ObservedObject var store: Store<State, Action>

    public init(store: Store<State, Action>) {
        self.store = store
    }
    
    public var body: some View {
        List {
            ForEach(
                self.store.value.plants,
                id: \Plant.name,
                content: { plant in Text(plant.name) }
            )
        }
        .navigationBarTitle("Plants")
        .navigationBarItems(trailing: Button("Add", action: {
            self.store.send(.list(.addPlant))
        }))
        .onAppear {
            self.store.send(.list(.fetchPlants))
        }
        .sheet(
            isPresented: .constant(self.store.value.isPlantDetailsPresented),
            onDismiss: { self.store.send(.list(.plantDetailsDismissed)) }
        ) {
            PlantDetailsView(
                store: self.store.view(
                    value: { $0.plantDetailsView },
                    action: Action.plantDetails
                )
            )
        }
    }
}

private func fetchPlants() -> Effect<ListAction> {
    Deferred {
        Future<ListAction, Never> { callback in
            let container = CKContainer(identifier: "iCloud.com.aleksandermaj.podlej-test")
            let db = container.privateCloudDatabase
            let query = CKQuery(
                recordType: CKRecord.RecordType("Plant"),
                predicate: NSPredicate(value: true)
            )
            db.perform(query, inZoneWith: nil) { (records, error) in
                if let error = error {
                    print(error)
                    callback(.success(ListAction.fetchPlantsError))
                } else if let records = records {
                    print(records)
                    let plants = records.compactMap(Plant.init(record:))
                    callback(.success(ListAction.fetchPlantsSuccess(plants)))
                } else {
                    fatalError()
                }
            }
        }
    }
    .receive(on: DispatchQueue.main)
    .eraseToEffect()
}
