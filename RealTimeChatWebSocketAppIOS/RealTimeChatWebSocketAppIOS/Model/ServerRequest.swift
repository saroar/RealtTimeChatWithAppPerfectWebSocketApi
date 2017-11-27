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

}

extension ServerRequest {
    enum CodingKeys: String, CodingKey {
        case channelId = "channelid"
        case clientId  = "clientid"
        case command   = "cmd"
        case message   = "msg"
    }
}
