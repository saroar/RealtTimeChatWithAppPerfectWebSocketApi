//
//  ChatServerHandlers.swift
//  WebSocket
//
//  Created by Alif on 31/10/2017.
//

import Foundation
import PerfectLib
import PerfectHTTP
import PerfectThread
import PerfectWebSockets


func addChatServerHandler() -> Routes {
    var routes = Routes()
    
    routes.add(method: .get, uri: "/echo", handler: WebSocketHandler(handlerProducer: { (request: HTTPRequest, protocals: [String]) -> WebSocketSessionHandler? in
        
        guard protocals.contains("echo") else {
            return nil
        }
        
        return EchoHandler()
        
        }).handleRequest
    )
    
    routes.add(method: .get, uri: "api/v1/chat", handler: WebSocketHandler(handlerProducer: { (request: HTTPRequest, protocals: [String]) -> WebSocketSessionHandler? in
        return ChatWSHandler()
    }).handleRequest
    )
    
    return routes
}

private let loopbackClientId = "LOOPBACK_CLIENT_IC"

class Channel {
    let channelName:String
    var clients = [String:ChannelClient]()
    //Timer setup   ** testing for usage behind proxy
    //              ** not sure if these need to be in main or elsewhere as they dont seem to fire in Channel object
    //var timer = Timer()
    //let timeInterval:TimeInterval = 10.0
    
    init(channelName: String) {
        self.channelName = channelName
        //timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(dispatchPulse), userInfo: "pulse transmit", repeats: true)
        
    }
    @objc func dispatchPulse() {
        Log.error(message: "Pulse sent")
        dispatchMessage(msg: "pulse", fromClientId: "999", request: "pulse")
        
    }
    func dispatchMessage(msg: String, fromClientId: String, request: String?) {
        
        do {
            var fullMsg: [String:Any] = ["msg":msg, "error":""]
            if let cmd:String = request {
                fullMsg["request"] = cmd
            }
            fullMsg["clientid"] = fromClientId
            let jsonCoded = try fullMsg.jsonEncodedString()
            
            for (id, client) in self.clients where id != fromClientId {
                client.socket?.sendStringMessage(string: jsonCoded, final: true) {}
            }
            
            if let sender = self.clients[fromClientId] {
                sender.socket?.sendStringMessage(string: "{\"msg\": \"Dispatch Completed\", \"request\": \"dispatch\" }", final: true) {}
            }
        } catch {
            print("Exception while dispatching message \(error)")
        }
        
    }
    
    func echoMessage(msg: String, fromClientId: String, request: String) {
        
        do {
            let fullMsg: [String:Any] = ["msg":msg, "error":"", "request": request]
            let jsonCoded = try fullMsg.jsonEncodedString()
            for (id, client) in self.clients where id == fromClientId {
                client.socket?.sendStringMessage(string: jsonCoded, final: true) {}
            }
        } catch {
            print("Exception while dispatching message \(error)")
        }
        
    }
    
    func addClient(client: ChannelClient) {
        
        self.removeClient(clientId: client.clientId)
        self.clients[client.clientId] = client
        
        if client.loopback && self.clients[loopbackClientId] == nil {
            self.addClient(client: ChannelClient(clientId: loopbackClientId, loopback: false))
        }
        self.dispatchMessage(msg: client.clientId, fromClientId: client.clientId, request: "client_add")
    }
    
    func assignSocket(clientId: String, socket: WebSocket) -> Bool {
        if let client = self.clients[clientId] {

            client.socket = socket
            Threading.dispatch(closure: {
                self.startRead(clientId: clientId)
            })
            return true
            
        }
        return false
    }
    
    func removeClient(clientId: String) {
        if let oldClient = self.clients[clientId] {
            oldClient.socket?.close()
            self.clients.removeValue(forKey: clientId)
            if self.clients.count == 0 {
                ChatWSHandler.removeChannel(channelName: self.channelName)
            } else {
                self.dispatchMessage(msg: clientId, fromClientId: "999", request: "client_remove")
            }
            
        }
    }
    
