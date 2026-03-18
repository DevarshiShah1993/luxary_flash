import '../../features/product/data/repositories/mock_price_repository.dart';
import '../../features/product/domain/repositories/price_repository.dart';

/// Lightweight service locator.
/// In a larger app this would be replaced by get_it or injectable,
/// but for this single-feature demo a simple singleton factory is clean enough.
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  // Lazily created singletons
  MockPriceRepository? _mockPriceRepository;

  PriceRepository get priceRepository {
    _mockPriceRepository ??= MockPriceRepository();
    return _mockPriceRepository!;
  }

  /// Call once in main() before runApp if you need eager init.
  void init() {
    _mockPriceRepository = MockPriceRepository();
  }

  /// Reset for testing.
  void reset() {
    _mockPriceRepository = null;
  }
}
