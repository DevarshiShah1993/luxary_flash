part of 'product_bloc.dart';

/// All events that can be dispatched to [ProductBloc].
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once when the PDP mounts.
/// Triggers: product fetch + isolate parse + stream subscription.
class LoadProduct extends ProductEvent {
  const LoadProduct();
}

/// Fired by the mock WebSocket stream every 800 ms.
class PriceUpdated extends ProductEvent {
  final CurrentPrice currentPrice;
  const PriceUpdated(this.currentPrice);

  @override
  List<Object?> get props => [currentPrice];
}

/// Fired when the isolate finishes parsing historical bids.
class HistoricalBidsLoaded extends ProductEvent {
  final List<BidPoint> bids;
  const HistoricalBidsLoaded(this.bids);

  @override
  List<Object?> get props => [bids];
}

/// Fired when the user starts holding the buy button.
class PurchaseHoldStarted extends ProductEvent {
  const PurchaseHoldStarted();
}

/// Fired if the user releases the button before 2 seconds.
class PurchaseHoldCancelled extends ProductEvent {
  const PurchaseHoldCancelled();
}

/// Fired when the 2-second hold completes — triggers inventory verification.
class PurchaseConfirmRequested extends ProductEvent {
  const PurchaseConfirmRequested();
}

/// Fired when the confirm purchase API call returns.
class PurchaseConfirmResult extends ProductEvent {
  final bool success;
  const PurchaseConfirmResult({required this.success});

  @override
  List<Object?> get props => [success];
}

/// Fired to reset the purchase flow back to idle (e.g. after success screen).
class PurchaseReset extends ProductEvent {
  const PurchaseReset();
}
