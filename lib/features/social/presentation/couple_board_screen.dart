import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// 커플 인증 게시판 + 무료 커플 클래스 리워드 (HTML 디자인 CoupleBoard 대응)
class CoupleBoardScreen extends StatelessWidget {
  const CoupleBoardScreen({super.key});

  static const _posts = [
    _CouplePost(
      couple: '소금빵 ♥ 티라미수',
      generation: '8기',
      step: 3,
      body: '오브닝에서 만나 벌써 세 번째 데이트예요! 베이킹으로 시작한 인연이 이렇게 이어질 줄 몰랐어요.',
      hasImage: true,
      badge: '현커 인증',
      likes: 24,
      cheers: 8,
    ),
    _CouplePost(
      couple: '크루아상 ♥ 에그타르트',
      generation: '7기',
      step: 2,
      body: '두 번째 만남에서 더 가까워졌어요. 다음엔 같이 빵 만들러 가기로 했어요 :)',
      hasImage: true,
      badge: '데이트 인증',
      likes: 18,
      cheers: 5,
    ),
    _CouplePost(
      couple: '에클레어 ♥ 마들렌',
      generation: '7기',
      step: 1,
      body: '첫 데이트 다녀왔어요. 대화가 잘 통해서 시간 가는 줄 몰랐네요.',
      hasImage: false,
      badge: '데이트 인증',
      likes: 11,
      cheers: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('커플 인증 게시판', style: TextStyle(fontSize: 17)),
        actions: [
          IconButton(
            onPressed: () => _showDemoSnack(context, '인증 글 작성 (검토용 데모)'),
            icon: const Icon(Icons.add, color: AppColors.burgundy),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                const _RewardBanner(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '인증 게시글',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '최신순 ▾',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final post in _posts) ...[
                  _CouplePostCard(post: post),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showDemoSnack(context, '커플 인증하기 (검토용 데모)'),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('우리 커플 인증하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showDemoSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

/// 무료 커플 클래스 리워드 배너 (3회 인증 진행도 포함)
class _RewardBanner extends StatelessWidget {
  const _RewardBanner();

  static const _completedSteps = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.butter, Color(0xFFEAC97A)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x26551321)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COUPLE REWARD',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xCC3B0715),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '세 번 인증하면\n무료 커플 클래스!',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.wine,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '세 번의 데이트(또는 현커) 인증을 완료하면 두 분을 위한 무료 베이킹 커플 클래스를 선물해드려요.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xD93B0715),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var step = 1; step <= 3; step++)
                    Expanded(child: _ProgressDot(step: step)),
                ],
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  '한 번만 더 인증하면 클래스 오픈! 🎉',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.wine,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final isDone = step <= _RewardBanner._completedSteps;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppColors.wine : const Color(0x1F551321),
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 15, color: AppColors.butter)
              : Text(
                  '$step',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.wine,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          '$step회차',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.wine,
          ),
        ),
      ],
    );
  }
}

class _CouplePostCard extends StatelessWidget {
  const _CouplePostCard({required this.post});

  final _CouplePost post;

  @override
  Widget build(BuildContext context) {
    final isRealCouple = post.badge == '현커 인증';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 18,
                  color: AppColors.burgundy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.couple,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cocoa,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${post.generation} 매칭 · ${post.step}번째 인증',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isRealCouple ? AppColors.butter : AppColors.parchment,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  post.badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isRealCouple ? AppColors.wine : AppColors.burgundy,
                  ),
                ),
              ),
            ],
          ),
          if (post.hasImage) ...[
            const SizedBox(height: 12),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.parchment,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.photo_outlined,
                    size: 28,
                    color: AppColors.mutedText,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'COUPLE PHOTO · 인증 사진',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            post.body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.cocoa,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite,
                  size: 15,
                  color: AppColors.burgundy,
                ),
                const SizedBox(width: 5),
                Text(
                  '${post.likes}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.campaign_outlined,
                  size: 15,
                  color: AppColors.mutedText,
                ),
                const SizedBox(width: 5),
                Text(
                  '응원 ${post.cheers}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _CouplePost {
  const _CouplePost({
    required this.couple,
    required this.generation,
    required this.step,
    required this.body,
    required this.hasImage,
    required this.badge,
    required this.likes,
    required this.cheers,
  });

  final String couple;
  final String generation;
  final int step;
  final String body;
  final bool hasImage;
  final String badge;
  final int likes;
  final int cheers;
}
