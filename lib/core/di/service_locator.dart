import '../../features/product/data/repositories/mock_price_repository.dart';
import '../../features/product/domain/repositories/price_repository.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  MockPriceRepository? _mockPriceRepository;

  PriceRepository get priceRepository {
    _mockPriceRepository ??= MockPriceRepository();
    return _mockPriceRepository!;
  }

  void init() {
    _mockPriceRepository = MockPriceRepository();
  }

  void reset() {
    _mockPriceRepository = null;
  }
}
