import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class ChatProvider extends ChangeNotifier {
  String? myId;
  String? _currentRoom;

  // room_id → list of messages
  final Map<String, List<Map<String, dynamic>>> _history = {};
  Map<String, List<Map<String, dynamic>>> get groupChatHistory => _history;

  void setMyId(String id) => myId = id;

  // ── Load history via REST ─────────────────────────────────────────────────
  Future<void> fetchHistory(String roomId) async {
    final raw = await ApiService.getChatHistory(roomId);
    _history[roomId] = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    notifyListeners();
  }

  Future<void> fetchGroupMessageHistory(String groupId) async {
    final roomId = 'group_$groupId';
    await fetchHistory(roomId);
  }

  // ── Connect WebSocket for a room ──────────────────────────────────────────
  Future<void> connectRoom(String roomId) async {
    if (_currentRoom == roomId) return;
    _currentRoom = roomId;

    wsService.disconnectChat();
    await wsService.connectChat(roomId);
    wsService.addChatListener(_onMessage);
  }

  Future<void> connectGroupRoom(String groupId) async {
    await connectRoom('group_$groupId');
  }

  void _onMessage(String event, Map<String, dynamic> data) {
    if (event == 'new_message') {
      final roomId = data['room_id'] as String? ?? '';
      data['isMe'] = data['sender_id'] == myId;
      data['timestamp'] = data['timestamp'] ?? DateTime.now().toIso8601String();
      _history.putIfAbsent(roomId, () => []).add(data);
      notifyListeners();
    }
  }

  // ── Send DM ───────────────────────────────────────────────────────────────
  void sendMessage(String roomId, String text) {
    wsService.sendChatMessage(text);
  }

  // ── Send group message ────────────────────────────────────────────────────
  void sendGroupMessage(String groupId, String text) {
    wsService.sendChatMessage(text, groupId: groupId);
  }

  void disconnect() {
    wsService.disconnectChat();
    _currentRoom = null;
  }
}
