import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthMode {
  real,
  decoy,
}

final authModeProvider = StateProvider<AuthMode>((ref) => AuthMode.real);
