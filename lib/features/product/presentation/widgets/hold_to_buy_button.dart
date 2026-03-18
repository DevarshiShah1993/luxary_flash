import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/current_price.dart';
import '../../../../core/theme/app_theme.dart';

/// The "Hold to Secure" purchase button.
///
/// State machine (mirrors [PurchaseFlowState] in the BLoC):
///
///   idle
///     └─(press down)──► holding  [progress ring fills over 2s]
///         ├─(release early)──► idle  [ring snaps back, easeOut]
///         └─(2s complete)──► verifying  [morphs to spinner]
///             ├─(success)──► success  [morphs to checkmark ✓]
///             └─(failed)──► failed   [morphs to ✕]
///
/// All morphs share one [AnimationController] so timing stays perfectly
/// synchronised with the BLoC state without any manual coordination.
class HoldToBuyButton extends StatefulWidget {
  const HoldToBuyButton({
    super.key,
    required this.currentPrice,
    required this.purchaseFlow,
    required this.onHoldStart,
    required this.onHoldCancel,
    required this.onHoldComplete,
    required this.onReset,
  });

  final CurrentPrice currentPrice;
  final PurchaseFlowState purchaseFlow;

  final VoidCallback onHoldStart;
  final VoidCallback onHoldCancel;
  final VoidCallback onHoldComplete;
  final VoidCallback onReset;

