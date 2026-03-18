part of 'product_bloc.dart';

enum PurchaseFlowState { idle, holding, verifying, success, failed }

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductLoading extends ProductState {
  const ProductLoading();
}

class ProductLoaded extends ProductState {
  final ProductDetail product;
  final CurrentPrice currentPrice;

  final List<BidPoint> historicalBids;

  final List<BidPoint> livePricePoints;

  final bool isParsingHistory;

  final PurchaseFlowState purchaseFlow;

  const ProductLoaded({
    required this.product,
    required this.currentPrice,
    this.historicalBids = const [],
    this.livePricePoints = const [],
    this.isParsingHistory = true,
    this.purchaseFlow = PurchaseFlowState.idle,
  });

  ProductLoaded copyWith({
    ProductDetail? product,
    CurrentPrice? currentPrice,
    List<BidPoint>? historicalBids,
    List<BidPoint>? livePricePoints,
    bool? isParsingHistory,
    PurchaseFlowState? purchaseFlow,
  }) {
    return ProductLoaded(
      product: product ?? this.product,
      currentPrice: currentPrice ?? this.currentPrice,
      historicalBids: historicalBids ?? this.historicalBids,
      livePricePoints: livePricePoints ?? this.livePricePoints,
      isParsingHistory: isParsingHistory ?? this.isParsingHistory,
      purchaseFlow: purchaseFlow ?? this.purchaseFlow,
    );
  }

  @override
  List<Object?> get props => [
        product,
        currentPrice,
        historicalBids,
        livePricePoints,
        isParsingHistory,
        purchaseFlow,
      ];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
