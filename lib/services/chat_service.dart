import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatService {
  WebSocketChannel? _ch;

  Stream<String> get stream => _ch!.stream.map((e) => e.toString());

  Future<void> connect({String? url}) async {
    final wsUrl = url ?? 'wss://echo.websocket.events';
    _ch = WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  void send(String text) => _ch?.sink.add(text);

  Future<void> disconnect() async {
    await _ch?.sink.close();
  }
}
