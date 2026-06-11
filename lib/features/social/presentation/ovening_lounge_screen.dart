import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// 오브닝 라운지 — 매칭 여부와 상관없이 그날 하루만 열리는 단체 메시지
/// (HTML 디자인 OveningLounge 대응)
class OveningLoungeScreen extends StatefulWidget {
  const OveningLoungeScreen({super.key});

  @override
  State<OveningLoungeScreen> createState() => _OveningLoungeScreenState();
}

class _OveningLoungeScreenState extends State<OveningLoungeScreen> {
  static const _people = [
    _LoungePerson(
      name: '소금빵',
      tag: '매칭 성공 · 연락처 공개',
      isMale: true,
      accent: true,
    ),
    _LoungePerson(name: '마들렌', tag: '같은 회차', isMale: false),
    _LoungePerson(name: '크루아상', tag: '같은 회차', isMale: true),
    _LoungePerson(name: '에그타르트', tag: '같은 회차', isMale: false),
    _LoungePerson(name: '에클레어', tag: '같은 회차', isMale: true),
  ];

  final Set<String> _blocked = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('오브닝 라운지', style: TextStyle(fontSize: 17)),
            Text(
              '12시간 후 닫혀요 · 11:32 남음',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.burgundy,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.butter,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'OPEN',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.wine,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                _buildIntroBanner(),
                const SizedBox(height: 16),
                Text(
                  '대화 가능한 분들',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final person in _people) ...[
                  _buildPersonTile(person),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 4),
                _buildOpenChatCard(context),
                const SizedBox(height: 12),
                Text(
                  '라운지와 모든 대화는 12시간 후 자동으로 닫혀요. 원하지 않는 분은 차단할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wine, AppColors.burgundy],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '오늘 함께한 분들과\n하루 동안 이야기해요.',
            style: TextStyle(
              fontSize: 22,
              height: 1.25,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '매칭이 안 됐더라도 괜찮아요. 오늘 참석한 모든 분과 12시간 동안 자유롭게 대화하고, '
            '연락처를 주고받거나 다음 약속을 잡을 수 있어요.',
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Color(0xE6F5DFA8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonTile(_LoungePerson person) {
    final isBlocked = _blocked.contains(person.name);

    return Opacity(
      opacity: isBlocked ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: person.accent ? AppColors.gold : AppColors.line,
            width: person.accent ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: person.isMale
                    ? const Color(0xFFE6E1D6)
                    : AppColors.parchment,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(
                person.name.characters.first,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: person.isMale
                      ? AppColors.mutedText
                      : AppColors.burgundy,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cocoa,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    person.tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: person.accent
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: person.accent
                          ? AppColors.burgundy
                          : AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (isBlocked)
              OutlinedButton(
                onPressed: () =>
                    setState(() => _blocked.remove(person.name)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  foregroundColor: AppColors.mutedText,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('차단 해제'),
              )
            else ...[
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${person.name}님과의 대화방 (검토용 데모)'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.burgundy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('대화'),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 34,
                height: 34,
                child: OutlinedButton(
                  onPressed: () =>
                      setState(() => _blocked.add(person.name)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(
                    Icons.block,
                    size: 15,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOpenChatCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold, width: 1.4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE500),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  size: 20,
                  color: Color(0xFF191600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘이 아쉬운 분들 오픈채팅',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '회차 단체 오픈채팅방으로 인연을 이어가세요.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('오픈채팅방 입장 (검토용 데모)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: const Text('오픈채팅방 입장하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoungePerson {
  const _LoungePerson({
    required this.name,
    required this.tag,
    required this.isMale,
    this.accent = false,
  });

  final String name;
  final String tag;
  final bool isMale;
  final bool accent;
}
