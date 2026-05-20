import 'cleaning_worker_global_prompt_coordinator.dart';

/// App-wide access for forwarding extension realtime events (e.g. from the
/// active booking channel on order details).
class CleaningWorkerExtensionPrompts {
  CleaningWorkerExtensionPrompts._();

  static CleaningWorkerGlobalPromptCoordinator? coordinator;

  static Future<void> dispatchRealtimeEvent(
    String eventName,
    Map<String, dynamic> payload,
  ) async {
    final active = coordinator;
    if (active == null) return;
    await active.handleRealtimeEvent(eventName, payload);
  }

  /// Polls pending orders and extension-request orders, then opens the
  /// corresponding worker prompt sheet when needed (fallback when Pusher misses).
  static Future<void> pollPendingExtensions() async {
    final active = coordinator;
    if (active == null) return;
    await active.pollPendingExtensionPrompts();
  }
}
