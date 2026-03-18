import 'dart:isolate';
import 'dart:math';
import 'dart:convert';
import '../../domain/entities/bid_point.dart';

class IsolateParser {
  IsolateParser._();

  static Future<List<BidPoint>> parseHistoricalBids() async {
    return Isolate.run(_generateAndParseBids);
  }
}

List<BidPoint> _generateAndParseBids() {
  const int count = 50000;
  const double basePrice = 48500.0;
  const double volatility = 0.015;

  final random = Random(42);

  final List<Map<String, dynamic>> rawMaps = [];

  final int startTimestamp =
      DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
  const int intervalMs = 12096;

  double price = basePrice * 0.80;

  for (int i = 0; i < count; i++) {
    final change = 1 + (random.nextDouble() * 2 - 1) * volatility + 0.0001;
    price = (price * change).clamp(basePrice * 0.60, basePrice * 1.55);

    rawMaps.add({
      'timestamp': startTimestamp + (i * intervalMs),
      'price': double.parse(price.toStringAsFixed(2)),
      'bid_id': 'bid_${i.toString().padLeft(6, '0')}',
      'user_hash': _fakeHash(random),
      'region': _fakeRegion(random),
      'confidence': random.nextDouble(),
    });
  }

  final String jsonString = jsonEncode(rawMaps);

  final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;

  final List<BidPoint> bidPoints = decoded
      .map((e) => BidPoint.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);

  return bidPoints;
}

String _fakeHash(Random r) {
  const chars = '0123456789abcdef';
  return List.generate(8, (_) => chars[r.nextInt(16)]).join();
}

String _fakeRegion(Random r) {
  const regions = ['US-EAST', 'EU-WEST', 'APAC', 'US-WEST', 'ME', 'LATAM'];
  return regions[r.nextInt(regions.length)];
}
