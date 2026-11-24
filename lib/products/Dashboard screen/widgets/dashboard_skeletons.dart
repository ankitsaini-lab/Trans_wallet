import 'package:flutter/material.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/shimmer_widget.dart';

/// Skeleton loader for Wallet Cards and Balance.
///
/// Designed to perfectly match the dimensions of [RealisticWalletWidget]
/// to eliminate any layout shifting during loading.
class WalletCardsAndBalanceSkeleton extends StatelessWidget {
  final double availableWidth;
  final double cardHeight;
  final double containerHeight;
  final bool isError;
  final VoidCallback? onRetry;

  const WalletCardsAndBalanceSkeleton({
    super.key,
    required this.availableWidth,
    required this.cardHeight,
    required this.containerHeight,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isError) {
      return Container(
        height: containerHeight,
        width: availableWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: primaryLightYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_card_off_rounded,
                size: 24,
                color: primaryRed,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Unable to load wallet card",
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Could not fetch your card details",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text(
                    "Retry",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Skeleton Shimmer matching RealisticWalletWidget
    return SizedBox(
      height: containerHeight,
      width: availableWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Tucked Card Skeleton in background pocket
          Positioned(
            top: context.responsive(12),
            left: context.responsive(40),
            right: context.responsive(40),
            height: cardHeight,
            child: ShimmerEffect(
              baseColor: const Color(0xFFD1D5DB),
              highlightColor: const Color(0xFFF3F4F6),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.12),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Card chip placeholder
                        ShimmerBox(
                          width: context.responsive(38),
                          height: context.responsive(26),
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFFCBD5E1),
                        ),
                        // Network logo placeholder
                        ShimmerBox(
                          width: context.responsive(45),
                          height: context.responsive(20),
                          borderRadius: BorderRadius.circular(4),
                          color: const Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Card number placeholder
                    ShimmerBox(
                      width: context.responsive(160),
                      height: context.responsive(14),
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFFCBD5E1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Realistic Wallet Front Pocket Graphic
          Positioned(
            bottom: context.responsive(53),
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Image.asset('assets/frontwallet.png', fit: BoxFit.contain),
            ),
          ),

          // 3. Front Pocket Balance Shimmer
          Positioned(
            bottom: context.responsive(72),
            left: 0,
            right: 0,
            child: ShimmerEffect(
              baseColor: Colors.white.withValues(alpha: 0.22),
              highlightColor: Colors.white.withValues(alpha: 0.55),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "Total Balance" placeholder
                  ShimmerBox(
                    width: context.responsive(90),
                    height: context.responsive(14),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  SizedBox(height: context.responsive(6)),
                  // Balance amount placeholder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerBox(
                        width: context.responsive(120),
                        height: context.responsive(22),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      SizedBox(width: context.responsive(8)),
                      ShimmerCircle(
                        size: context.responsive(22),
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                  SizedBox(height: context.responsive(6)),
                  // "Secured by RBI" badge placeholder
                  ShimmerBox(
                    width: context.responsive(85),
                    height: context.responsive(10),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),

          // 4. Explore More Pill placeholder at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ShimmerEffect(
                baseColor: const Color(0xFF1E293B),
                highlightColor: const Color(0xFF334155),
                child: ShimmerBox(
                  width: context.responsive(120),
                  height: context.responsive(32),
                  borderRadius: BorderRadius.circular(context.responsive(20)),
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for the Recent Transactions list.
///
/// Matches the exact padding, icon dimensions, and row heights
/// of the Dashboard recent transactions section.
class RecentTransactionsSkeleton extends StatelessWidget {
  final int count;

  const RecentTransactionsSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        children: List.generate(count, (index) {
          final isLast = index == count - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Circle Skeleton
                    ShimmerCircle(size: context.responsive(48)),
                    const SizedBox(width: 16),
                    // Title and Subtitle Skeleton
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(
                            width: context.responsive(
                              index % 2 == 0 ? 130 : 105,
                            ),
                            height: context.responsive(15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 6),
                          ShimmerBox(
                            width: context.responsive(75),
                            height: context.responsive(11),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    // Amount Skeleton
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShimmerBox(
                          width: context.responsive(65),
                          height: context.responsive(16),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        ShimmerBox(
                          width: context.responsive(35),
                          height: context.responsive(10),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  color: Colors.grey.shade100,
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
            ],
          );
        }),
      ),
    );
  }
}

/// Retry container for the Recent Transactions section.
class RecentTransactionsErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;

  const RecentTransactionsErrorView({
    super.key,
    required this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: primaryLightYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 24,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message ?? "Unable to Load Transactions",
            style: const TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Please check your network and tap retry",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text(
                "Retry",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for the Spending Analytics section.
///
/// Matches the exact container, metric chips, chart area, week pills,
/// and summary breakdown cards of the analytics card.
class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 5,
            spreadRadius: 0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ShimmerEffect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Metric filter chips placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ShimmerBox(
                    width: 76,
                    height: 32,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  const SizedBox(width: 8),
                  ShimmerBox(
                    width: 88,
                    height: 32,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Chart wave placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShimmerBox(
                          width: 16,
                          height: 45,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        ShimmerBox(
                          width: 16,
                          height: 70,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        ShimmerBox(
                          width: 16,
                          height: 35,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        ShimmerBox(
                          width: 16,
                          height: 55,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    Divider(
                      color: const Color(0xFFE2E8F0),
                      thickness: 1,
                      height: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Week pills placeholder (W1, W2, W3, W4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (_) {
                  return ShimmerBox(
                    width: 48,
                    height: 28,
                    borderRadius: BorderRadius.circular(14),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Helper tap banner placeholder
            Center(
              child: ShimmerBox(
                width: 210,
                height: 26,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 14),

            // 5. Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Divider(
                color: Colors.grey.shade200,
                thickness: 1,
                height: 1,
              ),
            ),
            const SizedBox(height: 18),

            // 6. Summary breakdown stat columns placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                          width: 75,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        ShimmerBox(
                          width: 95,
                          height: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                          width: 75,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        ShimmerBox(
                          width: 95,
                          height: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Retry container for the Spending Analytics section.
class AnalyticsErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;

  const AnalyticsErrorView({super.key, required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 5,
            spreadRadius: 0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: primaryLightYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 24,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message ?? "Unable to Load Analytics",
            style: const TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Please check your network and tap retry",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text(
                "Retry",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
