//
//  RKCodableNameSpace.swift
//  CodableMacro
//
//  Created by zhenhua.lv on 2025/11/24.
//

import Foundation

public struct RKCodableNameSpace<Base> {
    let base: Base.Type
}

public extension Decodable {
    static var rk: RKCodableNameSpace<Self> {
        return RKCodableNameSpace(base: self)
    }
}

public extension RKCodableNameSpace where Base: Decodable {
    /// from Data Decode
    /// - Parameter data: JSON
    /// - Returns: convert Model
    func decode(from data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> Base {
        return try decoder.decode(Base.self, from: data)
    }

    /// from JSON String Decode
    /// - Parameter jsonString: JSON string
    /// - Returns: convert Model
    func decode(from jsonString: String, decoder: JSONDecoder = JSONDecoder()) throws -> Base {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "RKNamespace", code: -1, userInfo: [NSLocalizedDescriptionKey: "can not convert string to Data"])
        }
        return try decode(from: data, decoder: decoder)
    }
}
