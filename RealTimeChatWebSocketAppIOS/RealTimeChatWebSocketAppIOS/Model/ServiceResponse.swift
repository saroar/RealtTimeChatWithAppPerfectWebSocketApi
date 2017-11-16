//
//  ServiceResponse.swift
//  RealTimeChatWebSocketAppIOS
//
//  Created by Alif on 13/11/2017.
//  Copyright © 2017 Alif. All rights reserved.
//

import Foundation

struct ServerResponse: Codable {
    let params: Params
    let result: String
}

struct Params: Codable {
    let clientId: String
    let clientList: [String]
    let messages: [String]
}

extension ServerResponse {
    static func from(json: String, using encoding: String.Encoding = .utf8) -> ServerResponse? {
        guard let data = json.data(using: encoding) else { return nil }
        return ServerResponse.from(data: data)
    }
    
    static func from(data: Data) -> ServerResponse? {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(ServerResponse.self, from: data)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
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

extension ServerResponse {
    enum CodingKeys: String, CodingKey {
        case params = "params"
        case result = "result"
    }
}

extension Params {
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientList = "client_list"
        case messages = "messages"
    }
}


