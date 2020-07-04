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
import PodlejCommon

struct AppState: Equatable {
    var plants = [Plant]()
    var isPlantDetailsPresented = false
    var plantDetails = Plant(name: "Nowa roślina")
    var selection: UUID? = nil
}

extension AppState {
    var plantsView: Plants.State {
        get {
            .init(
                plants: plants,
                isPlantDetailsPresented: isPlantDetailsPresented,
                plantDetails: plantDetails,
                selection: selection
            )
        }
        set {
            self.plants = newValue.plants
            self.isPlantDetailsPresented = newValue.isPlantDetailsPresented
            self.plantDetails = newValue.plantDetails
            self.selection = newValue.selection
        }
    }
}

enum AppAction: Equatable {
    case plants(Plants.Action)
}

struct ContentView: View {
    init(
        store: Store<AppState, AppAction> = .init(
            initialState: AppState(),
            reducer: reducer.debug(),
            environment: AppEnvironment()
        )
    ) {
        self.store = store
    }

    let store: Store<AppState, AppAction>

    var body: some View {
        TabView {
            NavigationView {
                PlantsView(
                    store: self.store.scope(
                        state: { $0.plantsView },
                        action: AppAction.plants
                    )
                )
            }
            .tabItem {
                Image(systemName: "list.bullet")
                    .font(Font.body.weight(.black))
                Text("Rośliny")
            }
            VStack {
                Image("calathea")
                    .resizable()
                    .frame(width: 90, height: 90)
                Text("Kalendarz")
            }
                .tabItem {
                    Image(systemName: "calendar")
                        .font(Font.body.weight(.black))
                    Text("Kalendarz")
            }
            Text("Ustawienia")
                .tabItem {
                    Image(systemName: "gear")
                        .font(Font.body.weight(.black))
                    Text("Ustawienia")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store<AppState, AppAction>(
                initialState: AppState(
                    plants: .mock
                ),
                reducer: reducer,
                environment: .mock
            )
        )
    }
}

struct AppEnvironment {
    var cloudKitWrapper = CloudKitWrapper()
}

extension AppEnvironment {
    var plants: Plants.Environment {
        .init(cloudKitWrapper: cloudKitWrapper)
    }
}

extension AppEnvironment {
    static var mock: AppEnvironment {
        AppEnvironment(
            cloudKitWrapper: .mock
        )
    }
}

let reducer: Reducer<AppState, AppAction, AppEnvironment> = Plants.reducer.pullback(
    state: \AppState.plantsView,
    action: /AppAction.plants,
    environment: \AppEnvironment.plants
)

