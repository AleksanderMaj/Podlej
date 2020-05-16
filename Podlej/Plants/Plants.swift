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
import PodlejCommon

public struct State: Equatable {
    public var plants: [Plant]
    public var isPlantDetailsPresented: Bool
    public var plantDetails: Plant

    public init(
        plants: [Plant],
        isPlantDetailsPresented: Bool,
        plantDetails: Plant
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
            PlantDetails.State(
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
    var cloudKitWrapper: CloudKitWrapper

    public init(
        cloudKitWrapper: CloudKitWrapper
    ) {
        self.cloudKitWrapper = cloudKitWrapper
    }

    var plantDetails: PlantDetails.Environment {
        .init(createPlant: cloudKitWrapper.createPlant)
    }
}

public extension Environment {
    static var mock: Environment {
        Environment(cloudKitWrapper: CloudKitWrapper.mock)
    }
}

public enum ListAction: Equatable {
    case addPlant
    case plantDetailsDismissed
    case fetchPlants
    case fetchPlantsResponse(Result<[Plant], CloudKitWrapper.FetchError>)
    case plantDetails(PlantDetails.Action)
}

let listReducer = Reducer<ListState, ListAction, Environment> { state, action, environment in
    switch action {
    case .addPlant:
        state.isPlantDetailsPresented = true
        return .none

    case .plantDetailsDismissed:
        state.isPlantDetailsPresented = false
        return .none

    case .fetchPlants:
        return environment.cloudKitWrapper.fetchPlants()
            .receive(on: DispatchQueue.main)
            .catchToEffect()
            .map(ListAction.fetchPlantsResponse)

    case .fetchPlantsResponse(.success(let plants)):
        state.plants = plants
        return .none

    case .fetchPlantsResponse(.failure(let error)):
        return .none

    case .plantDetails:
        return .none
    }
}

public let reducer = Reducer.combine(
    listReducer.pullback(state: \State.list, action: /Action.list, environment: { $0 }),
    PlantDetails.reducer.pullback(
        state: \State.plantDetailsView,
        action: /Action.plantDetails,
        environment: \Environment.plantDetails
    ),
    Reducer { state, action, env in
        switch action {
        case .plantDetails(.createPlantResponse(.success(let plant))):
            return Effect(value: Action.list(.fetchPlants))
        default:
            return .none
        }
    }
)


public struct PlantsView: View {

    let store: Store<State, Action>

    public init(store: Store<State, Action>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView {
                List {
                    ForEach(
                        viewStore.plants,
                        id: \Plant.name,
                        content: { plant in Text(plant.name) }
                    )
                }
                .navigationBarTitle("Rośliny")
                .navigationBarItems(trailing:
                    HStack {
                        Button("Odśwież", action: { viewStore.send(.list(.fetchPlants)) })
                        Button("Dodaj", action: { viewStore.send(.list(.addPlant)) })
                    }
                )
                    .onAppear {
                        viewStore.send(.list(.fetchPlants))
                }
                .sheet(
                    isPresented: .constant(viewStore.isPlantDetailsPresented),
                    onDismiss: { viewStore.send(.list(.plantDetailsDismissed)) }
                ) {
                    PlantDetailsView(
                        store: self.store.scope(state: { $0.plantDetailsView }, action: Action.plantDetails)
                    )
                }
            }
        }
    }
}

struct Plants_Previews: PreviewProvider {
    static var previews: some View {
        PlantsView(
            store: .init(
                initialState: .init(
                    plants: .mock,
                    isPlantDetailsPresented: false,
                    plantDetails: .init(name: "Nowa roślina")
                ),
                reducer: reducer,
                environment: .mock
            )
        )
    }
}
