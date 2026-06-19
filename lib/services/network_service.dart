import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/user_role.dart';
import '../globals.dart';

typedef OnMessageReceived = void Function(Map<String, dynamic> data);
typedef OnErrorCallback = void Function(String error);

class NetworkService {
  final UserRole role;
  final OnMessageReceived onMessageReceived;
  final OnErrorCallback onError;

  // Server state
  HttpServer? _server;
  final List<WebSocketChannel> _clients = [];

  // Client state
  WebSocketChannel? _clientChannel;

  NetworkService({
    required this.role,
    required this.onMessageReceived,
    required this.onError,
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
      webSocket.stream.listen(
        (message) {
          final data = jsonDecode(message);
          onMessageReceived(data);
          
          for (final client in _clients) {
            if (client != webSocket) {
              client.sink.add(message);
            }
          }
        },
        onDone: () {
          _clients.remove(webSocket);
        },
        onError: (e) {
          _clients.remove(webSocket);
        },
      );
    });

    router.get('/ws', wsHandler);

    final pipeline = const Pipeline().addHandler(router.call);

    try {
      _server = await io.serve(pipeline, InternetAddress.anyIPv4, 8080);
      print('Host Server running on port ${_server!.port}');
    } catch (e) {
      print('Error starting server: $e');
    }
  }

  Future<void> _connectAsClient() async {
    try {
      final wsUrl = Uri.parse('ws://$serverIp:8080/ws');
      _clientChannel = WebSocketChannel.connect(wsUrl);
      
      _clientChannel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          onMessageReceived(data);
        },
        onError: (error) {
          print('WebSocket Client Error: $error');
          onError('Sunucuya bağlanılamadı. Ana bilgisayar açık mı?');
        },
        onDone: () {
          print('WebSocket Client Disconnected');
          onError('Sunucu bağlantısı koptu.');
        },
      );
    } catch (e) {
      print('Error connecting to Host: $e');
      onError('Sunucuya bağlanılamadı. Ana bilgisayar açık mı?');
    }
  }

  void sendMessage(Map<String, dynamic> data) {
    try {
      final message = jsonEncode(data);
      
      if (role == UserRole.admin) {
        for (final client in _clients) {
          client.sink.add(message);
        }
      } else {
        _clientChannel?.sink.add(message);
      }
    } catch (e) {
      print('Message send error: $e');
    }
  }

  void dispose() {
    _server?.close(force: true);
    for (final client in _clients) {
      client.sink.close();
    }
    _clientChannel?.sink.close();
  }
}
