import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sound_service.dart';
import 'sound_effects_enabled_provider.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService(
    isSoundEffectsEnabled: () => ref.read(soundEffectsEnabledProvider),
  );
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});
