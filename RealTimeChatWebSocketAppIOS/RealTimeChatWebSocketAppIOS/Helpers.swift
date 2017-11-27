//
//  Helpers.swift
//  RealTimeChatWebSocketAppIOS
//
//  Created by Alif on 27/11/2017.
//  Copyright © 2017 Alif. All rights reserved.
//

import Foundation

extension Encodable {
    var jsonData: Data? {
        let encoder = JSONEncoder()
        do {
            return try encoder.encode(self)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    var jsonString: String? {
        guard let data = self.jsonData else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension Decodable {
    static func from(json: String, using encoding: String.Encoding = .utf8) -> Self? {
        guard let data = json.data(using: encoding) else { return nil }
        return Self.from(data: data)
    }
    
    static func from(data: Data) -> Self? {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(Self.self, from: data)
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
    }
}

// May be 
//extension Encodable {
//    func encode(data: Data) throws -> Data {
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted
//        return try encoder.encode(self)
//    }
//}
//
//extension Decodable {
//    func decode(data: Data) throws -> Self {
//        let decoder = JSONDecoder()
//        return try decoder.decode(Self.self, from: data)
//    }
//}

