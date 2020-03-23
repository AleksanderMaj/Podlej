//
//  NewPlant.swift
//  Models
//
//  Created by Aleksander Maj on 23/03/2020.
//  Copyright © 2020 AleksanderMaj. All rights reserved.
//

import Foundation

public struct NewPlant: Equatable {
    public var name: String

    public init(name: String = "New plant") {
        self.name = name
    }
}
