////
////  WebSocketsHandler.swift
////  WebSocket
////
////  Created by Alif on 31/10/2017.
////
//
//import Foundation
//import PerfectLib
//import PerfectWebSockets
//import PerfectHTTP
//
//func makeRoutes() -> Routes {
//    var routes = Routes()
//
//    routes.add(method: .get, uri: "*", handler: { (request, response) in
//        StaticFileHandler(documentRoot: request.documentRoot).handleRequest(request: request, response: response)
//    })
//
//    routes.add(method: .get, uri: "/echo", handler: {
//        request, response in
//        WebSocketHandler(handlerProducer: {
//            (request: HTTPRequest, protocols: [String]) -> WebSocketSessionHandler? in
//            guard protocols.contains("echo") else { return nil }
//
//            return EchoHandler()
//        }).handleRequest(request: request, response: response)
//    })
//
//    return routes
//}
//
//class EchoHandler: WebSocketSessionHandler {
//    let socketProtocol: String? = "echo"
//
//    func handleSession(request: HTTPRequest, socket: WebSocket) {
//        socket.readStringMessage {
//            string, op, fin in
//
//            guard let string = string else {
//                socket.close()
//                return
//            }
//
//            print("Read msg: \(string) op: \(op) fin: \(fin)")
//
//            socket.sendStringMessage(string: string, final: true) {
//                self.handleSession(request: request, socket: socket)
//            }
//        }
//    }
//}
//
//
//
