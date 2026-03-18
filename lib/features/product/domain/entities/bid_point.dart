import 'package:equatable/equatable.dart';

/// A single historical bid/price data point used to render the chart.
/// [timestamp] is milliseconds since epoch.
/// [price] is the bid value at that moment.
class BidPoint extends Equatable {
  final int timestamp;
  final double price;

  const BidPoint({
    required this.timestamp,
    required this.price,
  });

  /// Construct from raw JSON map (used inside the isolate parser).
  factory BidPoint.fromJson(Map<String, dynamic> json) {
    return BidPoint(
      timestamp: json['timestamp'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'price': price,
      };

  @override
  List<Object?> get props => [timestamp, price];

  @override
  String toString() => 'BidPoint(ts: $timestamp, price: $price)';
}
