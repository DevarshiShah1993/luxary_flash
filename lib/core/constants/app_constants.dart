/// App-wide constants
class AppConstants {
  AppConstants._();

  // ── Stream ─────────────────────────────────────────────────────
  static const int streamIntervalMs = 800;

  // ── Isolate / Data ─────────────────────────────────────────────
  static const int historicalBidCount = 50000;

  // ── Buy Button ─────────────────────────────────────────────────
  static const Duration holdDuration = Duration(seconds: 2);

  // ── Chart ──────────────────────────────────────────────────────
  static const int maxLivePricePoints = 60; // keep last N live points on chart
}
