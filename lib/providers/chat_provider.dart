import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../core/constants.dart';

class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.timestamp,
  });

  final String id;
  final String title;
  final int timestamp;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'timestamp': timestamp,
      };

  factory ChatSession.fromMap(Map map) => ChatSession(
        id: map['id'] as String,
        title: map['title'] as String,
        timestamp: map['timestamp'] as int,
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String sessionId;
  final String role; // 'user' | 'model'
  final String text;
  final int timestamp;

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'role': role,
        'text': text,
        'timestamp': timestamp,
      };

  factory ChatMessage.fromMap(Map map) => ChatMessage(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        role: map['role'] as String,
        text: map['text'] as String,
        timestamp: map['timestamp'] as int,
      );
}

final chatSessionsProvider =
    StateNotifierProvider<ChatSessionsNotifier, List<ChatSession>>((ref) {
  return ChatSessionsNotifier();
});

class ChatSessionsNotifier extends StateNotifier<List<ChatSession>> {
  ChatSessionsNotifier() : super(_load());

  static Box get _box => Hive.box(HiveBoxes.chatSessions);

  static List<ChatSession> _load() {
    final sessions =
        _box.values.cast<Map>().map(ChatSession.fromMap).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sessions;
  }

  Future<ChatSession> createSession({String title = 'New Session'}) async {
    final session = ChatSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await _box.put(session.id, session.toMap());
    state = [session, ...state];
    return session;
  }

  /// Persists an already-constructed session and adds it to state. Riverpod
  /// forbids mutating provider state synchronously during any widget's
  /// initState/build/dispose — callers that need a session id immediately
  /// (e.g. `ChatView.initState`) must construct the `ChatSession` locally
  /// and defer this call to a post-frame callback.
  void registerSession(ChatSession session) {
    unawaited(_box.put(session.id, session.toMap()));
    state = [session, ...state];
  }
}

/// Messages for a single session, kept sorted ascending by timestamp.
final messagesProvider = StateNotifierProvider.family<MessagesNotifier,
    List<ChatMessage>, String>((ref, sessionId) {
  return MessagesNotifier(sessionId);
});

class MessagesNotifier extends StateNotifier<List<ChatMessage>> {
  MessagesNotifier(this.sessionId) : super(_load(sessionId));

  final String sessionId;

  static Box get _box => Hive.box(HiveBoxes.messages);

  static List<ChatMessage> _load(String sessionId) {
    final messages = _box.values
        .cast<Map>()
        .map(ChatMessage.fromMap)
        .where((m) => m.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  Future<ChatMessage> addMessage({
    required String role,
    required String text,
  }) async {
    final message = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sessionId: sessionId,
      role: role,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await _box.put(message.id, message.toMap());
    state = [...state, message];
    return message;
  }

  /// Token-optimization: only the last [n] messages are ever sent as context.
  List<ChatMessage> lastN(int n) {
    if (state.length <= n) return state;
    return state.sublist(state.length - n);
  }
}
