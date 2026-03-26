import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sound_service.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});
