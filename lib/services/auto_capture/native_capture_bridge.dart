import 'package:flutter/services.dart';

import '../../models/pending_capture.dart';

class NativeCaptureBridge {
  static const MethodChannel _channel = MethodChannel('jizhang/auto_capture');

  const NativeCaptureBridge();

  Future<bool> isNotificationAccessEnabled() async {
    if (const bool.fromEnvironment('dart.library.html')) return false;
    return await _channel.invokeMethod<bool>('isNotificationAccessEnabled') ?? false;
  }

  Future<void> openNotificationAccessSettings() async {
    await _channel.invokeMethod<void>('openNotificationAccessSettings');
  }

  Future<List<PendingCapture>> drainCandidates() async {
    final raw = await _channel.invokeListMethod<Object?>('drainCandidates') ?? const [];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(PendingCapture.fromNativeMap)
        .toList(growable: false);
  }
}
