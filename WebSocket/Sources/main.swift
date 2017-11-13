//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectWebSockets


// Create server
let server = HTTPServer()

// server webroot
server.documentRoot = "./webroot"

// Add our routes
//let routes = makeRoutes()
//server.addRoutes(routes)

let chatRoutes = addChatServerHandler()
server.addRoutes(chatRoutes)

// Listen on port 8181
server.serverPort = 8181

do {
	
	try server.start()

} catch PerfectError.networkError(let err, let msg) {

    print("Network error thrown: \(err) \(msg)")

}

