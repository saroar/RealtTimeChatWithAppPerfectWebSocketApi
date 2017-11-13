//
//  ChatService.swift
//  RealTimeChatWebSocketAppIOS
//
//  Created by Alif on 13/11/2017.
//  Copyright © 2017 Alif. All rights reserved.
//

import Foundation
import Starscream

protocol ChatServiceDelegate: class {
    func newMessage(_ message: String)
    func setStatus(_ status: String)
}

typealias JSON = [String:Any]

struct WSParams {
    let channel: String
    var clientId: String?
    var messages: [String]
    var clients: [String]
}

struct ServerCommands {
    static let send = "send"
    static let register = "register"
}

class ChatService {
    
    let socket = WebSocket(url: URL(string: "ws://34.198.94.121:8181/api/v1/chat")!, protocols: ["chat"])
    var wsParams = WSParams(channel: "trial1", clientId: nil, messages: [], clients: [])
    var delegate: ChatServiceDelegate?
    
    deinit {
        socket.disconnect(forceTimeout: 0)
        socket.delegate = nil
    }
}

extension ChatService {
    
    func connect() {
        socket.delegate = self
        socket.connect()
    }
    
    func sendRequest(_ request: ServerRequest) {
        if let jsonRequest = request.jsonString {
            print("SENDING: " + jsonRequest)
            socket.write(string: jsonRequest)
        }
    }
    
    func sendMessage(_ message: String) {
        let request = ServerRequest(channelId: wsParams.channel, clientId: wsParams.clientId, command: ServerCommands.send, message: "iOS: \(message)")
        sendRequest(request)
    }
    
    func messageReceived(_ message: String) {
        delegate?.setStatus("")
        delegate?.newMessage(message)
    }
    
    func register(_ response: String) {
        guard let resp = ServerResponse.from(json: response, using: .utf16) else {
            return
        }
        
        delegate?.setStatus("Connection: \(resp.result)")
        wsParams.clientId = resp.params.clientId
        wsParams.messages = resp.params.messages
        wsParams.clients = resp.params.clientList
    }
}

// MARK: - WebSocketDelegate
extension ChatService : WebSocketDelegate {
    func websocketDidConnect(socket: WebSocketClient) {
        print("CONNECTED")
        delegate?.setStatus("CONNECTED")
        let request = ServerRequest(channelId: wsParams.channel, clientId: nil, command: ServerCommands.register, message: "joining channel "+wsParams.channel)
        sendRequest(request)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("DISCONNECTED")
        delegate?.setStatus("DISCONNECTED")
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("MESSAGE")
        guard let serverMessage = ServerMessage.from(json: text, using: .utf16) else {
            return
        }
        
        let message = serverMessage.message
        
        switch(serverMessage.request) {
        case "send":
            print("send message: \(message)")
            messageReceived(message)
            break;
        case "dispatch":
            delegate?.setStatus("")
            print("dispatch message: \(message)")
            break;
        case "client_list":
            print("client_list message: \(message)")
            break;
        case "client_add":
            print("client_add message: \(message)")
            break;
        case "client_remove":
            print("client_remove message: \(message)")
            break;
        case "register":
            print("register message: \(message)")
            register(message)
            break;
        default:
            print("default message: \(message)")
            break;
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("DATA")
    }
    
}
