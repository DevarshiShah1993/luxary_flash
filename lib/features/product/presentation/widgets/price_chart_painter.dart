import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../domain/entities/bid_point.dart';
import '../../../../core/theme/app_theme.dart';

/// Premium FinTech line chart rendered via [CustomPainter].
///
/// Renders two data series in one pass:
///   • [historicalBids]  — parsed by isolate, plotted in muted gold
///   • [livePricePoints] — appended every 800 ms, plotted in vivid gold
///
/// Features:
///   • Smooth cubic bezier curve (not jagged polyline)
///   • Gradient fill beneath the line (Robinhood-style)
///   • Animated live "pulse" dot at the latest price point
///   • Subtle Y-axis price labels and X-axis time labels
///   • [RepaintBoundary] wraps this painter — only repaints when data changes
class PriceChartPainter extends CustomPainter {
  const PriceChartPainter({
    required this.historicalBids,
    required this.livePricePoints,
    required this.pulseRadius,         // animated from outside
    required this.isParsingHistory,
  });

  final List<BidPoint> historicalBids;
  final List<BidPoint> livePricePoints;
  final double pulseRadius;
  final bool isParsingHistory;

  // ── Combine both series for bounds calculation ─────────────────
  List<BidPoint> get _allPoints => [
        ...historicalBids,
        ...livePricePoints,
      ];

  @override
  void paint(Canvas canvas, Size size) {
    if (_allPoints.isEmpty) return;

    final points = _allPoints;
    final minPrice = points.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = points.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final minTs    = points.first.timestamp.toDouble();
    final maxTs    = points.last.timestamp.toDouble();

    // Avoid division by zero on flat data
    final priceRange = (maxPrice - minPrice).abs() < 1 ? 1.0 : maxPrice - minPrice;
    final tsRange    = (maxTs - minTs).abs() < 1 ? 1.0 : maxTs - minTs;

    // Padding so line never clips the edge
    const double padH = 24.0;
    const double padV = 32.0;
    final chartW = size.width - padH * 2;
    final chartH = size.height - padV * 2;

    // ── Map a BidPoint → canvas Offset ────────────────────────────
    Offset toOffset(BidPoint p) {
      final x = padH + ((p.timestamp - minTs) / tsRange) * chartW;
      final y = padV + (1 - (p.price - minPrice) / priceRange) * chartH;
      return Offset(x, y);
    }

    // ── Build smooth path using cubic bezier ──────────────────────
    Path buildSmooth(List<BidPoint> pts) {
      if (pts.isEmpty) return Path();
      final path = Path();
      final offsets = pts.map(toOffset).toList();
      path.moveTo(offsets.first.dx, offsets.first.dy);

      for (int i = 0; i < offsets.length - 1; i++) {
        final curr = offsets[i];
        final next = offsets[i + 1];
        final cpX = (curr.dx + next.dx) / 2;
        path.cubicTo(cpX, curr.dy, cpX, next.dy, next.dx, next.dy);
      }
      return path;
    }

    // ── 1. Draw historical series (muted) ─────────────────────────
    if (historicalBids.isNotEmpty) {
      final histPath = buildSmooth(historicalBids);

      // Gradient fill under historical line
      final histFillPath = Path.from(histPath)
        ..lineTo(toOffset(historicalBids.last).dx, size.height - padV)
        ..lineTo(toOffset(historicalBids.first).dx, size.height - padV)
        ..close();

      final histFillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, padV),
          Offset(0, size.height - padV),
          [
            AppTheme.chartLine.withOpacity(0.18),
            AppTheme.chartLine.withOpacity(0.0),
          ],
        );
      canvas.drawPath(histFillPath, histFillPaint);

      // Historical line stroke
      final histLinePaint = Paint()
        ..color = AppTheme.chartLine.withOpacity(0.45)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(histPath, histLinePaint);
    }

    // ── 2. Draw live series (vivid) ───────────────────────────────
    if (livePricePoints.isNotEmpty) {
      // If historical exists, connect the two series seamlessly
      final bridgeSeed = historicalBids.isNotEmpty
          ? [historicalBids.last, ...livePricePoints]
          : livePricePoints;

      final livePath = buildSmooth(bridgeSeed);

      // Gradient fill under live line
      final liveFillPath = Path.from(livePath)
        ..lineTo(toOffset(bridgeSeed.last).dx, size.height - padV)
        ..lineTo(toOffset(bridgeSeed.first).dx, size.height - padV)
        ..close();

      final liveFillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, padV),
          Offset(0, size.height - padV),
          [
            AppTheme.chartLine.withOpacity(0.35),
            AppTheme.chartLine.withOpacity(0.0),
          ],
        );
      canvas.drawPath(liveFillPath, liveFillPaint);

      // Live line stroke — brighter + slightly thicker
      final liveLinePaint = Paint()
        ..color = AppTheme.chartLine
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(livePath, liveLinePaint);

      // ── 3. Pulse dot at latest price ────────────────────────────
      final latestOffset = toOffset(livePricePoints.last);

      // Outer glow ring (animated)
      final glowPaint = Paint()
        ..color = AppTheme.accentLight.withOpacity(
          (1 - (pulseRadius - 4) / 8).clamp(0.0, 0.5),
        )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(latestOffset, pulseRadius, glowPaint);

      // Inner solid dot
      canvas.drawCircle(
        latestOffset,
        4.0,
        Paint()..color = AppTheme.accentLight,
      );
      canvas.drawCircle(
        latestOffset,
        2.5,
        Paint()..color = Colors.white,
      );
    }

    // ── 4. Y-axis price labels (3 levels) ─────────────────────────
    _drawPriceLabels(canvas, size, minPrice, maxPrice, padH, padV, chartH);

    // ── 5. Horizontal grid lines ──────────────────────────────────
    _drawGridLines(canvas, size, padH, padV, chartH, chartW);
  }

  void _drawPriceLabels(
    Canvas canvas,
    Size size,
    double minPrice,
    double maxPrice,
    double padH,
    double padV,
    double chartH,
  ) {
    final levels = [minPrice, (minPrice + maxPrice) / 2, maxPrice];
    for (final price in levels) {
      final priceRange =
          (maxPrice - minPrice).abs() < 1 ? 1.0 : maxPrice - minPrice;
      final y = padV + (1 - (price - minPrice) / priceRange) * chartH;

      final label = price >= 1000
          ? '\$${(price / 1000).toStringAsFixed(1)}k'
          : '\$${price.toStringAsFixed(0)}';

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }
  }

  void _drawGridLines(
    Canvas canvas,
    Size size,
    double padH,
    double padV,
    double chartH,
    double chartW,
  ) {
    final gridPaint = Paint()
      ..color = AppTheme.divider.withOpacity(0.6)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 3 horizontal grid lines
    for (int i = 0; i <= 2; i++) {
      final y = padV + (i / 2) * chartH;
      canvas.drawLine(
        Offset(padH, y),
        Offset(padH + chartW, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(PriceChartPainter oldDelegate) {
    return oldDelegate.livePricePoints != livePricePoints ||
        oldDelegate.historicalBids != historicalBids ||
        oldDelegate.pulseRadius != pulseRadius ||
        oldDelegate.isParsingHistory != isParsingHistory;
  }
}
