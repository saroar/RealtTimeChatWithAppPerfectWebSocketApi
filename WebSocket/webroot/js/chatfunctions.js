
	function init() {
		output = document.getElementById("output");
		input = document.getElementById("chatinput");
		clients = document.getElementById("clients");
		requestJoin();
		myTimer = setInterval(pulse, 30000);
	}
	function requestJoin() {
    		connectWebsocket(ws_params.channel);
    	}
               
	function connectWebsocket(channel, clientid) {
		websocket = new WebSocket(wsUri);
		websocket.onopen = function(evt) { onOpen(evt) };
		websocket.onclose = function(evt) { onClose(evt) };
		websocket.onmessage = function(evt) { onMessage(evt) };
		websocket.onerror = function(evt) { onError(evt) };
	}

	function onOpen(evt) {
        
        console.log(ws_params);
		if(ws_params.client_id == undefined){
			writeToScreen("Connecting");
			valuetosend = {"cmd": "register", "msg": "joining channel "+ws_params.channel, "channelid":ws_params.channel};
        
		} else {
            console.log(evt.data);
			writeToScreen("CONNECTED: "+evt.data);
			valuetosend = {"cmd": "register", "msg": "registered "+ws_params.client_id, "clientid": ws_params.client_id, "channelid": ws_params.channel};
        
		}
		websocket.send(JSON.stringify(valuetosend));
        
        writeToScreen('<span style="color: red;">Registering hello from Saroar:'+ws_params.channel+' <\/span> ');
	}

	function onClose(evt) {
		writeToScreen("DISCONNECTED");
		clearInterval(myTimer)
	}

	function onMessage(evt) {
		json_data = JSON.parse(evt.data);
		msg = json_data["msg"];
		request = json_data["request"];
		switch(request) {
			case "send":
				writeToScreen('<span style="color: blue;">Received: ' + msg +'<\/span>');
				break;
			case "dispatch":
				writeToScreen('<span style="color: blue;">Received: ' + msg +'<\/span>');
				break;
			case "client_list":
				listClients(msg);
				break;
			case "client_add":
				addToClients(msg);
				break;
			case "client_remove":
				removeClient(msg);
				break;
			case "register":
				registerResponse(msg);
				break;
			default:
				writeToScreen('<span style="color: blue;">RESPONSE: ' + msg +' for request: '+request+'<\/span>');
		}
	}

	function onError(evt) {
		writeToScreen('<span style="color: red;">ERROR:<\/span> ' + evt.data);
	}

	function doSend() {
		writeToScreen('<span style="color: red;">SENDING:<\/span> ' + input.value);
        valuetosend = {"cmd": "send", "msg": input.value, "clientid": ws_params.client_id, "channelid": ws_params.channel};
        websocket.send(JSON.stringify(valuetosend));
	}

    function doEcho() {
        writeToScreen('<span style="color: red;">Echo:<\/span> ' + input.value);
        valuetosend = {"cmd": "echo", "msg": input.value, "clientid": ws_params.client_id, "channelid": ws_params.channel};
        websocket.send(JSON.stringify(valuetosend));
    }
     function pulse() {
	     
        valuetosend = {"cmd": "pulse", "msg": ".", "clientid": ws_params.client_id, "channelid": ws_params.channel};
        websocket.send(JSON.stringify(valuetosend));
	}
	
	function writeToScreen(message) {
		output.innerHTML += '<br>' +message;
	}
	
	function listClients(list) {
		
		clients.innerHTML = list.join('<br>')+'<br>';
	}
	function addToClients(message) {
		ws_params.client_list.push(message);
		
		clients.innerHTML = ws_params.client_list.join('<br>')+'<br>';
	}
	function removeClient(message) {
		//clientToRemove = JSON.parse(message);
		//clients_list = ws_params.clients.remove(clientToRemove);
		
		ws_params.client_list.splice(ws_params.client_list.indexOf(message), 1);
		clients.innerHTML = ws_params.client_list.join('<br>')+'<br>';
	}
	function registerResponse(response) {
		resp = JSON.parse(response);
		
		writeToScreen('<span style="color: blue;">Connection: '+resp["result"]+'<\/span>');
		ws_params.client_id = resp.params.client_id;
		ws_params.messages = resp.params.messages;
		if(resp.params.client_list != undefined){
			ws_params.client_list = resp.params.client_list
			listClients(ws_params.client_list)
		} else {
			ws_params.client_list = new Array();
		}
	}
