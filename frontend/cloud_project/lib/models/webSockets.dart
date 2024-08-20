import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
  final String _url;
  bool _isConnected = false;
  Timer? _pingTimer;
  final Duration _pingInterval = const Duration(seconds: 30);

  final StreamController<dynamic> _messageStreamController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get messageStream => _messageStreamController.stream;

  WebSocketService(this._url);

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      _isConnected = true;
      _startPingTimer();

      _channel!.stream.listen(
        (message) {
          _messageStreamController.add(message);
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _stopPingTimer();
          _tryReconnect();
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _isConnected = false;
      _tryReconnect();
    }
  }

  void send(dynamic message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(message);
    } else {
      print('WebSocket is not connected. Cannot send message.');
    }
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
    }
    _isConnected = false;
    _stopPingTimer();
  }

  void _startPingTimer() {
    _pingTimer = Timer.periodic(_pingInterval, (_) => _sendPing());
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _sendPing() {
    send('ping');
  }

  void _tryReconnect() {
    Future.delayed(Duration(seconds: 5), () {
      if (!_isConnected) {
        print('Attempting to reconnect...');
        connect();
      }
    });
  }

  bool get isConnected => _isConnected;

  void dispose() {
    disconnect();
    _messageStreamController.close();
  }
}