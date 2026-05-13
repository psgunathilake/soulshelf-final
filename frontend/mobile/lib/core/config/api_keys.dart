/// API keys injected at build time via `--dart-define`.
///
/// Values come from `project/soulshelf/.env.local` (gitignored) and are
/// passed to `flutter run` by `scripts/run-dev.ps1`. Reads return an empty
/// string if the define wasn't passed — callers should check `hasX` first.
class ApiKeys {
  ApiKeys._();

  static const String tmdb = String.fromEnvironment('TMDB_KEY');
  static const String lastfm = String.fromEnvironment('LASTFM_KEY');
  static const String openai = String.fromEnvironment('OPENAI_API_KEY');

  static bool get hasTmdb => tmdb.isNotEmpty;
  static bool get hasLastfm => lastfm.isNotEmpty;
  static bool get hasOpenai => openai.isNotEmpty;

  /// Logs presence (not the values) in debug builds. No-op in release.
  static void debugLogStatus() {
    assert(() {
      // ignore: avoid_print
      print('[ApiKeys] TMDB:    ${hasTmdb ? "loaded" : "MISSING"}');
      // ignore: avoid_print
      print('[ApiKeys] Last.fm: ${hasLastfm ? "loaded" : "MISSING"}');
      // ignore: avoid_print
      print('[ApiKeys] OpenAI:  ${hasOpenai ? "loaded" : "MISSING"}');
      return true;
    }());
  }
}
