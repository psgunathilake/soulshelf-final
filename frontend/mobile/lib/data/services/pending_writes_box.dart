import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Thin helper around the `pendingWritesBox` Hive box. Records offline
/// writes that should later be replayed against the API.
///
/// Task 3.6 only enqueues; Task 3.8 ships the connectivity-driven drainer.
/// All five repositories (Media, Journal, Planner, Collection, User) write
/// here using the same envelope shape so the drainer can dispatch by `op`.
///
/// Envelope:
/// ```dart
/// {
///   'op': 'create.media' | 'update.media' | 'delete.media' | ...,
///   'payload': { ... },   // op-specific; for media writes:
///                         //   { category, localId, serverId?, body? }
///   'userId': '<uid>',    // owner at enqueue time; SyncService drops
///                         //   envelopes whose userId doesn't match the
///                         //   current session (cross-user safety).
///   'ts': <epoch ms>,
///   'attempts': 0,
/// }
/// ```
class PendingWritesBox {
  static const String _boxName = 'pendingWritesBox';

  Box get _box => Hive.box(_boxName);

  Future<void> enqueue(String op, Map<String, dynamic> payload) async {
    await _box.add({
      'op': op,
      'payload': payload,
      'userId': _currentUserId(),
      'ts': DateTime.now().millisecondsSinceEpoch,
      'attempts': 0,
    });
  }

  int get pendingCount => _box.length;

  /// Reads the active user's id from the cached profile. Returns null if
  /// no profile is loaded — those envelopes will be dropped by the drainer
  /// rather than replayed under the wrong identity.
  static String? _currentUserId() {
    final profile = Hive.box('profileBox').get('profile');
    if (profile is! Map) return null;
    return profile['uid'] as String?;
  }
}

final pendingWritesBoxProvider =
    Provider<PendingWritesBox>((ref) => PendingWritesBox());

/// Streams the current size of `pendingWritesBox` so UI badges can react
/// to enqueue / drain in real time. Yields once immediately, then on every
/// box change (add/delete). `autoDispose` so it stops listening when no
/// widget is using it.
final pendingWritesCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final box = Hive.box('pendingWritesBox');
  yield box.length;
  await for (final _ in box.watch()) {
    yield box.length;
  }
});
