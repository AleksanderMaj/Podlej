//
//  CloudKitWrapper.swift
//  PodlejCommon
//
//  Created by Aleksander Maj on 16/05/2020.
//  Copyright © 2020 AleksanderMaj. All rights reserved.
//

import Foundation
import Combine
import CloudKit
import Models

public struct CloudKitWrapper {
    public enum FetchError: Error, Equatable {
        case unknown(String)
    }

    public enum CreateError: Error, Equatable {
        case decodingError
        case unknown(String)
    }

    let identifier: String

    public init(identifier: String = "iCloud.com.aleksandermaj.podlej-test") {
        self.identifier = identifier
    }

    public var fetchPlants: () -> Future<[Plant], FetchError> = {
        Future<[Plant], FetchError> { callback in
            let container = CKContainer(identifier: "iCloud.com.aleksandermaj.podlej-test")
            let db = container.privateCloudDatabase
            let query = CKQuery(
                recordType: CKRecord.RecordType("Plant"),
                predicate: NSPredicate(value: true)
            )
            db.perform(query, inZoneWith: nil) { (records, error) in
                if let error = error {
                    callback(.failure(.unknown(error.localizedDescription)))
                } else if let records = records {
                    let plants = records.compactMap(Plant.init(record:))
                    callback(.success(plants))
                } else {
                    callback(.failure(.unknown("Unknown")))
                }
            }
        }
    }

    public var createPlant: (Plant) -> Future<Plant, CreateError> = { plant in
        Future<Plant, CreateError> { callback in
            let container = CKContainer(identifier: "iCloud.com.aleksandermaj.podlej-test")
            let db = container.privateCloudDatabase

            db.save(plant.ckRecord) { (record, error) in
                if let error = error {
                    callback(.failure(.unknown(error.localizedDescription)))
                } else if let record = record {
                    if let plant = Plant(record: record) {
                        callback(.success(plant))
                    } else {
                        callback(.failure(.decodingError))
                    }
                } else {
                    callback(.failure(.unknown("Unkown")))
                }
            }
        }
    }
}

extension CloudKitWrapper {
    public static var mock: CloudKitWrapper {
        var wrapper = CloudKitWrapper()
        wrapper.fetchPlants = {
            Future<[Plant], FetchError> { callback in
                callback(.success(.mock))
            }
        }
        wrapper.createPlant = { plant in
            Future<Plant, CreateError> { callback in
                callback(.success(plant))
            }
        }
        return wrapper
    }
}
