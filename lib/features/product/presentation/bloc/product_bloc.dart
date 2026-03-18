import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/price_repository.dart';
import '../../data/isolates/isolate_parser.dart';
import '../../../../core/constants/app_constants.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc({required PriceRepository repository})
      : _repository = repository,
        super(const ProductLoading()) {
    on<LoadProduct>(_onLoadProduct);
    on<PriceUpdated>(_onPriceUpdated);
    on<HistoricalBidsLoaded>(_onHistoricalBidsLoaded);
    on<PurchaseHoldStarted>(_onPurchaseHoldStarted);
    on<PurchaseHoldCancelled>(_onPurchaseHoldCancelled);
    on<PurchaseConfirmRequested>(_onPurchaseConfirmRequested);
    on<PurchaseConfirmResult>(_onPurchaseConfirmResult);
    on<PurchaseReset>(_onPurchaseReset);
  }

  final PriceRepository _repository;
  StreamSubscription<CurrentPrice>? _priceSubscription;

  // ─────────────────────────────────────────────────────────────────
  // LoadProduct
  // ─────────────────────────────────────────────────────────────────

  Future<void> _onLoadProduct(
    LoadProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      // 1. Fetch product metadata (fast — mock 120ms delay)
      final product = await _repository.getProductDetail();

      // 2. Get the first price tick synchronously before stream starts
      final firstPrice = await _repository
          .watchLivePrice()
          .first;

      // 3. Emit initial loaded state — UI is now visible
      emit(ProductLoaded(
        product: product,
        currentPrice: firstPrice,
        isParsingHistory: true, // spinner shows on chart
      ));

      // 4. Subscribe to live price stream
      _priceSubscription?.cancel();
      _priceSubscription = _repository.watchLivePrice().listen(
        (price) => add(PriceUpdated(price)),
      );

      // 5. Kick off isolate parse — runs completely off main thread
      //    We don't await here; result comes back as an event.
      IsolateParser.parseHistoricalBids().then(
        (bids) => add(HistoricalBidsLoaded(bids)),
        onError: (e) {
          // Non-fatal: chart just stays empty, rest of UI works fine
          add(const HistoricalBidsLoaded([]));
        },
      );
    } catch (e) {
      emit(ProductError('Failed to load product: $e'));
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PriceUpdated — fires every 800 ms
  // ─────────────────────────────────────────────────────────────────

  void _onPriceUpdated(
    PriceUpdated event,
    Emitter<ProductState> emit,
  ) {
    final current = state;
    if (current is! ProductLoaded) return;

    // Append new live point to chart, keeping only last N points
    final newPoint = BidPoint(
      timestamp: event.currentPrice.timestamp.millisecondsSinceEpoch,
      price: event.currentPrice.price,
    );

    final updatedLive = [
      ...current.livePricePoints,
      newPoint,
    ];

    // Trim to max window
    final trimmed = updatedLive.length > AppConstants.maxLivePricePoints
        ? updatedLive.sublist(
            updatedLive.length - AppConstants.maxLivePricePoints)
        : updatedLive;

    emit(current.copyWith(
      currentPrice: event.currentPrice,
      livePricePoints: trimmed,
    ));
  }

  // ─────────────────────────────────────────────────────────────────
  // HistoricalBidsLoaded — isolate finished
  // ─────────────────────────────────────────────────────────────────

  void _onHistoricalBidsLoaded(
    HistoricalBidsLoaded event,
    Emitter<ProductState> emit,
  ) {
    final current = state;
    if (current is! ProductLoaded) return;

    emit(current.copyWith(
      historicalBids: event.bids,
      isParsingHistory: false, // hide spinner, show chart
    ));
  }

  // ─────────────────────────────────────────────────────────────────
  // Purchase Flow
  // ─────────────────────────────────────────────────────────────────

  void _onPurchaseHoldStarted(
    PurchaseHoldStarted event,
    Emitter<ProductState> emit,
  ) {
    final current = state;
    if (current is! ProductLoaded) return;
    if (current.purchaseFlow != PurchaseFlowState.idle) return;

    emit(current.copyWith(purchaseFlow: PurchaseFlowState.holding));
  }

  void _onPurchaseHoldCancelled(
    PurchaseHoldCancelled event,
    Emitter<ProductState> emit,
  ) {
    final current = state;
    if (current is! ProductLoaded) return;
    if (current.purchaseFlow != PurchaseFlowState.holding) return;

    emit(current.copyWith(purchaseFlow: PurchaseFlowState.idle));
  }

  Future<void> _onPurchaseConfirmRequested(
    PurchaseConfirmRequested event,
    Emitter<ProductState> emit,
  ) async {
    final current = state;
    if (current is! ProductLoaded) return;

    // Move to verifying — shows loading spinner on button
    emit(current.copyWith(purchaseFlow: PurchaseFlowState.verifying));

    // Call repository (300–800ms simulated latency)
    try {
      final success =
          await _repository.confirmPurchase(current.product.id);
      add(PurchaseConfirmResult(success: success));
    } catch (_) {
      add(const PurchaseConfirmResult(success: false));
    }
  }

  void _onPurchaseConfirmResult(
    PurchaseConfirmResult event,
    Emitter<ProductState> emit,
  ) {
    final current = state;
    if (current is! ProductLoaded) return;

    emit(current.copyWith(
      purchaseFlow: event.success
          ? PurchaseFlowState.success
          : PurchaseFlowState.failed,
    ));
  }

  void _onPurchaseReset(
    PurchaseReset event,
    Emitter<ProductState> emit,
  ) {
    final current = state;
    if (current is! ProductLoaded) return;

    emit(current.copyWith(purchaseFlow: PurchaseFlowState.idle));
  }

  // ─────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    await _priceSubscription?.cancel();
    return super.close();
  }
}
