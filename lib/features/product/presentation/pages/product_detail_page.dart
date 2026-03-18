import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/product_bloc.dart';
import '../widgets/live_price_widget.dart';
import '../widgets/price_chart_widget.dart';
import '../widgets/hold_to_buy_button.dart' as btn;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';

/// The Product Detail Page — root of the Flash Drop experience.
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductBloc(
        repository: ServiceLocator.instance.priceRepository,
      )..add(const LoadProduct()),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) return const _LoadingView();
          if (state is ProductError) return _ErrorView(message: state.message);
          if (state is ProductLoaded) return _LoadedView(state: state);
          return const _LoadingView();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppTheme.textPrimary,
          size: 16,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share_rounded,
                color: AppTheme.textPrimary, size: 18),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            'LOADING DROP',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.priceDown, size: 48),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () =>
                  context.read<ProductBloc>().add(const LoadProduct()),
              child:
                  const Text('Retry', style: TextStyle(color: AppTheme.accent)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loaded ────────────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});
  final ProductLoaded state;

  btn.PurchaseFlowState _mapFlow(PurchaseFlowState f) =>
      btn.PurchaseFlowState.values[f.index];

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductBloc>();
    final product = state.product;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _HeroSection(product: product)),
            SliverToBoxAdapter(
              child: _ContentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductHeader(product: product),
                    const _Divider(),

                    // Scoped rebuild: price only
                    BlocBuilder<ProductBloc, ProductState>(
                      buildWhen: (p, c) => p is ProductLoaded &&
                          c is ProductLoaded &&
                          (p).currentPrice != (c).currentPrice,
                      builder: (_, s) {
                        if (s is! ProductLoaded) return const SizedBox.shrink();
                        return LivePriceWidget(currentPrice: s.currentPrice);
                      },
                    ),

                    const _Divider(),

                    // Scoped rebuild: chart data only
                    BlocBuilder<ProductBloc, ProductState>(
                      buildWhen: (p, c) =>
                          p is ProductLoaded &&
                          c is ProductLoaded &&
                          ((p).livePricePoints != (c).livePricePoints ||
                              (p).historicalBids != (c).historicalBids ||
                              (p).isParsingHistory != (c).isParsingHistory),
                      builder: (_, s) {
                        if (s is! ProductLoaded) return const SizedBox.shrink();
                        return PriceChartWidget(
                          historicalBids: s.historicalBids,
                          livePricePoints: s.livePricePoints,
                          isParsingHistory: s.isParsingHistory,
                        );
                      },
                    ),

                    const _Divider(),
                    _TagRow(tags: product.tags),
                    const _Divider(),
                    _Description(text: product.description),
                    const _Divider(),
                    _DropDetails(product: product),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Sticky buy bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _StickyBuyBar(
            state: state,
            mapFlow: _mapFlow,
            onHoldStart: () => bloc.add(const PurchaseHoldStarted()),
            onHoldCancel: () => bloc.add(const PurchaseHoldCancelled()),
            onHoldComplete: () => bloc.add(const PurchaseConfirmRequested()),
            onReset: () => bloc.add(const PurchaseReset()),
          ),
        ),
      ],
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.product});
  final dynamic product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.accent.withOpacity(0.3), width: 1),
                color: AppTheme.surfaceHigh.withOpacity(0.5),
              ),
              child: const Icon(Icons.watch_rounded,
                  color: AppTheme.accent, size: 80),
            ),
          ),
          Positioned(
            top: 90,
            left: 20,
            child: _FlashDropBadge(),
          ),
          Positioned(
            top: 90,
            right: 20,
            child: _CountdownBadge(dropEndsAt: product.dropEndsAt),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppTheme.surface],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashDropBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: AppTheme.background, size: 13),
          SizedBox(width: 4),
          Text(
            'FLASH DROP',
            style: TextStyle(
              color: AppTheme.background,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.dropEndsAt});
  final String dropEndsAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: AppTheme.priceDown, size: 12),
          const SizedBox(width: 4),
          Text(
            dropEndsAt,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Content card + sub-widgets ────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: child,
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});
  final dynamic product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brand,
          style: const TextStyle(
            color: AppTheme.accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          product.edition,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map((tag) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ))
          .toList(),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ABOUT THIS PIECE',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 14, height: 1.7),
        ),
      ],
    );
  }
}

class _DropDetails extends StatelessWidget {
  const _DropDetails({required this.product});
  final dynamic product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DROP DETAILS',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _DetailRow(
            label: 'Total Edition Size',
            value: '${product.totalInventory} pieces'),
        const SizedBox(height: 8),
        const _DetailRow(
            label: 'Authentication', value: 'Rolex Geneva Certified'),
        const SizedBox(height: 8),
        const _DetailRow(
            label: 'Delivery', value: 'Insured — 3 Business Days'),
        const SizedBox(height: 8),
        _DetailRow(label: 'Drop ID', value: product.id.toUpperCase()),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: AppTheme.divider, height: 1),
    );
  }
}

// ── Sticky buy bar ────────────────────────────────────────────────────────────

class _StickyBuyBar extends StatelessWidget {
  const _StickyBuyBar({
    required this.state,
    required this.mapFlow,
    required this.onHoldStart,
    required this.onHoldCancel,
    required this.onHoldComplete,
    required this.onReset,
  });

  final ProductLoaded state;
  final btn.PurchaseFlowState Function(PurchaseFlowState) mapFlow;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldCancel;
  final VoidCallback onHoldComplete;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.85),
            border: const Border(top: BorderSide(color: AppTheme.divider)),
          ),
          child: BlocBuilder<ProductBloc, ProductState>(
            buildWhen: (p, c) =>
                p is ProductLoaded &&
                c is ProductLoaded &&
                ((p).purchaseFlow != (c).purchaseFlow ||
                    (p).currentPrice != (c).currentPrice),
            builder: (_, s) {
              if (s is! ProductLoaded) return const SizedBox.shrink();
              return btn.HoldToBuyButton(
                currentPrice: s.currentPrice,
                purchaseFlow: mapFlow(s.purchaseFlow),
                onHoldStart: onHoldStart,
                onHoldCancel: onHoldCancel,
                onHoldComplete: onHoldComplete,
                onReset: onReset,
              );
            },
          ),
        ),
      ),
    );
  }
}