  @override
  State<HoldToBuyButton> createState() => _HoldToBuyButtonState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Import the enum without bloc dependency (passed in from the page)
// ─────────────────────────────────────────────────────────────────────────────
// We re-declare a local alias so this widget file is self-contained.
// The page maps BLoC PurchaseFlowState → this enum.
enum PurchaseFlowState { idle, holding, verifying, success, failed }

class _HoldToBuyButtonState extends State<HoldToBuyButton>
    with TickerProviderStateMixin {
  // ── Progress ring controller (0 → 1 over 2 seconds) ──────────────
  late final AnimationController _progressCtrl;
  late final Animation<double> _progressAnim;

  // ── Morph controller: button → spinner → icon (0 → 1) ────────────
  late final AnimationController _morphCtrl;
  late final Animation<double> _morphAnim;

  // ── Spinner rotation ──────────────────────────────────────────────
  late final AnimationController _spinCtrl;

  // ── Success/fail icon scale ───────────────────────────────────────
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;

  // ── Button scale on press ─────────────────────────────────────────
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  PurchaseFlowState _prevFlow = PurchaseFlowState.idle;

  @override
  void initState() {
    super.initState();

    // Progress ring: fills over 2s
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressCtrl,
      curve: Curves.linear,
    );

    // Morph: 300ms
    _morphCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _morphAnim = CurvedAnimation(
      parent: _morphCtrl,
      curve: Curves.easeInOut,
    );

    // Spinner: continuous rotation
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Icon pop: spring-like overshoot
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _iconScale = CurvedAnimation(
      parent: _iconCtrl,
      curve: Curves.elasticOut,
    );

    // Press scale
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _pressScale = _pressCtrl;

    // Listen for progress completion
    _progressCtrl.addStatusListener(_onProgressStatus);
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      HapticFeedback.heavyImpact();
      widget.onHoldComplete();
    }
  }

  @override
  void didUpdateWidget(HoldToBuyButton old) {
    super.didUpdateWidget(old);
    if (widget.purchaseFlow != _prevFlow) {
      _handleFlowChange(widget.purchaseFlow);
      _prevFlow = widget.purchaseFlow;
    }
  }

  void _handleFlowChange(PurchaseFlowState next) {
    switch (next) {
      case PurchaseFlowState.idle:
        // Snap back: reverse progress with easeOut feel
        _progressCtrl.animateBack(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
        _morphCtrl.reverse();
        _spinCtrl.stop();
        _spinCtrl.reset();
        _iconCtrl.reverse();
        _pressCtrl.animateTo(1.0);
        break;

      case PurchaseFlowState.holding:
        HapticFeedback.selectionClick();
        _pressCtrl.animateTo(0.95);
        _progressCtrl.forward(from: _progressCtrl.value);
        break;

      case PurchaseFlowState.verifying:
        _progressCtrl.stop();
        _morphCtrl.forward(); // button → spinner
        _spinCtrl.repeat();
        break;

      case PurchaseFlowState.success:
        HapticFeedback.mediumImpact();
        _spinCtrl.stop();
        _iconCtrl.forward(); // spinner → checkmark
        break;

      case PurchaseFlowState.failed:
        HapticFeedback.heavyImpact();
        _spinCtrl.stop();
        _iconCtrl.forward(); // spinner → ✕
        break;
    }
  }

  @override
  void dispose() {
    _progressCtrl.removeStatusListener(_onProgressStatus);
    _progressCtrl.dispose();
    _morphCtrl.dispose();
    _spinCtrl.dispose();
    _iconCtrl.dispose();
    _pressCtrl.dispose();
    super.dispose();
  }

  // ── Gesture handlers ───────────────────────────────────────────────

  void _onTapDown(TapDownDetails _) {
    if (widget.purchaseFlow != PurchaseFlowState.idle) return;
    widget.onHoldStart();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.purchaseFlow == PurchaseFlowState.holding) {
      widget.onHoldCancel();
    }
  }

  void _onTapCancel() {
    if (widget.purchaseFlow == PurchaseFlowState.holding) {
      widget.onHoldCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.purchaseFlow;
    final isTerminal =
        flow == PurchaseFlowState.success || flow == PurchaseFlowState.failed;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isTerminal ? widget.onReset : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _progressAnim,
          _morphAnim,
          _spinCtrl,
          _iconScale,
          _pressScale,
        ]),
        builder: (context, _) {
          return Transform.scale(
            scale: _pressCtrl.value,
            child: _ButtonShell(
              flow: flow,
              progress: _progressAnim.value,
              morphValue: _morphAnim.value,
              spinValue: _spinCtrl.value,
              iconScale: _iconScale.value,
              currentPrice: widget.currentPrice,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Button shell — pure layout + paint, no logic
// ─────────────────────────────────────────────────────────────────────────────

class _ButtonShell extends StatelessWidget {
  const _ButtonShell({
    required this.flow,
    required this.progress,
    required this.morphValue,
    required this.spinValue,
    required this.iconScale,
    required this.currentPrice,
  });

  final PurchaseFlowState flow;
  final double progress;
  final double morphValue;     // 0 = button label, 1 = spinner/icon
  final double spinValue;      // 0→1 rotation progress
  final double iconScale;      // 0→1 for success/fail icon pop
  final CurrentPrice currentPrice;

  static const double _size = 64.0;
  static const double _buttonH = 64.0;
  static const double _ringStroke = 4.0;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder gives the real available width so we can lerp
    // from it to _size — avoids NaN from lerping double.infinity.
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 300.0; // safe fallback when unconstrained

        return SizedBox(
          height: _buttonH,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Base button body ──────────────────────────────────
              _buildButtonBody(availableWidth),

              // ── Progress ring (drawn on top) ──────────────────────
              if (flow == PurchaseFlowState.holding ||
                  flow == PurchaseFlowState.verifying)
                _ProgressRing(
                  progress: progress,
                  size: _size + 12,
                  strokeWidth: _ringStroke,
                ),

              // ── Button content (label / spinner / icon) ────────────
              _buildContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButtonBody(double availableWidth) {
    // Morphs from wide pill → circle as morphValue goes 0→1
    final borderRadius = BorderRadius.circular(
      lerpDouble(16, _size / 2, morphValue)!,
    );
    // Lerp from the actual measured width → circle diameter (no infinity)
    final width = lerpDouble(availableWidth, _size, morphValue)!;

    // Background colour
    final bgColor = switch (flow) {
      PurchaseFlowState.success => AppTheme.priceUp,
      PurchaseFlowState.failed  => AppTheme.priceDown,
      _                         => AppTheme.accent,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: _buttonH,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return switch (flow) {
      PurchaseFlowState.idle || PurchaseFlowState.holding =>
        _buildIdleLabel(),
      PurchaseFlowState.verifying => _buildSpinner(),
      PurchaseFlowState.success   => _buildIcon(Icons.check_rounded, true),
      PurchaseFlowState.failed    => _buildIcon(Icons.close_rounded, false),
    };
  }

  Widget _buildIdleLabel() {
    return Opacity(
      opacity: (1 - morphValue * 3).clamp(0.0, 1.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.background,
              size: 18,
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HOLD TO SECURE',
                  style: TextStyle(
                    color: AppTheme.background,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  currentPrice.formattedPrice,
                  style: const TextStyle(
                    color: AppTheme.background,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinner() {
    return Transform.rotate(
      angle: spinValue * 2 * 3.14159,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: const AlwaysStoppedAnimation(AppTheme.background),
          backgroundColor: AppTheme.background.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, bool isSuccess) {
    return Transform.scale(
      scale: iconScale,
      child: Icon(
        icon,
        color: AppTheme.background,
        size: 32,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress ring — CustomPainter arc
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.size,
    required this.strokeWidth,
  });

  final double progress;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
  });

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -3.14159 / 2; // top
    final sweepAngle = 2 * 3.14159 * progress;

    // Track (background ring)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * 3.14159,
      false,
      Paint()
        ..color = AppTheme.accent.withOpacity(0.15)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Filled arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..shader = ui.Gradient.sweep(
          center,
          [AppTheme.accentLight, AppTheme.accent],
          null,
          TileMode.clamp,
          startAngle,
          startAngle + sweepAngle,
        )
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}


