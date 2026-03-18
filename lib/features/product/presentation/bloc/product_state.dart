part of 'product_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Purchase flow state machine
// ─────────────────────────────────────────────────────────────────────────────
//
//   idle ──(hold start)──► holding
//   holding ──(release early)──► idle
//   holding ──(2s complete)──► verifying
//   verifying ──(success)──► success
//   verifying ──(failure)──► failed
//   success / failed ──(reset)──► idle
//
enum PurchaseFlowState { idle, holding, verifying, success, failed }

// ─────────────────────────────────────────────────────────────────────────────
// Top-level states
// ─────────────────────────────────────────────────────────────────────────────

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

/// Page is bootstrapping — fetching product + spawning isolate.
class ProductLoading extends ProductState {
  const ProductLoading();
}

/// Everything ready — this is the only long-lived state once loaded.
/// The UI rebuilds from this single state; fields update in place.
class ProductLoaded extends ProductState {
  final ProductDetail product;
  final CurrentPrice currentPrice;

  /// Historical bids parsed by the isolate. Empty list while still parsing.
  final List<BidPoint> historicalBids;

  /// Live price points appended every 800 ms for the right-side of the chart.
  final List<BidPoint> livePricePoints;

  /// Whether the isolate is still running.
  final bool isParsingHistory;

  /// Current stage of the buy-button flow.
  final PurchaseFlowState purchaseFlow;

  const ProductLoaded({
    required this.product,
    required this.currentPrice,
    this.historicalBids = const [],
    this.livePricePoints = const [],
    this.isParsingHistory = true,
    this.purchaseFlow = PurchaseFlowState.idle,
  });

  /// Immutable copy with selective field overrides.
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

/// Unrecoverable error during initial load.
class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
