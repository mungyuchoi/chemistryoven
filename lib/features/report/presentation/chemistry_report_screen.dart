import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// 케미 리포트 — 회차 종료 후 AI 개인 분석 (HTML 디자인 OveningChemiReport 대응)
///
/// 규칙: 본인은 닉네임(이름) 표기, 다른 참가자는 닉네임만 표기.
class ChemistryReportScreen extends StatelessWidget {
  const ChemistryReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('케미 리포트', style: TextStyle(fontSize: 17)),
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
                  color: const Color(0xFFDDEBDD),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Color(0xFF3F6B4A),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Gemini 분석',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3F6B4A),
                      ),
                    ),
                  ],
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
                const _ReportHero(),
                const SizedBox(height: 14),
                _ReportBlock(
                  mark: '📈',
                  title: '서사 그래프 (선택 흐름)',
                  accent: true,
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Expanded(
                            child: _FlowStep(stage: '첫인상', name: '소금빵'),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.line,
                          ),
                          Expanded(
                            child: _FlowStep(stage: '중간', name: '소금빵'),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.line,
                          ),
                          Expanded(
                            child: _FlowStep(
                              stage: '최종',
                              name: '소금빵',
                              highlighted: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.butter,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Text(
                          '💬 서사 한 줄 평 · #처음부터_끝까지_직진 #한_우물_순애보',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.wine,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _ReportBlock(
                  mark: '💌',
                  title: '나를 향한 레시피 픽 (득표 현황)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _VoteStageRow(
                        stage: '첫인상',
                        count: 3,
                        names: ['소금빵', '크루아상', '단팥빵'],
                      ),
                      SizedBox(height: 8),
                      _VoteStageRow(
                        stage: '중간',
                        count: 2,
                        names: ['소금빵', '크루아상'],
                      ),
                      SizedBox(height: 8),
                      _VoteStageRow(stage: '최종', count: 1, names: ['소금빵']),
                      SizedBox(height: 11),
                      _PointText(
                        lead: '💡 픽 포인트',
                        body:
                            ' · 첫인상에서 차분하고 편안한 분위기가 폭넓게 닿았고, '
                            '회차가 진행될수록 ‘대화가 깊은 사람’이라는 매력이 진중한 한 명에게 응축됐어요.',
                      ),
                    ],
                  ),
                ),
                _ReportBlock(
                  mark: '🍰',
                  title: '베이킹 페어링 & 케미 점수',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _NickChip(name: '소금빵', filled: true),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.butter,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '💘 최종 케미 매칭 성공',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.wine,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: const [
                          Expanded(
                            child: _ScoreTile(label: 'STRICT', score: 88),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _ScoreTile(label: 'PSYCHOLOGY', score: 91),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      const _PointText(
                        lead: '🤝 시너지 리뷰',
                        body:
                            ' · 옆자리 페어로 함께 반죽을 치대는 동안, 담백하고 신뢰감 있는 대화가 '
                            '오븐의 온기처럼 천천히 번졌어요. ‘차분한 대화’ 취향과 가치관(신뢰)이 맞물리며 '
                            '호감이 최종 선택까지 자연스럽게 부풀어 올랐습니다.',
                      ),
                    ],
                  ),
                ),
                _ReportBlock(
                  mark: '🧠',
                  title: '케미스트리 프로필 (성향 · 취향 분석)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _ProfileItem(
                        keyword: 'MBTI · INFP',
                        description:
                            'INFP는 마음이 한 번 향하면 깊고 진솔해지는 유형. ‘많은 사람에게 두루’보다 '
                            '‘한 사람에게 진심으로’를 택한 이번 선택과 정확히 닮아 있어요.',
                      ),
                      SizedBox(height: 10),
                      _ProfileItem(
                        keyword: '핵심 가치관 · 신뢰',
                        description:
                            '관계에서 가장 중요한 한 가지로 꼽은 ‘신뢰’가, 화려한 어필보다 '
                            '일관된 진심을 보여준 상대에게 마음이 머물게 했어요.',
                      ),
                      SizedBox(height: 10),
                      _ProfileItem(
                        keyword: '취향 페어링',
                        description:
                            '‘조용히 집중할 때 가까워진다’는 취향이 페어 베이킹의 잔잔한 호흡 속에서 '
                            '그대로 발현됐어요.',
                      ),
                    ],
                  ),
                ),
                _ReportBlock(
                  mark: '🌟',
                  title: '치명적 매력 포인트',
                  child: Column(
                    children: const [
                      _StrengthRow(
                        title: '진정성',
                        description: '마음의 방향을 끝까지 바꾸지 않는 일관된 진심',
                      ),
                      SizedBox(height: 8),
                      _StrengthRow(
                        title: '편안한 깊이',
                        description: '말수보다 결이 깊은, 함께 있으면 안정되는 분위기',
                      ),
                    ],
                  ),
                ),
                _ReportBlock(
                  mark: '🎬',
                  title: '오븐 속 드라마',
                  child: Text(
                    '티라미수는 처음부터 반죽의 온도를 알고 있던 사람이었습니다. 화려한 데코 대신, '
                    '한 겹 한 겹 진심을 쌓아 올리는 쪽을 택했죠. 다른 풍미가 곁을 스쳐도 오븐의 불씨는 '
                    '늘 한 곳을 향했고, 마침내 같은 온도로 구워진 소금빵을 만났을 때 — 달지 않아도 '
                    '가장 오래 기억에 남는 디저트가 완성되었습니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      height: 1.7,
                      fontStyle: FontStyle.italic,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.wine,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '📌 파티시에 AI의 한 줄 평',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.butter,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '“끝까지 한 사람을 향한,\n가장 담백한 진심.”',
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.35,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _ReportBlock(
                  mark: '🏷️',
                  title: '케미 요약 해시태그 보드',
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final tag in const [
                        '#INFP',
                        '#티라미수',
                        '#신뢰가_최우선',
                        '#최종케미매칭성공',
                        '#나를_픽한_6명',
                      ])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.parchment,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.burgundy,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    '이 리포트는 참가자 프로필과 첫인상·중간·최종 선택 데이터를 바탕으로 Gemini가 생성했어요.\n'
                    '다른 참가자는 닉네임으로만 표기돼요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('리포트가 저장되었어요. (검토용 데모)'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('리포트 저장하기'),
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

class _ReportHero extends StatelessWidget {
  const _ReportHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wine, AppColors.burgundy, AppColors.caramel],
          stops: [0, 0.72, 1],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -40,
            right: -34,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.butter.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✨ 나의 케미 캐릭터',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.butter,
                ),
              ),
              const SizedBox(height: 6),
              const Text('🍰', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              RichText(
                text: const TextSpan(
                  text: '티라미수 ',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    TextSpan(
                      text: '(이지윤)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xE6F5DFA8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '케미스트리 오븐 · 9기 · 토요일 오후 팀',
                style: TextStyle(fontSize: 12, color: Color(0xD9F5DFA8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportBlock extends StatelessWidget {
  const _ReportBlock({
    required this.mark,
    required this.title,
    required this.child,
    this.accent = false,
  });

  final String mark;
  final String title;
  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: accent
            ? [
                BoxShadow(
                  color: AppColors.wine.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(mark, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cocoa,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _NickChip extends StatelessWidget {
  const _NickChip({required this.name, this.filled = false});

  final String name;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? AppColors.burgundy : AppColors.parchment,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.characters.first,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: filled ? AppColors.butter : AppColors.burgundy,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : AppColors.burgundy,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.stage,
    required this.name,
    this.highlighted = false,
  });

  final String stage;
  final String name;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          stage,
          style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
        ),
        const SizedBox(height: 5),
        _NickChip(name: name, filled: highlighted),
      ],
    );
  }
}

class _VoteStageRow extends StatelessWidget {
  const _VoteStageRow({
    required this.stage,
    required this.count,
    required this.names,
  });

  final String stage;
  final int count;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              stage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedText,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: '$count',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.burgundy,
                ),
                children: const [
                  TextSpan(
                    text: '명',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final name in names)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cocoa,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              text: '$score',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.wine,
              ),
              children: const [
                TextSpan(
                  text: '점',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointText extends StatelessWidget {
  const _PointText({required this.lead, required this.body});

  final String lead;
  final String body;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: lead,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.burgundy,
          height: 1.6,
        ),
        children: [
          TextSpan(
            text: body,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({required this.keyword, required this.description});

  final String keyword;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '[$keyword]',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.burgundy,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            height: 1.6,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}

class _StrengthRow extends StatelessWidget {
  const _StrengthRow({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.auto_awesome, size: 15, color: AppColors.gold),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cocoa,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
