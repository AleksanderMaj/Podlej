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
import PodlejCommon

public struct State: Equatable {
    public var plant: Plant
    public var isPresented: Bool

    public init(
        plant: Plant,
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
    case createPlantResponse(Result<Plant, CloudKitWrapper.CreateError>)
}

public struct Environment {
    var createPlant: (Plant) -> Future<Plant, CloudKitWrapper.CreateError>
    public init(
        createPlant: @escaping (Plant) -> Future<Plant, CloudKitWrapper.CreateError>
    ) {
        self.createPlant = createPlant
    }
}

public let reducer = Reducer<State, Action, Environment> { state, action, environment in
    switch action {
        case .start:
            state.plant = Plant(name: "Nowa roślina")
            return .none

        case .nameChanged(let name):
            state.plant.name = name
            return .none

        case .speciesChanged(let species):
            state.plant.species = species
            return .none

        case .create:
            return environment.createPlant(state.plant)
                .receive(on: DispatchQueue.main)
                .catchToEffect()
                .map(Action.createPlantResponse)

        case .createPlantResponse(.success(let plant)):
            state.isPresented = false
            state.plant = Plant(name: "Nowa roślina")
            return .none

        case .createPlantResponse(.failure(let error)):
            return .none
    }
}

public struct PlantDetailsView: View {

    let store: Store<State, Action>

    public init(store: Store<State, Action>) {
        self.store = store
    }

    public var body: some View {
        return WithViewStore(self.store) { viewStore in
            Form {
                Section {
                    TextField(
                        "Nazwa",
                        text: viewStore.binding(
                            get: { $0.plant.name },
                            send: Action.nameChanged
                        )
                    )
                    TextField(
                        "Gatunek",
                        text: viewStore.binding(
                            get: { $0.plant.species ?? ""},
                            send: Action.speciesChanged
                        )
                    )
                }
                Section {
                    Button("Gotowe", action: { viewStore.send(.create) })
                }
            }
            .navigationBarTitle("Dodaj roślinę")
        }
    }
}

struct PlantDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlantDetailsView(
                store: .init(
                    initialState: .init(
                        plant: .init(name: "Nowa roślina"),
                        isPresented: true
                    ),
                    reducer: reducer,
                    environment: .init(createPlant: CloudKitWrapper.mock.createPlant)
                )
            )
        }
    }
}
