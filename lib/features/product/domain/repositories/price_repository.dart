import '../entities/current_price.dart';
import '../entities/product_detail.dart';
import '../entities/bid_point.dart';

abstract class PriceRepository {
  Stream<CurrentPrice> watchLivePrice();

  Future<ProductDetail> getProductDetail();

  Future<List<BidPoint>> fetchHistoricalBids();

  Future<bool> confirmPurchase(String productId);
}
