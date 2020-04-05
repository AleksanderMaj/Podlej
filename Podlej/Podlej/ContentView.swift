//
//  ContentView.swift
//  Podlej
//
//  Created by Aleksander Maj on 04/01/2020.
//  Copyright © 2020 AleksanderMaj. All rights reserved.
//

import Combine
import SwiftUI
import CasePaths
import ComposableArchitecture
import Plants
import Models
import PlantDetails

struct AppState: Equatable {
    var plants = [Plant]()
    var isPlantDetailsPresented = false
    var plantDetails = NewPlant()
}

extension AppState {
    var plantsView: Plants.State {
        get {
            .init(
                plants: plants,
                isPlantDetailsPresented: isPlantDetailsPresented,
                plantDetails: plantDetails
            )
        }
        set {
            self.plants = newValue.plants
            self.isPlantDetailsPresented = newValue.isPlantDetailsPresented
            self.plantDetails = newValue.plantDetails
        }
    }
}

enum AppAction: Equatable {
    case plants(Plants.Action)
}

struct ContentView: View {
    init(
        store: Store<AppState, AppAction> = .init(
            initialValue: AppState(),
            reducer: logging(reducer),
            environment: AppEnvironment()
        )
    ) {
        self.store = store
    }

    @ObservedObject var store: Store<AppState, AppAction>

    var body: some View {
        TabView {
            NavigationView {
                PlantsView(
                    store: self.store.view(
                        value: { $0.plantsView },
                        action: { AppAction.plants($0) }
                    )
                )
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Rośliny")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct AppEnvironment {}

extension AppEnvironment {
    var plants: Plants.Environment {
        .init()
    }
}

let reducer: Reducer<AppState, AppAction, AppEnvironment> = combine(
    pullback(Plants.reducer, value: \AppState.plantsView, action: /AppAction.plants, environment: { $0.plants })
)

