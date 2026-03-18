import 'package:flutter/material.dart';
import '../../domain/entities/bid_point.dart';
import '../../../../core/theme/app_theme.dart';
import 'price_chart_painter.dart';

class PriceChartWidget extends StatefulWidget {
  const PriceChartWidget({
    super.key,
    required this.historicalBids,
    required this.livePricePoints,
    required this.isParsingHistory,
  });

  final List<BidPoint> historicalBids;
  final List<BidPoint> livePricePoints;
  final bool isParsingHistory;

  @override
  State<PriceChartWidget> createState() => _PriceChartWidgetState();
}

class _PriceChartWidgetState extends State<PriceChartWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Text(
                'PRICE HISTORY',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              if (widget.isParsingHistory)
                const _ParseSpinner()
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.priceUp.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.historicalBids.length ~/ 1000}K pts',
                    style: const TextStyle(
                      color: AppTheme.priceUp,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: widget.isParsingHistory
              ? const _ChartSkeleton()
              : RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: PriceChartPainter(
                          historicalBids: widget.historicalBids,
                          livePricePoints: widget.livePricePoints,
                          pulseRadius: _pulseAnimation.value,
                          isParsingHistory: widget.isParsingHistory,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _ParseSpinner extends StatelessWidget {
  const _ParseSpinner();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppTheme.accent.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'Loading history…',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ChartSkeleton extends StatefulWidget {
  const _ChartSkeleton();

  @override
  State<_ChartSkeleton> createState() => _ChartSkeletonState();
}

class _ChartSkeletonState extends State<_ChartSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceHigh,
              Color.lerp(
                AppTheme.surfaceHigh,
                AppTheme.divider,
                _shimmer.value,
              )!,
              AppTheme.surfaceHigh,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