    func startRead(clientId: String) {
        if let client = self.clients[clientId] {
            return client.socket!.readStringMessage { string, opcode, final in
                guard let string = string else {
                    print("Channel \(self.channelName) client \(clientId) closing")
                    self.removeClient(clientId: clientId)
                    return
                }
                print("read msg: \(string) op: \(opcode) fin: \(final)")
                do {
                    if let decoded = try string.jsonDecode() as? Dictionary<String,Any> {
                        if let cmd = decoded["cmd"] as? String {
                            switch cmd {
                            case "send":
                                if let msg:String = decoded["msg"] as? String {
                                    do {
                                        if let decodedMsg:String = try msg.jsonDecode() as? String {
                                            let encoded = try decodedMsg.jsonEncodedString()
                                            self.dispatchMessage(msg: encoded, fromClientId: clientId, request: cmd)
                                            return self.startRead(clientId: clientId)
                                        }
                                    } catch {
                                        
                                        if let clientid = decoded["clientid"] as? String,
                                            let msg = decoded["msg"] as? String {
                                            self.dispatchMessage(msg: msg, fromClientId: clientid, request: cmd)
                                            return self.startRead(clientId: clientid)
                                            
                                        } else {
                                            
                                            self.dispatchMessage(msg: msg, fromClientId: clientId, request: cmd)
                                            return self.startRead(clientId: clientId)
                                            
                                        }
                                    }
                                }
                            case "echo":
                                if let msg = decoded["msg"] as? String {
                                    if let clientid = decoded["clientid"] as? String {
                                        self.echoMessage(msg: msg, fromClientId: clientid, request: cmd)
                                        return self.startRead(clientId: clientid)
                                    } else {
                                        self.echoMessage(msg: msg, fromClientId: clientId, request: cmd)
                                        return self.startRead(clientId: clientId)
                                    }
                                }
                            default: ()
                            Log.info(message: "pulse from client: \(clientId)")
                            return self.startRead(clientId: clientId)
                            }
                        }
                    }
                } catch {
                    print ("invalid msg from channel \(self.channelName) client \(clientId). Terminating client.")
                }
            }
        }
        self.removeClient(clientId: clientId)
    }
}



class ChatWSHandler: WebSocketSessionHandler {
    
    static var channelDict = [String:Channel]()
    
    let socketProtocol: String? = nil
    
    static func channel(named: String) -> Channel {
        
        if let channel = ChatWSHandler.channelDict[named] {
            return channel
        }
        print("adding Channel \(named)")
        
        let channel = Channel(channelName: named)
        ChatWSHandler.channelDict[named] = channel
        return channel
    }
    
    static func removeChannel(channelName:String){
        if let _ = ChatWSHandler.channelDict[channelName] {
            print("Removing Channel \(channelName)")
            ChatWSHandler.channelDict.removeValue(forKey: channelName)
            
        }
    }
    
