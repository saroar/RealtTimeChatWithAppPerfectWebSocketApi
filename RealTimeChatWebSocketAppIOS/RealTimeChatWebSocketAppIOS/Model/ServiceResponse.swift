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


