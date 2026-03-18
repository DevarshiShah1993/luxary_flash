import 'package:equatable/equatable.dart';

/// Represents a single live price emission from the mock WebSocket stream.
///
/// [price]             — current market price after demand multiplier.
/// [multiplier]        — demand-driven multiplier (e.g. 1.24×).
/// [remainingInventory]— units left in this flash drop.
/// [direction]         — whether price moved up, down, or held flat vs last tick.
class CurrentPrice extends Equatable {
  final double price;
  final double multiplier;
  final int remainingInventory;
  final PriceDirection direction;
  final DateTime timestamp;

  const CurrentPrice({
    required this.price,
    required this.multiplier,
    required this.remainingInventory,
    required this.direction,
    required this.timestamp,
  });

  /// Convenience: base price before multiplier.
  double get basePrice => price / multiplier;

  /// Human-readable formatted price string.
  String get formattedPrice {
    if (price >= 1000) {
      return '\$${(price / 1000).toStringAsFixed(2)}k';
    }
    return '\$${price.toStringAsFixed(2)}';
  }

  /// Formatted multiplier string.
  String get formattedMultiplier => '${multiplier.toStringAsFixed(2)}×';

  @override
  List<Object?> get props => [
        price,
        multiplier,
        remainingInventory,
        direction,
        timestamp,
      ];

  @override
  String toString() =>
      'CurrentPrice(price: $price, multiplier: $multiplier, '
      'inventory: $remainingInventory, dir: $direction)';
}

/// Direction of price movement relative to the previous tick.
enum PriceDirection { up, down, flat }