    func handleSession(request req: HTTPRequest, socket: WebSocket) {
        print("ChatWSHandler new session")
        print("channels: \(ChatWSHandler.channelDict)");
        
    
        
        socket.readStringMessage { string, op, fin in
            guard let string = string else {
                socket.close()
                return
            }
            
            print("Read msg: \(string) op: \(op) fin: \(fin)")
            do {
                
                if let decodedDict = try string.jsonDecode() as? Dictionary<String,Any> {
                    
                    print("WS received \(decodedDict)")
                    
                    if let cmd = decodedDict["cmd"] as? String {
                        switch cmd {
                        case "register":
                            if let channelid = decodedDict["channelid"] as? String,
                                let clientid = decodedDict["clientid"] as? String {
                                let channel = ChatWSHandler.channel(named: channelid)
                                if channel.assignSocket(clientId: clientid, socket: socket) {
                                    if let msg = decodedDict["msg"] as? String{
                                        channel.echoMessage(msg: msg, fromClientId: clientid, request: cmd)
                                    }
                                    return
                                }
                                
                            } else if let channelid = decodedDict["channelid"] as? String {
                                let channel = ChatWSHandler.channel(named: channelid)
                                let clientid = UUID().string
                                
                                
                                print("ws Join \(channelid) \(clientid)")
                                
                                var msgParams:[String:Any] = [
                                    "client_id":clientid,
                                    "channel_id":channelid,
                                    "messages":[Any](),
                                    ]
                                if channel.clients.count > 0 {
                                    msgParams["client_list"] = Array(channel.clients.keys)
                                }
                                let msgDict: [String:Any] = [
                                    "params": msgParams,
                                    "result":"Success"
                                ]
                                
                                let msgDictStr = try msgDict.jsonEncodedString()
                                let loopback = false
                                channel.addClient(client: ChannelClient(clientId: clientid, loopback: loopback))
                                
                                if channel.assignSocket(clientId: clientid, socket: socket) {
                                    channel.echoMessage(msg: msgDictStr, fromClientId: clientid, request: cmd)
                                    
                                    return
                                }
                            }
                        case "echo":
                            if let channelid = decodedDict["channelid"] as? String,
                                let clientid = decodedDict["clientid"] as? String,
                                let msg = decodedDict["msg"] as? String {
                                let channel = ChatWSHandler.channel(named: channelid)
                                channel.echoMessage(msg: msg, fromClientId: clientid, request: cmd)
                                return
                                
                            }
                        case "channel_list":
                            if let channelid = decodedDict["channelid"] as? String,
                                let clientid = decodedDict["clientid"] as? String {
                                let channelList = try ChatWSHandler.channelDict.jsonEncodedString()
                                let channel = ChatWSHandler.channel(named: channelid)
                                channel.echoMessage(msg: channelList, fromClientId: clientid, request: cmd)
                                return
                            }
                        case "client_list":
                            if let channelid = decodedDict["channelid"] as? String,
                                let clientid = decodedDict["clientid"] as? String {
                                let channel = ChatWSHandler.channel(named: channelid)
                                
                                let clientlist = try channel.clients.jsonEncodedString()
                                channel.echoMessage(msg: clientlist, fromClientId: clientid, request: cmd)
                                return
                            }
                        case "update_handle":
                            if let newhandle = decodedDict["client_handle"] as? String,
                                let clientid = decodedDict["clientid"] as? String,
                                let channelid = decodedDict["channelid"] as? String,
                                let channel = ChatWSHandler.channelDict[channelid]
                            {
                                if let client = channel.clients[clientid] {
                                    client.clientHandle = newhandle
                                }
                            }
                        default:
                            ()
                        }
                    }
                    
                }
            } catch {
                print("Exception handling message")
            }
            socket.close()
        }
    }
    
}

//public method that is being called by the server framework to initialise your module.
public func PerfectServerModuleInit() {
    
}

//Create a handler for index Route
func indexHandler(_ request: HTTPRequest, response: HTTPResponse) {
    
    response.appendBody(string: "<html><body>Raw request handler: You requested path \(request.path) with content-type \(String(describing: request.header(HTTPRequestHeader.Name.contentType))) and POST body \(String(describing: request.postBodyString))</body></html>")
    response.completed()
}
func generateClientId() -> String {
    return UUID().string.lowercased()
    //return NSUUID().UUIDString.lowercaseString
}

// A WebSocket service handler must implement the `WebSocketSessionHandler` protocol.
// This protocol requires the function `handleSession(request: HTTPRequest, socket: WebSocket)`.
// This function will be called once the WebSocket connection has been established,
// at which point it is safe to begin reading and writing messages.
//
// The initial `HTTPRequest` object which instigated the session is provided for reference.
// Messages are transmitted through the provided `WebSocket` object.
// Call `WebSocket.sendStringMessage` or `WebSocket.sendBinaryMessage` to send data to the client.
// Call `WebSocket.readStringMessage` or `WebSocket.readBinaryMessage` to read data from the client.
// By default, reading will block indefinitely until a message arrives or a network error occurs.
// A read timeout can be set with `WebSocket.readTimeoutSeconds`.
// When the session is over call `WebSocket.close()`.
class EchoHandler: WebSocketSessionHandler {
    
    // The name of the super-protocol we implement.
    // This is optional, but it should match whatever the client-side WebSocket is initialized with.
    let socketProtocol: String? = "echo"
    
