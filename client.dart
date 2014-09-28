import "dart:io";
import "dart:convert";

void main() {
  Socket.connect("127.0.0.1", 8031).then((socket) {
    socket.transform(UTF8.decoder).listen((data) {
      print(data);
    });
    
    socket.write(JSON.encode({
      "type": "register",
      "event": "message"
    }));
  });
}