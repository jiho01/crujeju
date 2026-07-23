import 'package:flutter/material.dart';

import '../data/guide_itinerary.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';

Future<void> showGuideChatSheet(
  BuildContext context, {
  required Guide guide,
  required AppState appState,
}) {
  appState.markGuideConversationRead(guide.id);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: .88,
      child: GuideChatPanel(
        guide: guide,
        appState: appState,
        onClose: () => Navigator.pop(context),
      ),
    ),
  );
}

class GuideChatPanel extends StatefulWidget {
  const GuideChatPanel({
    required this.guide,
    required this.appState,
    super.key,
    this.onClose,
  });

  final Guide guide;
  final AppState appState;
  final VoidCallback? onClose;

  @override
  State<GuideChatPanel> createState() => _GuideChatPanelState();
}

class _GuideChatPanelState extends State<GuideChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _replying = false;
  bool _bookingRequestExpanded = true;

  @override
  void initState() {
    super.initState();
    widget.appState.markGuideConversationRead(widget.guide.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final messages = widget.appState.messagesForGuide(widget.guide.id);
        final booking = widget.appState.bookingForGuide(widget.guide.id);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return ColoredBox(
          color: AppColors.surface,
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: Column(
              children: [
                _ChatHeader(guide: widget.guide, onClose: widget.onClose),
                const Divider(),
                if (booking != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                    child: _GuideBookingRequestCard(
                      booking: booking,
                      appState: widget.appState,
                      expanded: _bookingRequestExpanded,
                      onToggle: () => setState(
                        () =>
                            _bookingRequestExpanded = !_bookingRequestExpanded,
                      ),
                      onAccept: () =>
                          widget.appState.acceptGuideBooking(widget.guide.id),
                      onReject: () =>
                          widget.appState.rejectGuideBooking(widget.guide.id),
                      onModify: () => _showModifyBooking(booking),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    key: const ValueKey('guide-chat-messages'),
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                    itemCount: messages.length + (_replying ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const _TypingBubble();
                      }
                      final message = messages[index];
                      return _MessageBubble(message: message);
                    },
                  ),
                ),
                _ChatComposer(controller: _controller, onSend: _send),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showModifyBooking(GuideBooking booking) async {
    const transportOptions = [
      ('가이드 승용차', 0),
      ('프리미엄 밴', 70000),
      ('택시 동행', -30000),
    ];
    var selectedTransport = transportOptions.firstWhere(
      (option) => option.$1 == booking.transport,
      orElse: () => transportOptions.first,
    );
    var selectedLanguage = booking.language;
    var selectedTimeRange = RangeValues(
      _bookingTimeValue(booking.startTime),
      _bookingTimeValue(booking.endTime),
    );

    final updated = await showModalBottomSheet<GuideBooking>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final durationMinutes =
              ((selectedTimeRange.end - selectedTimeRange.start) * 60).round();
          final durationPriceDelta = ((durationMinutes - 360) ~/ 30) * 12500;
          final total =
              widget.guide.price + selectedTransport.$2 + durationPriceDelta;
          final startTime = _formatBookingTime(selectedTimeRange.start);
          final endTime = _formatBookingTime(selectedTimeRange.end);
          return FractionallySizedBox(
            key: const ValueKey('chat-booking-modify-sheet'),
            heightFactor: .82,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '예약 옵션 수정',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '변경한 시간과 이동수단에 맞춰 금액을 다시 계산해요.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '사용 언어',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.guide.languages.map((language) {
                            return ChoiceChip(
                              key: ValueKey('chat-booking-language-$language'),
                              label: Text(language),
                              selected: language == selectedLanguage,
                              showCheckmark: false,
                              onSelected: (_) => setSheetState(
                                () => selectedLanguage = language,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '이동수단',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: transportOptions.map((option) {
                            return ChoiceChip(
                              key: ValueKey(
                                'chat-booking-transport-${option.$1}',
                              ),
                              label: Text(option.$1),
                              selected: option == selectedTransport,
                              showCheckmark: false,
                              onSelected: (_) => setSheetState(
                                () => selectedTransport = option,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              '투어 시간',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Text(
                              '$startTime – $endTime · '
                              '${_bookingDurationLabel(durationMinutes)}',
                              key: const ValueKey('chat-booking-time-summary'),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: AppColors.brand),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandWeak,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              RangeSlider(
                                key: const ValueKey('chat-booking-time-range'),
                                values: selectedTimeRange,
                                min: 9,
                                max: 18,
                                divisions: 18,
                                labels: RangeLabels(startTime, endTime),
                                onChanged: (value) {
                                  if (value.end - value.start < 3) return;
                                  setSheetState(
                                    () => selectedTimeRange = RangeValues(
                                      (value.start * 2).round() / 2,
                                      (value.end * 2).round() / 2,
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '09:00',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                    Text(
                                      '18:00',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SurfaceCard(
                          color: AppColors.surfaceSecondary,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '변경 예상금액',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                formatWon(total),
                                key: const ValueKey(
                                  'chat-booking-modified-total',
                                ),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: AppColors.brandNavy),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.line)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('chat-booking-modify-submit'),
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          booking.copyWith(
                            transport: selectedTransport.$1,
                            language: selectedLanguage,
                            startTime: startTime,
                            endTime: endTime,
                            durationMinutes: durationMinutes,
                            total: total,
                            status: GuideBookingStatus.modified,
                          ),
                        ),
                        child: const Text('수정안 보내기'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (updated == null || !mounted) return;
    widget.appState.modifyGuideBooking(widget.guide.id, updated);
  }

  Future<void> _send() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _replying) return;
    _controller.clear();
    widget.appState.sendGuideMessage(widget.guide.id, message);
    setState(() => _replying = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    widget.appState.addGuideReply(
      widget.guide.id,
      '확인했어요. 기항 일정에 맞춰 자세히 준비해서 안내드릴게요.',
    );
    setState(() => _replying = false);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }
}

class _GuideBookingRequestCard extends StatelessWidget {
  const _GuideBookingRequestCard({
    required this.booking,
    required this.appState,
    required this.expanded,
    required this.onToggle,
    required this.onAccept,
    required this.onReject,
    required this.onModify,
  });

  final GuideBooking booking;
  final AppState appState;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onModify;

  @override
  Widget build(BuildContext context) {
    final (
      statusLabel,
      statusColor,
      statusBackground,
    ) = switch (booking.status) {
      GuideBookingStatus.pending => (
        '가이드 확인 대기',
        AppColors.warning,
        AppColors.warningWeak,
      ),
      GuideBookingStatus.accepted => (
        '예약 수락',
        AppColors.success,
        AppColors.successWeak,
      ),
      GuideBookingStatus.rejected => (
        '예약 거절',
        AppColors.danger,
        AppColors.dangerWeak,
      ),
      GuideBookingStatus.modified => (
        '수정 제안',
        AppColors.brand,
        AppColors.brandWeak,
      ),
    };
    final actionable =
        booking.status == GuideBookingStatus.pending ||
        booking.status == GuideBookingStatus.modified;
    final selectedPlaces = selectedGuidePlaces(appState.savedPlaceIds);
    return Container(
      key: const ValueKey('guide-booking-request-card'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F1720),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: GestureDetector(
              key: const ValueKey('guide-booking-toggle'),
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: statusBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: statusColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '가이드 일정 요청',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              appState.cruise.date,
                              key: const ValueKey('guide-booking-date'),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Text(
                                '·',
                                style: TextStyle(color: AppColors.textTertiary),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                statusLabel,
                                key: const ValueKey('guide-booking-status'),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatWon(booking.total),
                    key: const ValueKey('guide-booking-chat-total'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.brandNavy,
                    ),
                  ),
                  const SizedBox(width: 5),
                  AnimatedRotation(
                    turns: expanded ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      key: ValueKey('guide-booking-toggle-icon'),
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: expanded
                ? Column(
                    key: const ValueKey('guide-booking-expanded-content'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BookingRequestInfoRow(
                              icon: Icons.schedule_rounded,
                              text:
                                  '${booking.startTime}–${booking.endTime} · '
                                  '${_bookingDurationLabel(booking.durationMinutes)}',
                            ),
                            const SizedBox(height: 7),
                            _BookingRequestInfoRow(
                              icon: Icons.tune_rounded,
                              text:
                                  '${booking.transport} · ${booking.language}',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(),
                            ),
                            Text(
                              '저장한 장소',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 7),
                            if (selectedPlaces.isEmpty)
                              Text(
                                '아직 저장한 장소가 없어요',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textTertiary),
                              )
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final place in selectedPlaces)
                                    Container(
                                      key: ValueKey(
                                        'guide-booking-saved-place-${place.id}',
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                          color: AppColors.line,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.place_rounded,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            place.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (actionable) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                key: const ValueKey('guide-booking-reject'),
                                onPressed: onReject,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                ),
                                child: const Text('거절'),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: OutlinedButton(
                                key: const ValueKey('guide-booking-modify'),
                                onPressed: onModify,
                                child: Text(
                                  booking.status == GuideBookingStatus.modified
                                      ? '다시 수정'
                                      : '수정',
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: FilledButton(
                                key: const ValueKey('guide-booking-accept'),
                                onPressed: onAccept,
                                child: const Text('수락'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _BookingRequestInfoRow extends StatelessWidget {
  const _BookingRequestInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.guide, this.onClose});

  final Guide guide;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (onClose != null) ...[
            RoundIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onClose!,
              tooltip: '뒤로가기',
            ),
            const SizedBox(width: 10),
          ],
          ClipOval(
            child: Image.asset(
              guide.image,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const EmptyImageFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${guide.name} 가이드',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '지금 메시지를 받을 수 있어요',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final GuideMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.fromUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: message.fromUser
              ? TextDirection.rtl
              : TextDirection.ltr,
          children: [
            Flexible(
              child: Container(
                key: ValueKey('chat-message-${message.text}'),
                constraints: const BoxConstraints(maxWidth: 310),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: message.fromUser
                      ? AppColors.brand
                      : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(message.fromUser ? 16 : 5),
                    bottomRight: Radius.circular(message.fromUser ? 5 : 16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: message.fromUser
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(message.time, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: SizedBox(
              width: 34,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: TextField(
          key: const ValueKey('guide-chat-input'),
          controller: controller,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onSend(),
          decoration: InputDecoration(
            hintText: '가이드에게 메시지 보내기',
            suffixIcon: IconButton(
              key: const ValueKey('guide-chat-send'),
              onPressed: onSend,
              icon: const Icon(Icons.arrow_upward_rounded),
              color: AppColors.brand,
            ),
          ),
        ),
      ),
    );
  }
}

double _bookingTimeValue(String time) {
  final parts = time.split(':');
  final hour = int.tryParse(parts.first) ?? 10;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return hour + minute / 60;
}

String _formatBookingTime(double value) {
  final totalMinutes = (value * 60).round();
  final hour = totalMinutes ~/ 60;
  final minute = totalMinutes % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

String _bookingDurationLabel(int durationMinutes) {
  final hours = durationMinutes ~/ 60;
  final minutes = durationMinutes % 60;
  return minutes == 0 ? '$hours시간' : '$hours시간 $minutes분';
}