    // This function is called by the WebSocketHandler once the connection has been established.
    func handleSession(request: HTTPRequest, socket: WebSocket) {
        
        // Read a message from the client as a String.
        // Alternatively we could call `WebSocket.readBytesMessage` to get binary data from the client.
        socket.readStringMessage {
            // This callback is provided:
            //    the received data
            //    the message's op-code
            //    a boolean indicating if the message is complete (as opposed to fragmented)
            string, op, fin in
            
            // The data parameter might be nil here if either a timeout or a network error, such as the client disconnecting, occurred.
            // By default there is no timeout.
            guard let string = string else {
                // This block will be executed if, for example, the browser window is closed.
                socket.close()
                return
            }
            
            // Print some information to the console for informational purposes.
            print("Read msg: \(string) op: \(op) fin: \(fin)")
            
            // Echo the data we received back to the client.
            // Pass true for final. This will usually be the case, but WebSockets has the concept of fragmented messages.
            // For example, if one were streaming a large file such as a video, one would pass false for final.
            // This indicates to the receiver that there is more data to come in subsequent messages but that all the data is part of the same logical message.
            // In such a scenario one would pass true for final only on the last bit of the video.
            socket.sendStringMessage(string: string, final: true) {
                
                // This callback is called once the message has been sent.
                // Recurse to read and echo new message.
                self.handleSession(request: request, socket: socket)
            }
        }
    }
}

// ****** Http interface methods ******
/*
 //Join Channel
 func joinHandler(_ request: HTTPRequest, response: HTTPResponse) {
 defer {
 response.completed()
 }
 guard let channelId = request.urlVariables["channelid"] else {
 //response.status.code = 400
 response.appendBody(string: "Channel Id must be specified.")
 return
 }
 do {
 let clientId = generateClientId()
 let loopback = request.param(name: "debug") == "loopback"
 print("Join Handler \(channelId) \(clientId)")
 
 let msgDict: [String:Any] = [
 "params": [
 "client_id":clientId,
 "channel_id":channelId,
 "messages":[Any](),
 ] as [String:Any],
 "result":"Success"
 ]
 
 let msgDictStr = try msgDict.jsonEncodedString()
 response.appendBody(string: msgDictStr)
 
 let channel = ChatWSHandler.channel(named: channelId)
 channel.addClient(client: ChannelClient(clientId: clientId, loopback: loopback))
 }  catch {
 print("Unknown Exception \(error)")
 }
 }
 func messageHandler(_ request: HTTPRequest, response: HTTPResponse) {
 print("messageHandler before guard \(request.urlVariables)")
 guard let channelId = request.urlVariables["channelid"],
 clientId = request.urlVariables["clientid"],
 channel = ChatWSHandler.channelDict[channelId] else {
 //response.status.code = 400
 response.completed()
 return
 }
 let postBody = request.postBodyString
 print("messageHandler \(channelId) \(clientId) \(postBody)")
 channel.dispatchMessage(msg: postBody!, fromClientId: clientId, request: nil)
 
 response.appendBody(string: "{\"result\":\"SUCCESS\"}")
 response.completed()
 }
 func leaveHandler(_ request: HTTPRequest, response: HTTPResponse) {
 guard let channelId = request.urlVariables["channelid"],
 clientId = request.urlVariables["clientid"],
 channel = ChatWSHandler.channelDict[channelId] else {
 //response.status.code = 400
 response.completed()
 return
 }
 print("LeaveHandler \(channelId) \(clientId)")
 channel.removeClient(clientId: clientId)
 
 response.appendBody(string: "{\"result\":\"SUCCESS\"}")
 response.completed()
 }
 func channelHandler(_ request: HTTPRequest, response: HTTPResponse) {
 response.appendBody(string: "<html><body>Raw Channel handler: You requested to path \(request.path) with content-type \(request.header(HTTPRequestHeader.Name.contentType)) and POST body \(request.postBodyString)</body></html>")
 response.completed()
 }
 */



class ChannelClient {
    var socket: WebSocket?
    let clientId: String
    var clientHandle: String?
    let loopback: Bool
    
    init(clientId: String, loopback: Bool) {
        self.clientId = clientId
        self.loopback = loopback
    }
}






































