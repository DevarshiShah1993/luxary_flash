import '../entities/current_price.dart';
import '../entities/product_detail.dart';
import '../entities/bid_point.dart';

/// Abstract contract for the price/product data layer.
/// The BLoC depends only on this interface — never on the concrete impl.
abstract class PriceRepository {
  /// Emits a new [CurrentPrice] every 800 ms, simulating a WebSocket feed.
  /// The stream is infinite; caller must cancel the subscription.
  Stream<CurrentPrice> watchLivePrice();

  /// Returns the static product metadata for the Flash Drop PDP.
  Future<ProductDetail> getProductDetail();

  /// Generates and parses 50,000 historical bid records.
  /// MUST be executed inside a Dart Isolate — this is intentionally heavy.
  /// Returns the parsed list ready to be plotted on the chart.
  Future<List<BidPoint>> fetchHistoricalBids();

  /// Simulates a purchase confirmation network call (300–800 ms delay).
  /// Returns [true] on success, [false] if inventory ran out.
  Future<bool> confirmPurchase(String productId);
}
