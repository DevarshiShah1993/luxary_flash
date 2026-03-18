import 'package:flutter/material.dart';
import '../../domain/entities/current_price.dart';
import '../../../../core/theme/app_theme.dart';

/// Displays the live price with smooth implicit animations.
///
/// Every 800 ms the BLoC emits a new [CurrentPrice]. This widget:
///   • Smoothly interpolates the numeric value via [TweenAnimationBuilder]
///   • Fades + slides the price in from above (up) or below (down)
///     using [AnimatedSwitcher] with a custom [SlideTransition]
///   • Colour-shifts between gold / teal-green / red based on [PriceDirection]
///   • Animates the demand multiplier badge independently
///
/// Zero [AnimationController]s — all implicit, zero boilerplate.
class LivePriceWidget extends StatelessWidget {
  const LivePriceWidget({
    super.key,
    required this.currentPrice,
  });

  final CurrentPrice currentPrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Live label ─────────────────────────────────────────────
        Row(
          children: [
            _PulseDot(direction: currentPrice.direction),
            const SizedBox(width: 6),
            const Text(
              'LIVE PRICE',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ── Main price + direction arrow ───────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _AnimatedPriceText(currentPrice: currentPrice),
            const SizedBox(width: 10),
            _DirectionArrow(direction: currentPrice.direction),
          ],
        ),

        const SizedBox(height: 10),

        // ── Bottom row: multiplier badge + inventory ───────────────
        Row(
          children: [
            _MultiplierBadge(multiplier: currentPrice.multiplier),
            const SizedBox(width: 12),
            _InventoryChip(remaining: currentPrice.remainingInventory),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated price number
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedPriceText extends StatelessWidget {
  const _AnimatedPriceText({required this.currentPrice});

  final CurrentPrice currentPrice;

  Color _priceColor(PriceDirection dir) => switch (dir) {
        PriceDirection.up   => AppTheme.priceUp,
        PriceDirection.down => AppTheme.priceDown,
        PriceDirection.flat => AppTheme.accent,
      };

  @override
  Widget build(BuildContext context) {
    // TweenAnimationBuilder smoothly interpolates between old and new price
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: currentPrice.price),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animatedPrice, _) {
        // Format the interpolated value identically to formattedPrice
        final display = animatedPrice >= 1000
            ? '\$${(animatedPrice / 1000).toStringAsFixed(2)}k'
            : '\$${animatedPrice.toStringAsFixed(2)}';

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            // Slide up for price increase, slide down for decrease
            final isUp = currentPrice.direction == PriceDirection.up;
            final offset = isUp
                ? const Offset(0, 0.3)   // enters from below
                : const Offset(0, -0.3); // enters from above

            return SlideTransition(
              position: Tween<Offset>(
                begin: offset,
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 400),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: _priceColor(currentPrice.direction),
              letterSpacing: -1.5,
              height: 1.0,
            ),
            child: Text(display, key: ValueKey(display)),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Direction arrow
// ─────────────────────────────────────────────────────────────────────────────

class _DirectionArrow extends StatelessWidget {
  const _DirectionArrow({required this.direction});

  final PriceDirection direction;

  @override
  Widget build(BuildContext context) {
    if (direction == PriceDirection.flat) return const SizedBox.shrink();

    final isUp = direction == PriceDirection.up;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Container(
        key: ValueKey(direction),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: (isUp ? AppTheme.priceUp : AppTheme.priceDown).withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: isUp ? AppTheme.priceUp : AppTheme.priceDown,
          size: 18,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demand multiplier badge
// ─────────────────────────────────────────────────────────────────────────────

class _MultiplierBadge extends StatelessWidget {
  const _MultiplierBadge({required this.multiplier});

  final double multiplier;

  @override
  Widget build(BuildContext context) {
    // Colour intensity scales with multiplier magnitude
    final intensity = ((multiplier - 1.0) / 0.5).clamp(0.0, 1.0);
    final badgeColor = Color.lerp(
      AppTheme.accent,
      AppTheme.priceDown,
      intensity,
    )!;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: multiplier),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (_, value, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: badgeColor, size: 13),
              const SizedBox(width: 4),
              Text(
                'DEMAND ${value.toStringAsFixed(2)}×',
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inventory chip
// ─────────────────────────────────────────────────────────────────────────────

class _InventoryChip extends StatelessWidget {
  const _InventoryChip({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final isLow = remaining <= 3;
    final color = isLow ? AppTheme.priceDown : AppTheme.textSecondary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Row(
        key: ValueKey(remaining),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLow
                ? Icons.warning_amber_rounded
                : Icons.inventory_2_outlined,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            isLow ? 'ONLY $remaining LEFT' : '$remaining remaining',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isLow ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: isLow ? 0.8 : 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing live indicator dot
// ─────────────────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.direction});

  final PriceDirection direction;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale   = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.priceUp,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
