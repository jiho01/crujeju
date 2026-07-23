import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_assistant_sheet.dart';
import '../widgets/common.dart';

Route<void> cardApplicationRoute(AppState appState) {
  return MaterialPageRoute<void>(
    builder: (_) => _CardApplicationScreen(appState: appState),
  );
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({required this.appState, super.key});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    if (!appState.cardApplicationComplete) {
      return _UnissuedWallet(
        appState: appState,
        onApply: () =>
            Navigator.of(context).push(cardApplicationRoute(appState)),
      );
    }
    if (appState.cardAwaitingPickup) {
      return _PickupWallet(
        appState: appState,
        onShowQr: () => _showReceiveQr(context),
        onReceived: () {
          appState.receiveCard();
          showAppSnack(context, '카드 수령을 완료했어요');
        },
      );
    }

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('wallet-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'CRUJEJU 카드',
              subtitle: '환전 없이 제주 어디서나 결제해요',
            ),
          ),
          SliverToBoxAdapter(
            child: _PrepaidCard(
              locked: appState.cardLocked,
              balance: appState.cardBalance,
              online: appState.cardOnline,
              onToggleSync: appState.toggleCardConnection,
            ),
          ),
          SliverToBoxAdapter(
            child: _QuickActions(
              locked: appState.cardLocked,
              onCharge: () => _showChargeSheet(context),
              onHistory: () => _showAllPayments(context),
              onLock: () => _toggleLock(context),
              onRefund: () => _showRefundInfo(context),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: '오늘 카드 내역',
              subtitle: '사용 99,000원 · 충전 200,000원',
              actionLabel: '전체 보기',
              onAction: () => _showAllPayments(context),
            ),
          ),
          SliverToBoxAdapter(child: _PaymentList(records: AppData.payments)),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '이용 안내',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.assignment_return_outlined,
                    title: '카드 반납과 잔액 환불',
                    subtitle: '${appState.cruise.port} 키오스크 · 출항 30분 전까지',
                    onTap: () => _showRefundInfo(context),
                  ),
                  const Divider(indent: 54),
                  _InfoTile(
                    icon: Icons.support_agent_rounded,
                    title: '카드 분실과 고객지원',
                    subtitle: '24시간 다국어 상담을 연결해요',
                    onTap: () => showAppSnack(context, '다국어 고객센터에 연결할 준비가 됐어요'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLock(BuildContext context) {
    appState.toggleCardLock();
    showAppSnack(
      context,
      appState.cardLocked ? '카드를 잠갔어요. 결제가 차단돼요' : '카드 잠금을 풀었어요',
    );
  }

  void _showReceiveQr(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('카드 수령 QR', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '${appState.cruise.port} 여객터미널 1번 키오스크에서 보여주세요',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            Container(
              width: 190,
              height: 190,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const CustomPaint(painter: _QrPainter()),
            ),
            const SizedBox(height: 18),
            MetaPill(
              label:
                  '${appState.cruise.date} · ${_addMinutes(appState.cruise.arrival, 20)}부터 수령 가능',
              selected: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showChargeSheet(BuildContext context) {
    var selectedAmount = 100000;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '얼마를 충전할까요?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '남은 일정에는 8만–12만원이 적당해요',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    formatWon(selectedAmount),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [50000, 100000, 150000].map((amount) {
                    final selected = amount == selectedAmount;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: amount == 150000 ? 0 : 8,
                        ),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              formatWon(amount),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setSheetState(() => selectedAmount = amount),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                SurfaceCard(
                  color: AppColors.surfaceSecondary,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _AmountRow(
                        label: '충전금',
                        value: formatWon(selectedAmount),
                      ),
                      const SizedBox(height: 8),
                      const _AmountRow(label: '수수료', value: '0원'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      appState.chargeCard(selectedAmount);
                      Navigator.pop(context);
                      showAppSnack(
                        context,
                        '${formatWon(selectedAmount)} 충전을 요청했어요',
                      );
                    },
                    child: Text('${formatWon(selectedAmount)} 충전하기'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAllPayments(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        minChildSize: .5,
        maxChildSize: .92,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          children: [
            Text('결제내역', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '오늘 · 사용 99,000원 · 충전 200,000원',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            _PaymentList(records: AppData.payments, padding: EdgeInsets.zero),
          ],
        ),
      ),
    );
  }

  void _showRefundInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('카드 반납과 환불', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '${appState.cruise.port} 키오스크에서 2분이면 끝나요',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const _RefundStep(number: '1', title: '카드를 키오스크에 넣어요'),
            const _RefundStep(number: '2', title: '잔액과 보증금을 확인해요'),
            const _RefundStep(
              number: '3',
              title: '원래 결제수단으로 환불받아요',
              last: true,
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              color: AppColors.brandWeak,
              child: Column(
                children: [
                  _AmountRow(
                    label: '현재 잔액',
                    value: formatWon(appState.cardBalance),
                  ),
                  const SizedBox(height: 8),
                  const _AmountRow(label: '카드 보증금', value: '5,000원'),
                  const Divider(height: 24),
                  _AmountRow(
                    label: '예상 환불금액',
                    value: formatWon(appState.cardBalance + 5000),
                    emphasized: true,
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

class _UnissuedWallet extends StatelessWidget {
  const _UnissuedWallet({required this.appState, required this.onApply});

  final AppState appState;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('wallet-unissued-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'CRUJEJU 카드',
              subtitle: '환전 없이 제주 어디서나 결제해요',
              action: RoundIconButton(
                icon: Icons.auto_awesome_rounded,
                onPressed: () => showAiAssistant(
                  context,
                  initialQuestion: '제주 여행에 카드를 얼마 충전하면 좋을까?',
                ),
                tooltip: 'AI에게 충전금액 물어보기',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SurfaceCard(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
              color: AppColors.oceanWeak,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.credit_card_rounded,
                      size: 34,
                      color: AppColors.ocean,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '아직 연결된 카드가 없어요',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${appState.cruise.port}에서 카드를 받고\n남은 금액은 출항 전에 환불받아요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: '카드 하나로 간편하게',
              subtitle: '신청부터 환불까지 앱에서 확인해요',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                children: const [
                  _CardBenefitRow(
                    icon: Icons.language_rounded,
                    title: '환전 없이 바로 결제',
                    description: '일반 카드 단말기가 있는 매장에서 사용할 수 있어요.',
                    color: AppColors.brand,
                    background: AppColors.brandWeak,
                  ),
                  SizedBox(height: 10),
                  _CardBenefitRow(
                    icon: Icons.location_on_outlined,
                    title: '크루즈터미널에서 수령',
                    description: '입항 일정에 맞춰 지정 키오스크에 준비해요.',
                    color: AppColors.ocean,
                    background: AppColors.oceanWeak,
                  ),
                  SizedBox(height: 10),
                  _CardBenefitRow(
                    icon: Icons.currency_exchange_rounded,
                    title: '잔액과 보증금 환불',
                    description: '카드 반납 후 원래 결제수단으로 돌려받아요.',
                    color: AppColors.brandNavy,
                    background: AppColors.brandNavyWeak,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onApply,
                      child: const Text('CRUJEJU 카드 신청하기'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '카드 보증금 5,000원 · 반납 시 전액 환불',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupWallet extends StatelessWidget {
  const _PickupWallet({
    required this.appState,
    required this.onShowQr,
    required this.onReceived,
  });

  final AppState appState;
  final VoidCallback onShowQr;
  final VoidCallback onReceived;

  @override
  Widget build(BuildContext context) {
    final cruise = appState.cruise;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('wallet-pickup-scroll'),
        slivers: [
          const SliverToBoxAdapter(
            child: PageHeader(
              title: 'CRUJEJU 카드',
              subtitle: '신청 완료 · 터미널 수령 대기',
            ),
          ),
          SliverToBoxAdapter(
            child: SurfaceCard(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              color: AppColors.brandWeak,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '카드가 준비됐어요',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '수령 전에는 카드 번호와 잔액을 표시하지 않아요.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          const SliverToBoxAdapter(
            child: SectionHeader(title: '수령 장소', subtitle: '입항 일정에 맞춰 준비했어요'),
          ),
          SliverToBoxAdapter(
            child: SurfaceCard(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              color: AppColors.surfaceSecondary,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 196,
                          child: Image.asset(
                            key: const ValueKey('pickup-location-image'),
                            cruise.port == '강정항'
                                ? 'assets/images/pickup_store_gangjeong.png'
                                : 'assets/images/pickup_terminal_jeju.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const EmptyImageFallback(),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .94),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '카드 발급기 위치 안내',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.oceanWeak,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.ocean,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cruise.port} 여객터미널',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '1번 CRUJEJU 키오스크',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(),
                  ),
                  _ApplicationInfoRow(label: '수령 날짜', value: cruise.date),
                  const SizedBox(height: 9),
                  _ApplicationInfoRow(
                    label: '수령 가능시간',
                    value: '${_addMinutes(cruise.arrival, 20)}부터',
                  ),
                  const SizedBox(height: 16),
                  _PickupMiniMap(port: cruise.port),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          const SliverToBoxAdapter(
            child: SectionHeader(title: '수령 방법', subtitle: '키오스크에서 1분이면 끝나요'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: const [
                  _PickupStep(number: '1', text: '1번 키오스크에서 카드 수령을 선택해요'),
                  _PickupStep(number: '2', text: '아래 수령 QR을 스캔해요'),
                  _PickupStep(number: '3', text: '나온 카드를 확인하고 수령 완료를 눌러요'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SurfaceCard(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const CustomPaint(painter: _QrPainter()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '카드 수령 QR',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '키오스크 화면의 스캐너에 보여주세요.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: onShowQr,
                          child: const Text('QR 크게 보기'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('card-pickup-complete'),
                  onPressed: onReceived,
                  child: const Text('카드 수령 완료'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupStep extends StatelessWidget {
  const _PickupStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brandWeak,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.brand),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PickupMiniMap extends StatelessWidget {
  const _PickupMiniMap({required this.port});

  final String port;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('pickup-location-map'),
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _PickupMapPainter()),
          ),
          Positioned(
            left: 14,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$port 터미널 1층 안내도',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          const Align(
            alignment: Alignment(-0.72, 0.65),
            child: _MapFacility(
              icon: Icons.sensor_door_outlined,
              label: '입항장 출입구',
            ),
          ),
          const Align(
            alignment: Alignment(-0.38, -0.18),
            child: _MapFacility(
              icon: Icons.info_outline_rounded,
              label: '관광안내소',
            ),
          ),
          const Align(
            alignment: Alignment(0.48, -0.2),
            child: _MapFacility(
              icon: Icons.storefront_outlined,
              label: '편의점 데스크',
            ),
          ),
          const Align(
            alignment: Alignment(0.63, 0.65),
            child: _MapFacility(
              icon: Icons.credit_card_rounded,
              label: '1번 키오스크',
              highlighted: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFacility extends StatelessWidget {
  const _MapFacility({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.brand : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? AppColors.brand : AppColors.line,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F1720),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: highlighted ? Colors.white : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: highlighted ? Colors.white : AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupMapPainter extends CustomPainter {
  const _PickupMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final roomPaint = Paint()..color = Colors.white;
    final wallPaint = Paint()
      ..color = const Color(0xFFD8E2EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final terminal = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .04,
        size.height * .25,
        size.width * .92,
        size.height * .66,
      ),
      const Radius.circular(14),
    );
    canvas
      ..drawRRect(terminal, roomPaint)
      ..drawRRect(terminal, wallPaint)
      ..drawLine(
        Offset(size.width * .5, size.height * .25),
        Offset(size.width * .5, size.height * .62),
        wallPaint,
      )
      ..drawLine(
        Offset(size.width * .18, size.height * .62),
        Offset(size.width * .82, size.height * .62),
        wallPaint,
      );

    final routePaint = Paint()
      ..color = AppColors.brand
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;
    final routePoints = [
      Offset(size.width * .18, size.height * .8),
      Offset(size.width * .38, size.height * .72),
      Offset(size.width * .58, size.height * .78),
      Offset(size.width * .76, size.height * .78),
    ];
    for (var i = 0; i < routePoints.length - 1; i++) {
      final start = routePoints[i];
      final end = routePoints[i + 1];
      for (var step = 0; step < 6; step += 2) {
        canvas.drawLine(
          Offset.lerp(start, end, step / 6)!,
          Offset.lerp(start, end, (step + 1) / 6)!,
          routePaint,
        );
      }
    }
    canvas.drawCircle(routePoints.last, 5, Paint()..color = AppColors.brand);
  }

  @override
  bool shouldRepaint(covariant _PickupMapPainter oldDelegate) => false;
}

class _CardBenefitRow extends StatelessWidget {
  const _CardBenefitRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      color: AppColors.surfaceSecondary,
      radius: 16,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 3),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardApplicationScreen extends StatefulWidget {
  const _CardApplicationScreen({required this.appState});

  final AppState appState;

  @override
  State<_CardApplicationScreen> createState() => _CardApplicationScreenState();
}

class _CardApplicationScreenState extends State<_CardApplicationScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _amountController = TextEditingController(
    text: '100000',
  );
  int _step = 0;
  String _paymentMethod = '해외 신용카드';
  int _chargeAmount = 100000;
  bool _agreed = false;
  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: AppPage(
        child: SafeArea(
          child: Column(
            children: [
              _ApplicationHeader(step: _step, onBack: _goBack),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (value) => setState(() => _step = value),
                  children: [
                    _buildPickupStep(),
                    _buildPaymentStep(),
                    _buildAmountStep(),
                    _buildConfirmationStep(),
                  ],
                ),
              ),
              _ApplicationBottomAction(
                step: _step,
                enabled: switch (_step) {
                  2 => _chargeAmount >= 10000,
                  3 => _agreed,
                  _ => true,
                },
                loading: _submitting,
                onPressed: _goNext,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepLayout({
    required String eyebrow,
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.brand),
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 9),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPickupStep() {
    final cruise = widget.appState.cruise;
    return _stepLayout(
      eyebrow: '카드 수령',
      title: '카드를 어디서\n받을지 확인해요',
      description: '등록한 크루즈 일정에 맞춰 자동으로 준비했어요.',
      children: [
        SurfaceCard(
          color: AppColors.oceanWeak,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.ocean,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cruise.port} 여객터미널',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1번 CRUJEJU 키오스크',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              _ApplicationInfoRow(label: '수령 날짜', value: cruise.date),
              const SizedBox(height: 10),
              _ApplicationInfoRow(
                label: '수령 가능시간',
                value: '${_addMinutes(cruise.arrival, 20)}부터',
              ),
              const SizedBox(height: 10),
              _ApplicationInfoRow(label: '선박', value: cruise.shipName),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    const options = [
      ('해외 신용카드', 'Visa · Mastercard · JCB', Icons.credit_card_rounded),
      ('간편결제', 'Apple Pay · Google Pay', Icons.account_balance_wallet_outlined),
    ];
    return _stepLayout(
      eyebrow: '결제수단',
      title: '충전할 결제수단을\n선택해요',
      description: '카드 반납 후 잔액도 같은 결제수단으로 환불해요.',
      children: options.map((option) {
        final selected = _paymentMethod == option.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: selected ? AppColors.brandWeak : AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: () => setState(() => _paymentMethod = option.$1),
              borderRadius: BorderRadius.circular(17),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: selected ? AppColors.brand : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      option.$3,
                      color: selected
                          ? AppColors.brand
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.$1,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.$2,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selected
                          ? AppColors.brand
                          : AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountStep() {
    return _stepLayout(
      eyebrow: '충전금액',
      title: '얼마를 충전할까요?',
      description: '필요한 금액을 직접 입력하거나 아래 금액을 빠르게 선택하세요.',
      children: [
        Center(
          child: Text(
            formatWon(_chargeAmount),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('card-charge-amount-input'),
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(7),
          ],
          onChanged: (value) {
            setState(() => _chargeAmount = int.tryParse(value) ?? 0);
          },
          decoration: const InputDecoration(
            labelText: '직접 입력',
            hintText: '충전할 금액을 입력하세요',
            prefixIcon: Icon(Icons.edit_outlined),
            suffixText: '원',
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [100000, 500000, 1000000].map((amount) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: amount == 1000000 ? 0 : 8),
                child: ChoiceChip(
                  label: SizedBox(
                    width: double.infinity,
                    child: Text(
                      '${amount ~/ 10000}만원',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  selected: _chargeAmount == amount,
                  showCheckmark: false,
                  onSelected: (_) {
                    _amountController.text = amount.toString();
                    _amountController.selection = TextSelection.collapsed(
                      offset: _amountController.text.length,
                    );
                    setState(() => _chargeAmount = amount);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return _stepLayout(
      eyebrow: '최종 확인',
      title: '신청 내용을\n확인해 주세요',
      description: '결제 후 카드 수령 QR을 바로 확인할 수 있어요.',
      children: [
        SurfaceCard(
          color: AppColors.surfaceSecondary,
          child: Column(
            children: [
              _AmountRow(label: '충전금', value: formatWon(_chargeAmount)),
              const SizedBox(height: 10),
              const _AmountRow(label: '카드 보증금', value: '5,000원'),
              const SizedBox(height: 10),
              const _AmountRow(label: '발급 수수료', value: '0원'),
              const Divider(height: 28),
              _AmountRow(
                label: '총 결제금액',
                value: formatWon(_chargeAmount + 5000),
                emphasized: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          padding: EdgeInsets.zero,
          color: AppColors.surfaceSecondary,
          child: CheckboxListTile(
            value: _agreed,
            onChanged: (value) => setState(() => _agreed = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.brand,
            title: Text(
              '카드 이용과 환불 안내를 확인했어요',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              '남은 잔액과 보증금은 카드 반납 후 환불돼요',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goNext() async {
    if (_step < 3) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!_agreed) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    widget.appState.applyForCard(_chargeAmount);
    if (mounted) Navigator.pop(context);
  }
}

class _ApplicationHeader extends StatelessWidget {
  const _ApplicationHeader({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              RoundIconButton(
                onPressed: onBack,
                icon: Icons.arrow_back_rounded,
                tooltip: '뒤로가기',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '카드 신청',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${step + 1}/4',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) => Container(
              height: 4,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: constraints.maxWidth * (step + 1) / 4,
                color: AppColors.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationBottomAction extends StatelessWidget {
  const _ApplicationBottomAction({
    required this.step,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final int step;
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled && !loading ? onPressed : null,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(step == 3 ? '총 금액 결제하고 신청하기' : '다음'),
        ),
      ),
    );
  }
}

class _ApplicationInfoRow extends StatelessWidget {
  const _ApplicationInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

String _addMinutes(String value, int minutes) {
  final parts = value.split(':');
  if (parts.length != 2) return value;
  final total =
      (int.tryParse(parts[0]) ?? 0) * 60 +
      (int.tryParse(parts[1]) ?? 0) +
      minutes;
  return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
}

class _PrepaidCard extends StatelessWidget {
  const _PrepaidCard({
    required this.locked,
    required this.balance,
    required this.online,
    required this.onToggleSync,
  });

  final bool locked;
  final int balance;
  final bool online;
  final VoidCallback onToggleSync;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: AspectRatio(
        aspectRatio: 1.56,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8F3FF), Color(0xFFCFE4FF)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFBFD9F6)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -38,
                top: -52,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.brand.withValues(alpha: .13),
                      width: 38,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CRUJEJU',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.brandNavy),
                        ),
                        const Spacer(),
                        _SyncStatus(online: online, onTap: onToggleSync),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      locked ? '카드가 잠겨 있어요' : '사용 가능한 금액',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatWon(balance),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '5412  ••••  ••••  8026',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                          size: 18,
                          color: locked
                              ? AppColors.danger
                              : AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({required this.online, required this.onTap});

  final bool online;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = online ? AppColors.brand : Colors.white;
    return Tooltip(
      message: online ? '온라인 상태' : '데이터 연결 없음',
      child: Material(
        color: online ? Colors.white : AppColors.danger,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          key: const ValueKey('card-sync-status'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  online ? Icons.sync_rounded : Icons.sync_disabled_rounded,
                  size: 15,
                  color: foreground,
                ),
                const SizedBox(width: 5),
                Text(
                  online ? '잔액 동기화 중' : '동기화 안 됨',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.locked,
    required this.onCharge,
    required this.onHistory,
    required this.onLock,
    required this.onRefund,
  });

  final bool locked;
  final VoidCallback onCharge;
  final VoidCallback onHistory;
  final VoidCallback onLock;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.add_card_rounded, '충전', onCharge),
      (Icons.receipt_long_outlined, '내역', onHistory),
      (
        locked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
        locked ? '잠금 해제' : '카드 잠금',
        onLock,
      ),
      (Icons.assignment_return_outlined, '환불', onRefund),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: actions.map((action) {
          return Expanded(
            child: InkWell(
              onTap: action.$3,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        action.$1,
                        size: 21,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      action.$2,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({
    required this.records,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 0),
  });

  final List<PaymentRecord> records;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final sortedRecords = List<PaymentRecord>.of(records)
      ..sort(
        (a, b) => _paymentMinutes(b.time).compareTo(_paymentMinutes(a.time)),
      );
    return Padding(
      padding: padding,
      child: Container(
        key: const ValueKey('payment-list-panel'),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < sortedRecords.length; index++) ...[
              _PaymentRow(record: sortedRecords[index]),
              if (index != sortedRecords.length - 1)
                const Divider(height: 1, indent: 72),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.record});

  final PaymentRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('payment-${record.store}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(record.icon, size: 21, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.store,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.category} · ${record.time}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${record.isCharge ? '+' : '-'}${formatWon(record.amount)}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: record.isCharge ? AppColors.success : AppColors.danger,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

int _paymentMinutes(String time) {
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(time);
  if (match == null) return 0;
  return (int.tryParse(match.group(1)!) ?? 0) * 60 +
      (int.tryParse(match.group(2)!) ?? 0);
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: AppColors.surfaceSecondary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      title: Text(title, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(
              color: emphasized
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: style?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _RefundStep extends StatelessWidget {
  const _RefundStep({
    required this.number,
    required this.title,
    this.last = false,
  });

  final String number;
  final String title;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.brandWeak,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.brand),
              ),
            ),
            if (!last) Container(width: 1, height: 26, color: AppColors.line),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.textPrimary;
    const matrix = [
      '1111111001011111111',
      '1000001010010000001',
      '1011101001010111011',
      '1011101011010111011',
      '1011101000010111011',
      '1000001011010000001',
      '1111111010101111111',
      '0000000011100000000',
      '1010111110111010101',
      '0111010011001101110',
      '1100111100110110011',
      '0000000011010101100',
      '1111111010111010111',
      '1000001001100011100',
      '1011101010111110111',
      '1011101001000101010',
      '1011101011111010111',
      '1000001010010110010',
      '1111111011101101111',
    ];
    final cell = size.width / matrix.length;
    for (var y = 0; y < matrix.length; y++) {
      for (var x = 0; x < matrix[y].length; x++) {
        if (matrix[y][x] == '1') {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell + .2, cell + .2),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
