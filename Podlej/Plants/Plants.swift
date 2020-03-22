//
//  Plants.swift
//  Plants
//
//  Created by Aleksander Maj on 22/03/2020.
//  Copyright © 2020 AleksanderMaj. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

public struct State: Equatable {
    public var plants: [Plant]

    public init(plants: [Plant]) {
        self.plants = plants
    }
}

public enum Action: Equatable {}

public struct Environment {
    public init() {}
}

public let reducer: Reducer<State, Action, Environment> = {state, action, _ in
    return []
}


public struct PlantsView: View {
    private let plants = [
        "Monstera Adansonii #1",
        "Sansevieria #1",
        "Monstera Adansonii #2"
    ]

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
    }
}
