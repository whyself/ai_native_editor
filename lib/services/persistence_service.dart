import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kWorkspace = 'persist_workspace';
const _kPaneTree = 'persist_pane_tree';
const _kLayout = 'persist_layout';
const _kChatSessions = 'persist_chat_sessions';
const _kActiveSession = 'persist_active_session';

/// Thin wrapper around [SharedPreferences] that caches the instance after
/// [init()] so all providers can read synchronously inside their [build()].
class PersistenceService {
  PersistenceService._();
  static final PersistenceService instance = PersistenceService._();

  SharedPreferences? _prefs;

  /// Must be awaited before [runApp]. Initialises the SharedPreferences cache.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'PersistenceService.init() must be awaited first');
    return _prefs!;
  }

  // ── Workspace ────────────────────────────────────────────────────────────

  Future<void> saveWorkspace(List<String> paths) async {
    try {
      await _p.setString(_kWorkspace, jsonEncode(paths));
    } catch (_) {}
  }

  List<String>? loadWorkspace() {
    try {
      final raw = _p.getString(_kWorkspace);
      if (raw == null) return null;
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return null;
    }
  }

  // ── Pane tree ─────────────────────────────────────────────────────────────

  Future<void> savePaneTree(Map<String, dynamic> json) async {
    try {
      await _p.setString(_kPaneTree, jsonEncode(json));
    } catch (_) {}
  }

  Map<String, dynamic>? loadPaneTree() {
    try {
      final raw = _p.getString(_kPaneTree);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Layout ────────────────────────────────────────────────────────────────

  Future<void> saveLayout(Map<String, dynamic> json) async {
    try {
      await _p.setString(_kLayout, jsonEncode(json));
    } catch (_) {}
  }

  Map<String, dynamic>? loadLayout() {
    try {
      final raw = _p.getString(_kLayout);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Chat sessions ─────────────────────────────────────────────────────────

  Future<void> saveChatSessions(
    List<Map<String, dynamic>> sessionsJson,
    String activeSessionId,
  ) async {
    try {
      await _p.setString(_kChatSessions, jsonEncode(sessionsJson));
      await _p.setString(_kActiveSession, activeSessionId);
    } catch (_) {}
  }

  ({List<dynamic>? sessions, String? activeId}) loadChatSessions() {
    try {
      final raw = _p.getString(_kChatSessions);
      final activeId = _p.getString(_kActiveSession);
      if (raw == null) return (sessions: null, activeId: null);
      return (
        sessions: jsonDecode(raw) as List<dynamic>,
        activeId: activeId,
      );
    } catch (_) {
      return (sessions: null, activeId: null);
    }
  }

  // ── Clear helpers (F3 Trash) ──────────────────────────────────────────────

  Future<void> clearWorkspaceAndPaneTree() async {
    try {
      await _p.remove(_kWorkspace);
      await _p.remove(_kPaneTree);
    } catch (_) {}
  }

  Future<void> clearChatSessions() async {
    try {
      await _p.remove(_kChatSessions);
      await _p.remove(_kActiveSession);
    } catch (_) {}
  }
}
