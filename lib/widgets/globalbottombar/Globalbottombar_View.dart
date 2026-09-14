import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Profile%20screen/Profilescreen_View.dart';
import 'package:transwallet/widgets/globalbottombar/GlobalbottomBar_Controller.dart';
import 'package:transwallet/widgets/constsize.dart';

class GlobalbottombarView extends StatefulWidget {
  final RxInt seletedIndex;

  const GlobalbottombarView({super.key, required this.seletedIndex});

  @override
  State<GlobalbottombarView> createState() => _GlobalbottombarViewState();
}

class _GlobalbottombarViewState extends State<GlobalbottombarView>
    with SingleTickerProviderStateMixin {
  late AnimationController _shineController;
  final GlobalbottombarController controller = Get.put(
    GlobalbottombarController(),
  );

  static const List<Map<String, dynamic>> _tabs = [
    {
      'label': 'Home',
      'selectedIcon': 'assets/bottomafterselect/home.svg',
      'unselectedIcon': 'assets/bottomiconbeforeselect/home.svg',
      'backendIndex': 0,
    },
    {
      'label': 'Wallets',
      'selectedIcon': 'assets/bottomafterselect/wallet.svg',
      'unselectedIcon': 'assets/bottomiconbeforeselect/wallet.svg',
      'backendIndex': 1,
    },
    {
      'label': 'Statements',
      'selectedIcon': 'assets/bottomafterselect/statement.svg',
      'unselectedIcon': 'assets/bottomiconbeforeselect/statement.svg',
      'backendIndex': 2,
    },
    {
      'label': 'Profile',
      'selectedIcon': 'assets/bottomafterselect/profile.svg',
      'unselectedIcon': 'assets/bottomiconbeforeselect/profile.svg',
      'backendIndex': 3,
    },
  ];

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.responsive(14),
          0,
          context.responsive(14),
          context.responsive(12),
        ),
        child: SizedBox(
          height: context.responsive(82),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.responsive(45)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.09),
                        blurRadius: 30,
                        spreadRadius: -2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(context.responsive(45)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.4),
                        borderRadius: BorderRadius.circular(
                          context.responsive(45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: -2,
                            offset: const Offset(0, 50),
                          ),
                        ],
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(context.responsive(6)),
                child: Obx(
                  () => Row(
                    children: List.generate(_tabs.length, (index) {
                      final tab = _tabs[index];
                      final int backendIndex = tab['backendIndex'];
                      final bool selected =
                          widget.seletedIndex.value == backendIndex;

                      return Expanded(
                        child: _LiquidGlassNavItem(
                          item: tab,
                          selected: selected,
                          onTap: () {
                            controller.changeIndex(backendIndex);
                            widget.seletedIndex.value = backendIndex;
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquidGlassNavItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool selected;
  final VoidCallback onTap;

  const _LiquidGlassNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(
          horizontal: context.responsive(1),
          vertical: context.responsive(4),
        ),
        padding: EdgeInsets.symmetric(
          vertical: context.responsive(8),
          horizontal: context.responsive(4),
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color.fromRGBO(237, 237, 237, 1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(context.responsive(32)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          scale: selected ? 1.0 : 0.94,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: SvgPicture.asset(
                  selected
                      ? item['selectedIcon'] as String
                      : item['unselectedIcon'] as String,
                  key: ValueKey('${item['label']}-$selected'),
                  height: context.responsive(24),
                  width: context.responsive(24),
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: context.responsive(12),
                  height: 1,
                  color: Colors.black,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(item['label'] as String),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
