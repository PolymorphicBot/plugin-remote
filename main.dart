import "dart:async";
import "dart:convert";
import "dart:io";

import "package:polymorphic_bot/api.dart";

BotConnector bot;
ServerSocket serverSocket;
Plugin plugin;
List<SocketClient> clients = [];

void main(List<String> args, Plugin myPlugin) {
  plugin = myPlugin;
  print("[Remote] Loading Plugin");
  bot = plugin.getBot();

  runZoned(() {
    ServerSocket.bind("0.0.0.0", 8031).then((server) {
      serverSocket = server;
      
      serverSocket.listen(handleSocket);
    });
  }, onError: (error) {
    if (error is SocketException) {
      print("[Remote] ${error.address.address}: ${error.message}");
    }
  });
  
  plugin.onShutdown(() {
    clients.forEach((it) {
      it.sendEvent({
        "event": "client-die"
      });
      
      it.socket.close();
    });
    serverSocket.close();
  });
}

void handleSocket(Socket socket) {
  print("[Remote] Client Connected (Address: ${socket.address.address})");
  var client = new SocketClient(socket);
  clients.add(client);
  
  socket.transform(UTF8.decoder).listen((String data) {
    var json = JSON.decode(data);
    
    if (json is! Map) {
      client.send({
        "type": "error",
        "message": "JSON must be a map!"
      });
      return;
    }
    
    String type = json['type'];
    
    switch (type) {
      case "register":
        var event = json['event'];
        plugin.on(event).listen((event) {
          client.sendEvent(event);
        });
        break;
      default:
        client.send({
          "type": "error",
          "message": "Invalid Request: Type not recognized."
        });
        break;
    }
  });
}

class SocketClient {
  final Socket socket;
  
  SocketClient(this.socket);
  
  void send(Map<String, dynamic> data) {
    socket.writeln(JSON.encode(data));
  }
  
  void sendEvent(Map data) {
    send({
      "type": "event",
      "data": data
    });
  }
}