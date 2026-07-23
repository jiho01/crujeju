import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

Future<void> showAiAssistant(BuildContext context, {String? initialQuestion}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AiAssistantSheet(initialQuestion: initialQuestion),
  );
}

class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({super.key, this.initialQuestion});

  final String? initialQuestion;

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _question;
  bool _loading = false;

  static const _suggestions = [
    '선택한 장소를 모두 갈 수 있어?',
    '부모님과 편한 코스를 짜줘',
    '카드에 얼마를 충전하면 좋아?',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuestion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ask(widget.initialQuestion!);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask(String value) async {
    if (value.trim().isEmpty) return;
    setState(() {
      _question = value.trim();
      _loading = true;
      _controller.clear();
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.brandWeak,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '제주 AI',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '내 일정과 취향을 알고 있어요',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  RoundIconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icons.close_rounded,
                    tooltip: '닫기',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_question == null) ...[
                Text(
                  '어떤 도움이 필요해요?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 14),
                for (final suggestion in _suggestions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      radius: 14,
                      onTap: () => _ask(suggestion),
                      child: Row(
                        children: [
                          Expanded(child: Text(suggestion)),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ] else ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 11,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(5),
                      ),
                    ),
                    child: Text(
                      _question!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        bottomLeft: Radius.circular(5),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 48,
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              borderRadius: BorderRadius.all(
                                Radius.circular(99),
                              ),
                            ),
                          )
                        : Text(
                            '강정항에서 출발해 새연교와 오설록을 방문하면 이동 포함 약 4시간 10분이 걸려요. 오후 4시 20분에 항구로 돌아오는 일정이라 승선 마감 전 70분의 여유가 있어요.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                ),
                if (!_loading) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => setState(() => _question = null),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('다른 질문 보기'),
                  ),
                ],
              ],
              const SizedBox(height: 22),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: _ask,
                decoration: InputDecoration(
                  hintText: '제주 여행을 물어보세요',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => _ask(_controller.text),
                    icon: const Icon(Icons.arrow_upward_rounded),
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
