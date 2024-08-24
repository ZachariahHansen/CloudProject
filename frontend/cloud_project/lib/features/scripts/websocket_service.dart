import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
import 'dart:io';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamController<dynamic> _messageController = StreamController<dynamic>.broadcast();
  bool _isConnected = false;
  Timer? _reconnectionTimer;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 5;

  Stream<dynamic> get messageStream => _messageController.stream;

  Future<void> connect(String url, String userId) async {
    if (_isConnected) return;

    try {
      print('Attempting to connect to WebSocket: $url?userid=$userId');
      final uri = Uri.parse('$url?userid=$userId');
      
      _channel = WebSocketChannel.connect(uri);
      
      print('Waiting for WebSocket connection...');
      await _channel!.ready;
      
      _isConnected = true;
      _reconnectAttempts = 0;
      print('WebSocket connected successfully');

      _channel!.stream.listen(
        (message) {
          print('Received message: $message');
          _messageController.add(json.decode(message));
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _handleConnectionError(url, userId, error);
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleConnectionClosed(url, userId);
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      if (e is WebSocketException) {
        print('WebSocket exception details: ${e.message}');
      } else if (e is SocketException) {
        print('Socket exception details: ${e.message}');
      }
      _handleConnectionError(url, userId, e);
    }
  }

  void _handleConnectionError(String url, String userId, dynamic error) {
    _isConnected = false;
    if (_reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
      _reconnect(url, userId);
    } else {
      print('Max reconnection attempts reached. Please check your connection and try again later.');
    }
  }

  void _handleConnectionClosed(String url, String userId) {
    _isConnected = false;
    if (_reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
      _reconnect(url, userId);
    } else {
      print('WebSocket connection closed and max reconnection attempts reached.');
    }
  }

  void _reconnect(String url, String userId) {
    _reconnectionTimer?.cancel();
    _reconnectAttempts++;
    print('Attempting to reconnect (Attempt $_reconnectAttempts of $MAX_RECONNECT_ATTEMPTS)');
    _reconnectionTimer = Timer(Duration(seconds: 5), () {
      connect(url, userId);
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected) {
      print('Sending message: ${json.encode(message)}');
      _channel?.sink.add(json.encode(message));
    } else {
      print('Cannot send message: WebSocket is not connected');
    }
  }

  Future<void> dispose() async {
    print('Disposing WebSocketService');
    await _channel?.sink.close(status.goingAway);
    await _messageController.close();
    _reconnectionTimer?.cancel();
  }
}