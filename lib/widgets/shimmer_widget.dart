import 'package:flutter/material.dart';

/// A high-performance, native Shimmer effect widget using ShaderMask and LinearGradient.
///
/// Designed to provide a smooth, premium skeleton loading experience without external dependencies.
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE5E7EB),
    this.highlightColor = const Color(0xFFF9FAFB),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              colors: [
                widget.baseColor,
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
                widget.baseColor,
              ],
              transform: _SlidingGradientTransform(
                slidePercent: _animController.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Translate from -width to +width across the cycle
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0.0,
      0.0,
    );
  }
}

/// A versatile skeleton placeholder box with rounded corners.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE2E8F0),
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : (borderRadius ?? BorderRadius.circular(8)),
      ),
    );
  }
}

/// A circular shimmer placeholder for icons and avatars.
class ShimmerCircle extends StatelessWidget {
  final double size;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const ShimmerCircle({
    super.key,
    required this.size,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: size,
      height: size,
      shape: BoxShape.circle,
      color: color,
      margin: margin,
    );
  }
}

