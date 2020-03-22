//
//  Plant.swift
//  Plants
//
//  Created by Aleksander Maj on 22/03/2020.
//  Copyright © 2020 AleksanderMaj. All rights reserved.
//

import Foundation

public struct Plant: Equatable {
    let name: String
}

extension Array where Element == Plant {
    public static var mock: [Plant] {
        let plants = [
            "Monstera Adansonii #1",
            "Sansevieria #1",
            "Monstera Adansonii #2"
        ]

        return plants.map(Plant.init(name:))
    }
}
