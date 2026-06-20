import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/user_role.dart';
import '../globals.dart';
import 'logger_service.dart';

typedef OnMessageReceived = void Function(Map<String, dynamic> data);
typedef OnErrorCallback = void Function(String error);

typedef OnConnectedCallback = void Function();

class NetworkService {
  final UserRole role;
  final OnMessageReceived onMessageReceived;
  final OnErrorCallback onError;
  final OnConnectedCallback onConnected;

  // Server state
  HttpServer? _server;
  final List<WebSocketChannel> _clients = [];

  // Client state
  WebSocketChannel? _clientChannel;
  Timer? _reconnectTimer;
  bool _isConnected = false;

  NetworkService({
    required this.role,
    required this.onMessageReceived,
    required this.onError,
    required this.onConnected,
  });

  Future<void> start() async {
    if (role == UserRole.admin) {
      await _startServer();
    } else {
      await _connectAsClient();
    }
  }

  Future<void> _startServer() async {
    final router = Router();
    
    router.get('/health', (Request request) {
      return Response.ok('Server is running');
    });

    final wsHandler = webSocketHandler((WebSocketChannel webSocket) {
      _clients.add(webSocket);
      LoggerService.instance.info('Client connected. Total clients: ${_clients.length}');
      onConnected();
      
      webSocket.stream.listen(
        (message) {
          final data = jsonDecode(message);
          LoggerService.instance.info("Received data from client (Action: ${data['action']})");
          onMessageReceived(data);
          
          for (final client in _clients) {
            if (client != webSocket) {
              client.sink.add(message);
            }
          }
        },
        onDone: () {
          _clients.remove(webSocket);
          LoggerService.instance.info('Client disconnected. Total clients: ${_clients.length}');
        },
        onError: (e) {
          _clients.remove(webSocket);
          LoggerService.instance.error('Client error: $e. Total clients: ${_clients.length}');
        },
      );
    });

    router.get('/ws', wsHandler);

    final pipeline = const Pipeline().addHandler(router.call);

    try {
      _server = await io.serve(pipeline, InternetAddress.anyIPv4, 8080);
      LoggerService.instance.info('Host Server running on port ${_server!.port}');
    } catch (e) {
      LoggerService.instance.error('Error starting server: $e');
    }
  }

  Future<void> _connectAsClient() async {
    _tryConnect();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected) {
        _tryConnect();
      }
    });
  }

  void _tryConnect() {
    try {
      final wsUrl = Uri.parse('ws://$serverIp:8080/ws');
      _clientChannel = WebSocketChannel.connect(wsUrl);
      
      _isConnected = true;
      LoggerService.instance.info('Connected to host server at $wsUrl');
      onConnected();
      
      _clientChannel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          LoggerService.instance.info("Received data from server (Action: ${data['action']})");
          onMessageReceived(data);
        },
        onError: (error) {
          _isConnected = false;
          LoggerService.instance.error('Server connection error: $error');
          onError('Sunucuya bağlanılamadı. Yeniden deneniyor...');
        },
        onDone: () {
          _isConnected = false;
          LoggerService.instance.warning('Server connection closed');
          onError('Sunucu bağlantısı koptu. Yeniden deneniyor...');
        },
      );
    } catch (e) {
      _isConnected = false;
      LoggerService.instance.error('Connection failure: $e');
      onError('Bağlantı hatası: $e');
    }
  }

  void sendMessage(Map<String, dynamic> data) {
    try {
      final message = jsonEncode(data);
      
      if (role == UserRole.admin) {
        LoggerService.instance.info("Broadcasting to ${_clients.length} clients (Action: ${data['action']})");
        for (final client in _clients) {
          client.sink.add(message);
        }
      } else {
        if (_isConnected && _clientChannel != null) {
          LoggerService.instance.info("Sending data to server (Action: ${data['action']})");
          _clientChannel!.sink.add(message);
        } else {
          LoggerService.instance.warning('Attempted to send message but client is not connected');
        }
      }
    } catch (e) {
      LoggerService.instance.error('Message send error: $e');
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _server?.close(force: true);
    for (final client in _clients) {
      client.sink.close();
    }
    _clientChannel?.sink.close();
  }
}
