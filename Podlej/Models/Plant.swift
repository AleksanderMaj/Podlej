//
//  Plant.swift
//  Plants
//
//  Created by Aleksander Maj on 22/03/2020.
//  Copyright © 2020 AleksanderMaj. All rights reserved.
//

import Foundation
import CloudKit

public struct Plant: Equatable {
    public let name: String
    public init(name: String) {
        self.name = name
    }
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

extension Plant {
    public init?(record: CKRecord) {
        guard record.recordType == "Plant",
        let name = record["name"] as? String else { return nil }
        self.name = name
    }
}
