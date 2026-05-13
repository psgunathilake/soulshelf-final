import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../data/services/api_client.dart';

/// Returns the right [ImageProvider] for a media-cover URL, or null if the
/// URL is empty / points at a missing local file.
///
/// Phase-3 covers are absolute server URLs (`http://.../storage/...`).
/// Phase-1 / -2 cached entries may still hold local file paths from the
/// in-app picker — we render those via [FileImage] when the file exists.
///
/// Backend stamps URLs using `config('app.url')`, which is usually
/// `http://localhost:8000` in dev. From the Android emulator that host
/// is unreachable, so we rewrite `localhost`/`127.0.0.1` to whatever
/// host the API client is configured for (`10.0.2.2` by default).
ImageProvider? coverImageProvider(String? coverUrl) {
  if (coverUrl == null || coverUrl.isEmpty) return null;
  if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
    return NetworkImage(_rewriteHost(coverUrl));
  }
  final file = File(coverUrl);
  if (!file.existsSync()) return null;
  return FileImage(file);
}

String _rewriteHost(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  if (uri.host != 'localhost' && uri.host != '127.0.0.1') return url;
  final replacement = Uri.parse(apiHostUrl);
  return uri.replace(
    scheme: replacement.scheme,
    host: replacement.host,
    port: replacement.hasPort ? replacement.port : null,
  ).toString();
}
