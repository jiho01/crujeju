import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_assistant_sheet.dart';
import '../widgets/common.dart';
import 'booking_detail_screen.dart';
import 'explore_screen.dart';
import 'guides_screen.dart';
import 'home_screen.dart';
import 'wallet_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.appState, super.key});

  final AppState appState;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _selectTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  void _openCardApplication() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (_index != 3) {
      setState(() => _index = 3);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.appState.cardApplicationComplete) return;
      Navigator.of(context).push(cardApplicationRoute(widget.appState));
    });
  }

  void _openBookingDetail(Guide guide) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(
          guide: guide,
          appState: widget.appState,
          onCardRequested: _openCardApplication,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final activeBooking = widget.appState.activeGuideBooking;
        final activeGuide = activeBooking == null
            ? null
            : AppData.guides.firstWhere(
                (guide) => guide.id == activeBooking.guideId,
              );
        return Scaffold(
          resizeToAvoidBottomInset: _index != 2,
          body: AppPage(
            child: IndexedStack(
              index: _index,
              children: [
                HomeScreen(
                  appState: widget.appState,
                  onTabChanged: _selectTab,
                  onBookingRequested:
                      activeBooking != null && activeGuide != null
                      ? () => _openBookingDetail(activeGuide)
                      : null,
                ),
                GuidesScreen(
                  appState: widget.appState,
                  onCardApplicationRequested: _openCardApplication,
                ),
                ExploreScreen(appState: widget.appState),
                WalletScreen(appState: widget.appState),
              ],
            ),
          ),
          bottomNavigationBar: _AppBottomNavigation(
            currentIndex: _index,
            onSelected: _selectTab,
          ),
          floatingActionButton: _index == 2
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_index == 0 &&
                        activeBooking != null &&
                        activeGuide != null) ...[
                      _BookingQuickAction(
                        guide: activeGuide,
                        booking: activeBooking,
                        onTap: () => _openBookingDetail(activeGuide),
                      ),
                      const SizedBox(width: 10),
                    ],
                    FloatingActionButton(
                      key: const ValueKey('global-ai-assistant'),
                      heroTag: 'global-ai-assistant',
                      onPressed: () => showAiAssistant(context),
                      elevation: 3,
                      highlightElevation: 1,
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      tooltip: 'AI 여행 도우미',
                      child: const Icon(Icons.auto_awesome_rounded, size: 24),
                    ),
                  ],
                ),
          floatingActionButtonLocation: const _AppEndFloatLocation(),
        );
      },
    );
  }
}

class _BookingQuickAction extends StatelessWidget {
  const _BookingQuickAction({
    required this.guide,
    required this.booking,
    required this.onTap,
  });

  final Guide guide;
  final GuideBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = switch (booking.status) {
      GuideBookingStatus.accepted => '예약 확정',
      GuideBookingStatus.modified => '변경 제안',
      _ => '확인 대기',
    };
    return Material(
      key: const ValueKey('home-booking-quick-action'),
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x30123A63),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 184,
          height: 56,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 8, 11, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandWeak,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    size: 20,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '예약 정보',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        '${guide.name} · $status',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppEndFloatLocation extends FloatingActionButtonLocation {
  const _AppEndFloatLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    const maxAppWidth = 600.0;
    const horizontalMargin = 20.0;
    const bottomMargin = 16.0;
    final scaffoldWidth = scaffoldGeometry.scaffoldSize.width;
    final appWidth = scaffoldWidth > maxAppWidth ? maxAppWidth : scaffoldWidth;
    final appRight = (scaffoldWidth + appWidth) / 2;
    final x =
        appRight -
        horizontalMargin -
        scaffoldGeometry.floatingActionButtonSize.width;
    final y =
        scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height -
        bottomMargin;
    return Offset(x, y);
  }
}

class _AppBottomNavigation extends StatelessWidget {
  const _AppBottomNavigation({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, '홈'),
    (Icons.person_search_rounded, Icons.person_search_outlined, '가이드'),
    (Icons.explore_rounded, Icons.explore_outlined, '둘러보기'),
    (Icons.credit_card_rounded, Icons.credit_card_outlined, '카드'),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceSecondary,
      child: Center(
        heightFactor: 1,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 66,
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final selected = currentIndex == index;
                  return Expanded(
                    child: Semantics(
                      selected: selected,
                      label: item.$3,
                      button: true,
                      child: InkWell(
                        key: ValueKey('bottom-tab-$index'),
                        onTap: () => onSelected(index),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selected ? item.$1 : item.$2,
                              color: selected
                                  ? AppColors.brand
                                  : AppColors.textTertiary,
                              size: 24,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.$3,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: selected
                                        ? AppColors.brand
                                        : AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
