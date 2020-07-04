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
import PodlejCommon

public struct State: Equatable {
    public var plants: [Plant]
    public var isPlantDetailsPresented: Bool
    public var plantDetails: Plant
    public var selection: UUID?

    public init(
        plants: [Plant],
        isPlantDetailsPresented: Bool,
        plantDetails: Plant,
        selection: UUID?
    ) {
        self.plants = plants
        self.isPlantDetailsPresented = isPlantDetailsPresented
        self.plantDetails = plantDetails
        self.selection = selection
    }
}

extension State {
    var list: ListState {
        get {
            ListState(
                plants: self.plants,
                isPlantDetailsPresented: self.isPlantDetailsPresented,
                selection: self.selection
            )
        }
        set {
            plants = newValue.plants
            isPlantDetailsPresented = newValue.isPlantDetailsPresented
            selection = newValue.selection
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

    var existingPlantDetails: PlantDetails.State? {
        get {
            guard let selectedPlant = plants.first(where: { selection == $0.uuid })
                else { return nil }
            return PlantDetails.State(
                plant: selectedPlant,
                isPresented: false
            )
        }
        set {
            guard let newValue = newValue else { return }
            self.selection = newValue.plant.uuid
        }
    }
}

public struct ListState: Equatable {
    public var plants: [Plant]
    public var isPlantDetailsPresented: Bool
    public var selection: UUID?
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
    case setSelection(UUID?)
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

    case .setSelection(let uuid):
        state.selection = uuid
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

public struct PlantView: View {
    let plant: Plant

    public var body: some View {
        HStack {
            Image("calathea")
                .resizable()
                .frame(width: 74, height: 74)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Text(plant.name)
                    .font(.body)
                Text(plant.species ?? "")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
    }
}

public struct PlantsView: View {

    let store: Store<State, Action>

    public init(store: Store<State, Action>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            List {
                ForEach(
                    viewStore.plants,
                    id: \Plant.uuid
                ) { plant in
                    NavigationLink(
                        destination: IfLetStore(
                            self.store.scope(state: { $0.existingPlantDetails }, action: Action.plantDetails),
                            then: PlantDetailsView.init(store:)
                        ),
                        tag: plant.uuid,
                        selection: viewStore.binding(
                            get: { $0.selection },
                            send: { Action.list(.setSelection($0)) }
                        ),
                        label: { PlantView(plant: plant) }
                    )
                }
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
                NavigationView {
                    PlantDetailsView(
                        store: self.store.scope(
                            state: { $0.plantDetailsView },
                            action: Action.plantDetails
                        )
                    )
                }
            }
        }
    }
}

struct Plants_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlantsView(
                store: .init(
                    initialState: .init(
                        plants: .mock,
                        isPlantDetailsPresented: false,
                        plantDetails: .init(name: "Nowa roślina"),
                        selection: nil
                    ),
                    reducer: reducer,
                    environment: .mock
                )
            )
        }
    }
}
