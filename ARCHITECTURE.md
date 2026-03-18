# Flash Drop — Architecture

## Folder Structure

```
lib/
├── main.dart                          # Entry point — DI init, orientation lock
├── app/
│   └── app.dart                       # MaterialApp + dark luxury theme
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Stream interval, bid count, hold duration
│   ├── di/
│   │   └── service_locator.dart       # Lightweight singleton DI
│   └── theme/
│       └── app_theme.dart             # Dark palette (gold, teal, red)
└── features/
    └── product/
        ├── data/
        │   ├── isolates/
        │   │   ├── isolate_parser.dart  # Isolate.run — 50k bid parse off main thread
        │   │   └── parse_status.dart    # ParseStatus enum
        │   └── repositories/
        │       └── mock_price_repository.dart  # Simulated WebSocket stream
        ├── domain/
        │   ├── entities/
        │   │   ├── bid_point.dart       # Chart data point (timestamp + price)
        │   │   ├── current_price.dart   # Live tick (price, multiplier, inventory, direction)
        │   │   ├── product_detail.dart  # Full product metadata + mock factory
        │   │   └── entities.dart        # Barrel export
        │   └── repositories/
        │       └── price_repository.dart  # Abstract interface
        └── presentation/
            ├── bloc/
            │   ├── product_bloc.dart    # Orchestrator — stream + isolate + purchase flow
            │   ├── product_event.dart   # 8 events (part of bloc)
            │   └── product_state.dart   # 3 states + PurchaseFlowState enum (part of bloc)
            ├── pages/
            │   └── product_detail_page.dart  # Root PDP — assembles all widgets
            └── widgets/
                ├── live_price_widget.dart      # TweenAnimationBuilder price ticker
                ├── price_chart_painter.dart    # CustomPainter — bezier line chart
                ├── price_chart_widget.dart     # Stateful wrapper — pulse anim + skeleton
                └── hold_to_buy_button.dart     # 5-controller hold-to-buy micro-animation
```

---

## State Management — BLoC

We use **flutter_bloc** for strict separation of concerns:

- **UI layer** dispatches events and rebuilds from states — zero business logic in widgets
- **BLoC layer** owns all orchestration: stream subscription lifecycle, isolate triggering, purchase state machine
- **Domain layer** defines pure entities and the abstract `PriceRepository` interface
- **Data layer** contains the only concrete implementation (`MockPriceRepository`)

### Scoped BlocBuilder pattern
Each section of the PDP uses its own `BlocBuilder` with a tight `buildWhen`:
- Price ticker rebuilds only when `currentPrice` changes
- Chart rebuilds only when `livePricePoints`, `historicalBids`, or `isParsingHistory` change
- Buy button rebuilds only when `purchaseFlow` or `currentPrice` changes

This prevents the entire page from rebuilding on every 800ms tick.

---

## Isolate Communication

Parsing 50,000 bid records happens entirely off the main thread:

1. `ProductBloc._onLoadProduct` calls `IsolateParser.parseHistoricalBids()` with `.then()` — **non-blocking**
2. `Isolate.run(_generateAndParseBids)` spawns a worker isolate running the top-level function
3. Inside the isolate: generates 50k maps → `jsonEncode` → `jsonDecode` → `List<BidPoint>`
4. Result is transferred back to the main isolate automatically by `Isolate.run`
5. BLoC receives it and dispatches `HistoricalBidsLoaded(bids)` as a normal event
6. State updates to `isParsingHistory: false` — chart skeleton is replaced with real data

**Why top-level function?** `Isolate.run` requires the function to be a top-level or static function — closures that capture state from the outer scope are forbidden and will throw at runtime.

---

## Mock WebSocket Stream

`MockPriceRepository.watchLivePrice()` returns a `Stream<CurrentPrice>` via `Stream.periodic(800ms)`:
- Each tick applies ±2% random fluctuation with a slight demand-based multiplier
- Price is clamped to 85%–150% of base price to stay realistic
- `PriceDirection` (up/down/flat) is computed per tick so the UI never does comparisons
- `BlocSubscription` is stored and cancelled in `ProductBloc.close()` — zero memory leaks

---

## Performance Strategy

| Concern | Solution |
|---------|----------|
| 50k bid parse blocking UI | `Isolate.run` — completely off main thread |
| Chart repaints on every tick | `RepaintBoundary` wraps `CustomPaint` |
| Full page rebuild on price tick | Scoped `BlocBuilder` with `buildWhen` |
| Smooth price animation | `TweenAnimationBuilder` interpolates between values |
| CustomPainter efficiency | `shouldRepaint` returns false unless data actually changed |
| Live price points memory | Trimmed to last 60 points (`AppConstants.maxLivePricePoints`) |
| Buy button controllers | All 5 controllers disposed in `dispose()` |

---

## Purchase Flow State Machine

```
idle
 └─(PurchaseHoldStarted)──► holding  [progress ring fills 0→1 over 2s]
     ├─(PurchaseHoldCancelled)──► idle  [ring animates back, easeOut]
     └─(PurchaseConfirmRequested after 2s)──► verifying  [spinner]
         ├─(PurchaseConfirmResult success:true)──► success  [checkmark]
         └─(PurchaseConfirmResult success:false)──► failed  [✕]
             └─(PurchaseReset / tap)──► idle
```
