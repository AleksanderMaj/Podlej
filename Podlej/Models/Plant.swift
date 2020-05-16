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
    public var uuid: UUID
    public var name: String
    public var species: String?
//
    public init(
        uuid: UUID = UUID(),
        name: String,
        species: String? = nil
    ) {
        self.uuid = uuid
        self.name = name
        self.species = species
    }
}

extension Array where Element == Plant {
    public static var mock: [Plant] {
        [
            Plant(
                name: "Grażyna",
                species: "Monstera Adansonii"
            ),
            Plant(
                name: "Dziad"
            ),
            Plant(
                name: "Sansevieria",
                species: "Sansevieria"
            )
        ]
    }
}

extension Plant {
    public init?(record: CKRecord) {
        guard record.recordType == "Plant",
            let uuid = UUID(uuidString: record.recordID.recordName),
            let name = record["name"] as? String
            else { return nil }

        self.uuid = uuid
        self.name = name
        self.species = record["species"] as? String
    }

    public var ckRecord: CKRecord {
        let recordID = CKRecord.ID(recordName: self.uuid.uuidString)
        let record = CKRecord(recordType: "Plant", recordID: recordID)
        record["name"] = name
        record["species"] = species
        return record
    }
}
