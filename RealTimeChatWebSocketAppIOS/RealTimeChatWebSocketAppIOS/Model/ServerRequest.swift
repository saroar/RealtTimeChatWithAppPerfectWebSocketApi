//
//  ServerRequest.swift
//  RealTimeChatWebSocketAppIOS
//
//  Created by Alif on 13/11/2017.
//  Copyright © 2017 Alif. All rights reserved.
//

import Foundation

struct ServerRequest: Codable {
    let channelId: String
    let clientId: String?
    let command: String
    let message: String
}

extension ServerRequest {
    static func from(json: String, using encoding: String.Encoding = .utf8) -> ServerRequest? {
        guard let data = json.data(using: encoding) else { return nil }
        return ServerRequest.from(data: data)
    }
    
    static func from(data: Data) -> ServerRequest? {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(ServerRequest.self, from: data)
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

extension ServerRequest {
    enum CodingKeys: String, CodingKey {
        case channelId = "channelid"
        case clientId  = "clientid"
        case command   = "cmd"
        case message   = "msg"
    }
}
