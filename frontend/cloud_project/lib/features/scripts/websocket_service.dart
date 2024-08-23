import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal();

  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<void> connect(String url) async {
    if (_channel != null) return;

    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel!.stream.listen(
      (message) {
        final data = json.decode(message);
        _messageController.add(data);
      },
      onError: (error) {
        print('WebSocket error: $error');
        reconnect(url);
      },
      onDone: () {
        print('WebSocket connection closed');
        reconnect(url);
      },
    );
  }

  void send(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(json.encode(message));
    }
  }

  void reconnect(String url) {
    Future.delayed(Duration(seconds: 5), () => connect(url));
  }

  void dispose() {
    _channel?.sink.close();
    _messageController.close();
  }
}