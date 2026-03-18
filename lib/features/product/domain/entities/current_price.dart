import 'package:equatable/equatable.dart';

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

  double get basePrice => price / multiplier;

  String get formattedPrice {
    if (price >= 1000) {
      return '\$${(price / 1000).toStringAsFixed(2)}k';
    }
    return '\$${price.toStringAsFixed(2)}';
  }

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
  String toString() => 'CurrentPrice(price: $price, multiplier: $multiplier, '
      'inventory: $remainingInventory, dir: $direction)';
}

enum PriceDirection { up, down, flat }
