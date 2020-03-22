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

struct AppState: Equatable {
    var plants = [Plant].mock
}

extension AppState {
    var plantsView: Plants.State {
        get {
            .init(
                plants: plants
            )
        }
        set {
            self.plants = newValue.plants
        }
    }
}

enum AppAction: Equatable {
    case plants(Plants.Action)
}

struct ContentView: View {

    @ObservedObject var store: Store<AppState, AppAction>

    var body: some View {
        NavigationView {
            PlantsView(
                store: self.store.view(
                    value: { $0.plantsView },
                    action: { AppAction.plants($0) }
                )
            )
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
struct AppEnvironment {}

extension AppEnvironment {
    var plants: Plants.Environment {
        .init()
    }
}

let reducer: Reducer<AppState, AppAction, AppEnvironment> = combine(
    pullback(Plants.reducer, value: \AppState.plantsView, action: /AppAction.plants, environment: { $0.plants })
)

