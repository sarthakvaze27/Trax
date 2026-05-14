import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef WsEventCallback = void Function(
    String event, Map<String, dynamic> data);

class WebSocketService {
  static const String _wsBase = 'ws://192.168.137.1:8000/ws';

  WebSocketChannel? _updateChannel;
  WebSocketChannel? _chatChannel;

  final List<WsEventCallback> _updateListeners = [];
  final List<WsEventCallback> _chatListeners = [];

  Timer? _pingTimer;
  bool _updatesConnected = false;
  bool _shouldReconnectUpdates = false;

  // ── Connect to global updates channel ────────────────────────────────────
  void connectUpdates() {
    _shouldReconnectUpdates = true;
    if (_updatesConnected) return;
    _updatesConnected = true;
    _updateChannel = WebSocketChannel.connect(Uri.parse('$_wsBase/updates'));
    _updateChannel!.stream.listen(
      (raw) {
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        final event = msg['event'] as String? ?? '';
        final data = msg['data'] as Map<String, dynamic>? ?? {};
        for (final cb in _updateListeners) {
          cb(event, data);
        }
      },
      onDone: () => _reconnectUpdates(),
      onError: (_) => _reconnectUpdates(),
    );

    // Ping every 25s to keep connection alive
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _updateChannel?.sink.add('ping');
    });
  }

  void _reconnectUpdates() {
    _updatesConnected = false;
    if (!_shouldReconnectUpdates) return;
    Future.delayed(const Duration(seconds: 3), connectUpdates);
  }

  void addUpdateListener(WsEventCallback cb) {
    if (!_updateListeners.contains(cb)) _updateListeners.add(cb);
  }

  void removeUpdateListener(WsEventCallback cb) => _updateListeners.remove(cb);

  // ── Connect to chat room ──────────────────────────────────────────────────
  Future<void> connectChat(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final uri = Uri.parse('$_wsBase/chat?token=$token&room=$roomId');
    _chatChannel = WebSocketChannel.connect(uri);

    _chatChannel!.stream.listen(
      (raw) {
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        final event = msg['event'] as String? ?? '';
        final data = msg['data'] as Map<String, dynamic>? ?? {};
        for (final cb in _chatListeners) {
          cb(event, data);
        }
      },
      onDone: () {},
      onError: (_) {},
    );
  }

  void sendChatMessage(String text, {String? groupId}) {
    final payload =
        jsonEncode({'text': text, if (groupId != null) 'group_id': groupId});
    _chatChannel?.sink.add(payload);
  }

  void addChatListener(WsEventCallback cb) => _chatListeners.add(cb);
  void removeChatListener(WsEventCallback cb) => _chatListeners.remove(cb);

  void disconnectChat() {
    _chatChannel?.sink.close();
    _chatChannel = null;
    _chatListeners.clear();
  }

  void dispose() {
    _shouldReconnectUpdates = false;
    _pingTimer?.cancel();
    _updateChannel?.sink.close();
    _chatChannel?.sink.close();
    _updatesConnected = false;
    _updateChannel = null;
    _chatChannel = null;
    _updateListeners.clear();
    _chatListeners.clear();
  }
}

// Singleton
final wsService = WebSocketService();
