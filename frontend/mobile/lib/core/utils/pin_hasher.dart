import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Returns the SHA-256 hex digest of `'$pin:$userId'`. Salting with the
/// user id means two users typing the same PIN have different hashes —
/// it defends against precomputed-rainbow comparison across the user
/// base if the pin_hash column ever leaks.
///
/// The plaintext PIN never reaches the server; this is the only field
/// the server ever sees.
String hashPin(String pin, String userId) =>
    sha256.convert(utf8.encode('$pin:$userId')).toString();
