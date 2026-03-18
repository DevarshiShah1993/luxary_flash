import 'dart:math';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/price_repository.dart';

/// Concrete mock implementation of [PriceRepository].
///
/// Simulates a live WebSocket feed by using [Stream.periodic] at 800 ms intervals.
/// Each tick applies a random ±2% price fluctuation and a demand-driven multiplier.
/// Inventory decrements randomly to simulate real purchase pressure.
class MockPriceRepository implements PriceRepository {
  MockPriceRepository() : _random = Random();

  final Random _random;

  // ── Internal mutable state (stream-local) ───────────────────────
  double _currentPrice = 48500.00;
  double _currentMultiplier = 1.00;
  int _remainingInventory = 12;
  double _previousPrice = 48500.00;

  // ── Base config ─────────────────────────────────────────────────
  static const double _basePrice = 48500.00;
  static const double _maxFluctuationPercent = 0.02; // ±2%
  static const int _streamIntervalMs = 800;

  // ───────────────────────────────────────────────────────────────
  // 1. Live Price Stream
  // ───────────────────────────────────────────────────────────────

  @override
  Stream<CurrentPrice> watchLivePrice() {
    return Stream.periodic(
      const Duration(milliseconds: _streamIntervalMs),
      (_) => _generateNextTick(),
    ).distinct(); // skip identical ticks (edge case)
  }

  CurrentPrice _generateNextTick() {
    _previousPrice = _currentPrice;

    // Random ±2% price fluctuation
    final fluctuation =
        1 + (_random.nextDouble() * 2 - 1) * _maxFluctuationPercent;
    _currentPrice = (_currentPrice * fluctuation).clamp(
      _basePrice * 0.85, // floor: never drop below 85% of base
      _basePrice * 1.50, // ceiling: never exceed 150% of base
    );

    // Demand multiplier: rises with scarcity, random nudge added
    final scarcityFactor = 1 + (1 - _remainingInventory / 12) * 0.30;
    final randomNudge = 1 + (_random.nextDouble() * 0.04 - 0.02);
    _currentMultiplier =
        (scarcityFactor * randomNudge).clamp(1.00, 1.50);

    // Re-price with multiplier
    _currentPrice = (_basePrice * _currentMultiplier * fluctuation).clamp(
      _basePrice * 0.85,
      _basePrice * 1.50,
    );

    // Randomly decrement inventory (roughly every 5–10 ticks)
    if (_remainingInventory > 0 && _random.nextInt(8) == 0) {
      _remainingInventory--;
    }

    // Determine direction
    final direction = _currentPrice > _previousPrice
        ? PriceDirection.up
        : _currentPrice < _previousPrice
            ? PriceDirection.down
            : PriceDirection.flat;

    return CurrentPrice(
      price: _currentPrice,
      multiplier: _currentMultiplier,
      remainingInventory: _remainingInventory,
      direction: direction,
      timestamp: DateTime.now(),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // 2. Product Detail
  // ───────────────────────────────────────────────────────────────

  @override
  Future<ProductDetail> getProductDetail() async {
    // Simulate a short network round-trip
    await Future.delayed(const Duration(milliseconds: 120));
    return ProductDetail.mock();
  }

  // ───────────────────────────────────────────────────────────────
  // 3. Historical Bids  ← heavy work; caller MUST use an Isolate
  // ───────────────────────────────────────────────────────────────

  /// Returns 50,000 raw JSON maps.
  /// This is intentionally called from inside [Isolate.run] in the BLoC.
  /// Do NOT call directly on the main thread.
  @override
  Future<List<BidPoint>> fetchHistoricalBids() async {
    // No actual network call — the isolate function generates + parses the data.
    // This method exists to satisfy the interface; the real heavy work is in
    // [IsolateParser.parseHistoricalBids] (Task 4).
    throw UnimplementedError(
      'fetchHistoricalBids must be invoked via IsolateParser.parseHistoricalBids',
    );
  }

  // ───────────────────────────────────────────────────────────────
  // 4. Confirm Purchase
  // ───────────────────────────────────────────────────────────────

  @override
  Future<bool> confirmPurchase(String productId) async {
    // Simulate network latency for "verifying inventory"
    final delayMs = 300 + _random.nextInt(500); // 300–800 ms
    await Future.delayed(Duration(milliseconds: delayMs));

    if (_remainingInventory <= 0) return false;

    _remainingInventory--;
    return true;
  }
}
