import 'package:flutter/material.dart';

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
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return ColoredBox(
          color: AppColors.surface,
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: Column(
              children: [
                _ChatHeader(guide: widget.guide, onClose: widget.onClose),
                const Divider(),
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
