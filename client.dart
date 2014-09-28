import "dart:io";
import "dart:convert";

void main() {
  Socket.connect("127.0.0.1", 8031).then((socket) {
    socket.transform(UTF8.decoder).transform(new LineSplitter()).listen((String line) {
      print(line);
    });
    
    socket.write(JSON.encode({
      "type": "register",
      "event": "message"
    }));
  });
}