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
    
}

extension ServerMessage {
    enum CodingKeys: String, CodingKey {
        case message = "msg"
        case request = "request"
    }
}
