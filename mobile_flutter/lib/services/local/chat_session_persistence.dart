import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

import '../../models/chat_session_summary.dart';
import '../../screens/chat/chatbot_screen.dart';
import '../../store/chat_snapshot_codec.dart';

class ChatSessionPersistence {
  ChatSessionPersistence._();

  static final ChatSessionPersistence instance = ChatSessionPersistence._();

  static const String _databaseName = 'civil_complaint_sessions_v1.db';
  static const int _databaseVersion = 1;
  static const String _sessionsTable = 'chat_sessions';
  static const String _snapshotsTable = 'chat_snapshots';

  sqflite.Database? _db;
  Future<void>? _initFuture;

  Future<void> initialize() {
    _initFuture ??= _initializeInternal();
    return _initFuture!;
  }

  Future<void> _initializeInternal() async {
    final factory = _resolveDatabaseFactory();
    final dbDirectory = await factory.getDatabasesPath();
    final dbPath = p.join(dbDirectory, _databaseName);

    _db = await factory.openDatabase(
      dbPath,
      options: sqflite.OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE $_sessionsTable (
              account_id TEXT NOT NULL,
              session_id TEXT NOT NULL,
              title TEXT NOT NULL,
              last_message TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              status TEXT NOT NULL,
              step_label TEXT NOT NULL,
              unread_count INTEGER NOT NULL,
              case_id TEXT,
              PRIMARY KEY (account_id, session_id)
            )
          ''');
          await database.execute('''
            CREATE INDEX idx_sessions_account_updated
            ON $_sessionsTable(account_id, updated_at DESC)
          ''');

          await database.execute('''
            CREATE TABLE $_snapshotsTable (
              account_id TEXT NOT NULL,
              session_id TEXT NOT NULL,
              snapshot_json TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              PRIMARY KEY (account_id, session_id)
            )
          ''');
        },
      ),
    );
  }

  sqflite.DatabaseFactory _resolveDatabaseFactory() {
    if (kIsWeb) {
      return sqflite.databaseFactory;
    }
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      sqflite_ffi.sqfliteFfiInit();
      return sqflite_ffi.databaseFactoryFfi;
    }
    return sqflite.databaseFactory;
  }

  Future<sqflite.Database> _database() async {
    await initialize();
    final db = _db;
    if (db == null) {
      throw StateError('ChatSessionPersistence database is not initialized.');
    }
    return db;
  }

  Future<void> saveSessionSummary(
    String accountId,
    ChatSessionSummary summary,
  ) async {
    final db = await _database();
    final payload = summary.toJson();

    await db.insert(
      _sessionsTable,
      <String, Object?>{
        'account_id': accountId,
        'session_id': summary.sessionId,
        'title': payload['title'],
        'last_message': payload['lastMessage'],
        'updated_at': payload['updatedAt'],
        'status': payload['status'],
        'step_label': payload['stepLabel'],
        'unread_count': payload['unreadCount'],
        'case_id': payload['caseId'],
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatSessionSummary>> loadSessionSummaries(
      String accountId) async {
    final db = await _database();
    final rows = await db.query(
      _sessionsTable,
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
      orderBy: 'updated_at DESC',
    );

    return rows.map((row) {
      return ChatSessionSummary.fromJson(<String, Object?>{
        'sessionId': row['session_id'],
        'title': row['title'],
        'lastMessage': row['last_message'],
        'updatedAt': row['updated_at'],
        'status': row['status'],
        'stepLabel': row['step_label'],
        'unreadCount': row['unread_count'],
        'caseId': row['case_id'],
      });
    }).toList(growable: false);
  }

  Future<void> saveSnapshot(
    String accountId,
    String sessionId,
    ChatbotScreenSnapshot snapshot,
  ) async {
    final db = await _database();
    final snapshotJson = jsonEncode(ChatSnapshotCodec.encode(snapshot));
    await db.insert(
      _snapshotsTable,
      <String, Object?>{
        'account_id': accountId,
        'session_id': sessionId,
        'snapshot_json': snapshotJson,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, ChatbotScreenSnapshot>> loadSnapshots(
    String accountId,
  ) async {
    final db = await _database();
    final rows = await db.query(
      _snapshotsTable,
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );

    final snapshots = <String, ChatbotScreenSnapshot>{};
    for (final row in rows) {
      final sessionId = row['session_id']?.toString();
      final rawJson = row['snapshot_json']?.toString();
      if (sessionId == null || sessionId.isEmpty) continue;
      if (rawJson == null || rawJson.isEmpty) continue;

      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is! Map<String, dynamic>) continue;
        snapshots[sessionId] =
            ChatSnapshotCodec.decode(decoded.cast<String, Object?>());
      } catch (_) {
        // Skip corrupted rows and continue loading others.
      }
    }
    return snapshots;
  }

  Future<void> deleteSnapshot(String accountId, String sessionId) async {
    final db = await _database();
    await db.delete(
      _snapshotsTable,
      where: 'account_id = ? AND session_id = ?',
      whereArgs: <Object?>[accountId, sessionId],
    );
  }

  Future<void> deleteSession(String accountId, String sessionId) async {
    final db = await _database();
    await db.delete(
      _sessionsTable,
      where: 'account_id = ? AND session_id = ?',
      whereArgs: <Object?>[accountId, sessionId],
    );
    await db.delete(
      _snapshotsTable,
      where: 'account_id = ? AND session_id = ?',
      whereArgs: <Object?>[accountId, sessionId],
    );
  }

  Future<void> clearAccount(String accountId) async {
    final db = await _database();
    await db.delete(
      _sessionsTable,
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );
    await db.delete(
      _snapshotsTable,
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );
  }
}
