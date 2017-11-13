//
//  ServerMessage.swift
//  RealTimeChatWebSocketAppIOS
//
//  Created by Alif on 13/11/2017.
//  Copyright © 2017 Alif. All rights reserved.
//

import Foundation

struct ServerMessage: Codable {
    let message: String
    let request: String
}

extension ServerMessage {
    static func from(json: String, using encoding: String.Encoding = .utf8) -> ServerMessage? {
        guard let data = json.data(using: encoding) else { return nil }
        return ServerMessage.from(data: data)
    }
    
    static func from(data: Data) -> ServerMessage? {
        let decoder = JSONDecoder()
        return try? decoder.decode(ServerMessage.self, from: data)
    }
    
    var jsonData: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
    
    var jsonString: String? {
        guard let data = self.jsonData else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension ServerMessage {
    enum CodingKeys: String, CodingKey {
        case message = "msg"
        case request = "request"
    }
}
