import 'dart:isolate';
import 'dart:math';
import 'dart:convert';
import '../../domain/entities/bid_point.dart';

/// Handles all heavy data work off the main UI thread.
///
/// Flutter's [Isolate.run] spawns a fresh isolate, executes the given
/// top-level function, returns the result to the main isolate, then
/// immediately disposes the worker — zero memory leaks.
///
/// ⚠️  All functions passed to [Isolate.run] MUST be top-level or static.
///     Instance methods and closures that capture state are NOT allowed.
class IsolateParser {
  IsolateParser._();

  /// Entry point called by the BLoC.
  ///
  /// Spawns an isolate that:
  ///   1. Generates 50,000 raw bid JSON maps (CPU-heavy).
  ///   2. JSON-encodes them into a single string (simulates network payload).
  ///   3. JSON-decodes and maps them into [BidPoint] objects.
  ///
  /// The main thread stays completely free — 0 frame drops guaranteed.
  static Future<List<BidPoint>> parseHistoricalBids() async {
    return Isolate.run(_generateAndParseBids);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP-LEVEL worker function — required by Isolate.run
// Must be top-level (not inside a class, not a closure).
// ─────────────────────────────────────────────────────────────────────────────

/// Runs entirely inside the worker isolate.
/// Returns a parsed [List<BidPoint>] to the main isolate.
List<BidPoint> _generateAndParseBids() {
  const int count = 50000;
  const double basePrice = 48500.0;
  const double volatility = 0.015; // 1.5% per step

  final random = Random(42); // seeded for reproducibility

  // ── Step 1: Generate raw bid data ────────────────────────────────
  // Simulate "receiving a massive JSON payload from a server".
  // We build a List<Map> first, then encode to String to mimic real parsing.
  final List<Map<String, dynamic>> rawMaps = [];

  // Start 7 days ago in ms
  final int startTimestamp =
      DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
  const int intervalMs = 12096; // ~12 seconds between bids over 7 days

  double price = basePrice * 0.80; // start below base, build up

  for (int i = 0; i < count; i++) {
    // Random walk with slight upward drift
    final change = 1 + (random.nextDouble() * 2 - 1) * volatility + 0.0001;
    price = (price * change).clamp(basePrice * 0.60, basePrice * 1.55);

    rawMaps.add({
      'timestamp': startTimestamp + (i * intervalMs),
      'price': double.parse(price.toStringAsFixed(2)),
      'bid_id': 'bid_${i.toString().padLeft(6, '0')}',   // extra fields
      'user_hash': _fakeHash(random),                      // to bulk up payload
      'region': _fakeRegion(random),
      'confidence': random.nextDouble(),
    });
  }

  // ── Step 2: Encode to JSON string (simulates a real network payload) ──
  final String jsonString = jsonEncode(rawMaps);

  // ── Step 3: Decode + parse into BidPoint entities ────────────────
  final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;

  final List<BidPoint> bidPoints = decoded
      .map((e) => BidPoint.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);

  return bidPoints;
}

/// Generates a fake 8-char hex string to bulk up each JSON record.
String _fakeHash(Random r) {
  const chars = '0123456789abcdef';
  return List.generate(8, (_) => chars[r.nextInt(16)]).join();
}

/// Picks a fake region string.
String _fakeRegion(Random r) {
  const regions = ['US-EAST', 'EU-WEST', 'APAC', 'US-WEST', 'ME', 'LATAM'];
  return regions[r.nextInt(regions.length)];
}
