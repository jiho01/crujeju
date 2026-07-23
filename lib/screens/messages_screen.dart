import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/guide_chat.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({required this.appState, super.key});

  final AppState appState;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: AppPage(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: widget.appState,
            builder: (context, _) {
              final guides =
                  AppData.guides.where((guide) {
                    final messages = widget.appState.messagesForGuide(guide.id);
                    return widget.appState.hasGuideConversation(guide.id) &&
                        messages.isNotEmpty &&
                        guide.name.toLowerCase().contains(_query.toLowerCase());
                  }).toList()..sort((a, b) {
                    final unreadA = widget.appState.unreadCountForGuide(a.id);
                    final unreadB = widget.appState.unreadCountForGuide(b.id);
                    return unreadB.compareTo(unreadA);
                  });
              return Column(
                children: [
                  PageHeader(
                    title: '메시지',
                    subtitle: '가이드와 나눈 대화를 확인해요',
                    leading: RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.pop(context),
                      tooltip: '뒤로가기',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: TextField(
                      key: const ValueKey('message-search'),
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: '가이드 이름 검색',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  Expanded(
                    child: guides.isEmpty
                        ? _MessageEmptyState(hasQuery: _query.isNotEmpty)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                            itemCount: guides.length,
                            separatorBuilder: (_, _) =>
                                const Divider(indent: 68),
                            itemBuilder: (context, index) {
                              final guide = guides[index];
                              final messages = widget.appState.messagesForGuide(
                                guide.id,
                              );
                              return _ConversationRow(
                                guide: guide,
                                lastMessage: messages.last,
                                unread: widget.appState.unreadCountForGuide(
                                  guide.id,
                                ),
                                onTap: () => _openChat(guide),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openChat(Guide guide) {
    widget.appState.markGuideConversationRead(guide.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GuideChatScreen(guide: guide, appState: widget.appState),
      ),
    );
  }
}

class _MessageEmptyState extends StatelessWidget {
  const _MessageEmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('message-empty-state'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.brandWeak,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.brand,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? '검색 결과가 없어요' : '아직 대화가 없어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery ? '다른 가이드 이름으로 검색해 보세요' : '가이드에게 메시지를 보내면 여기에 표시돼요',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class GuideChatScreen extends StatelessWidget {
  const GuideChatScreen({
    required this.guide,
    required this.appState,
    super.key,
  });

  final Guide guide;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSecondary,
      body: AppPage(
        child: SafeArea(
          child: GuideChatPanel(
            guide: guide,
            appState: appState,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.guide,
    required this.lastMessage,
    required this.unread,
    required this.onTap,
  });

  final Guide guide;
  final GuideMessage lastMessage;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('message-thread-${guide.id}'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipOval(
                    child: Image.asset(
                      guide.image,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const EmptyImageFallback(),
                    ),
                  ),
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lastMessage.time,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 7),
                  if (unread > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      child: Text(
                        '$unread',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
