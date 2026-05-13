import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

final authUserStreamProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).userChanges;
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  final asyncUser = ref.watch(authUserStreamProvider);
  return asyncUser.when(
    data: (user) {
      if (user == null) return AuthStatus.unauthenticated;
      return user.emailVerified
          ? AuthStatus.authenticated
          : AuthStatus.awaitingVerification;
    },
    loading: () => AuthStatus.unknown,
    error: (_, __) => AuthStatus.unauthenticated,
  );
});
