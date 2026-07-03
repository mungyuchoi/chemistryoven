import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../report/presentation/chemistry_report_screen.dart';

/// 후기 게이트 — 후기를 남겨야 케미 리포트가 열려요 (HTML 디자인 ReviewGate 대응)
class ReviewGateScreen extends StatefulWidget {
  const ReviewGateScreen({this.onReviewSubmitted, super.key});

  /// 후기 제출 시 호출. 별점/종류/내용을 전달한다 (라이브 모드에서 서버 저장용).
  final void Function(int stars, String type, String text)? onReviewSubmitted;

  @override
  State<ReviewGateScreen> createState() => _ReviewGateScreenState();
}

class _ReviewGateScreenState extends State<ReviewGateScreen> {
  static const _reviewTypes = ['참여 후기', '데이트 후기', '커플 인증'];

  final _controller = TextEditingController();
  int _stars = 5;
  int _selectedType = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('후기 남기기', style: TextStyle(fontSize: 17))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                const _LockedReportPreview(),
                const SizedBox(height: 16),
                Text(
                  '오늘 오브닝은 어떠셨나요?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var star = 1; star <= 5; star++)
                      IconButton(
                        onPressed: () => setState(() => _stars = star),
                        padding: const EdgeInsets.only(right: 4),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          star <= _stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 36,
                          color: star <= _stars
                              ? AppColors.gold
                              : AppColors.line,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('후기 종류', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _reviewTypes.length; i++)
                      ChoiceChip(
                        label: Text(_reviewTypes[i]),
                        selected: _selectedType == i,
                        showCheckmark: false,
                        selectedColor: AppColors.burgundy,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedType == i
                              ? Colors.white
                              : AppColors.cocoa,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: _selectedType == i
                                ? AppColors.burgundy
                                : AppColors.line,
                            width: 1.5,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        onSelected: (_) => setState(() => _selectedType = i),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText:
                        '오늘의 케미는 어땠는지 자유롭게 적어주세요. 후기는 후기 게시판에 닉네임으로 공개돼요.',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.mutedText,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    _PhotoSlot(),
                    SizedBox(width: 8),
                    _PhotoSlot(),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('후기 남기고 리포트 열기'),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '후기를 남기면 AI가 작성한 케미 리포트를 바로 볼 수 있어요.',
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

  void _submit() {
    widget.onReviewSubmitted?.call(
      _stars,
      _reviewTypes[_selectedType],
      _controller.text.trim(),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ChemistryReportScreen()),
    );
  }
}

/// 잠긴 리포트 미리보기 (블러 + 잠금 오버레이)
class _LockedReportPreview extends StatelessWidget {
  const _LockedReportPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 60),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.wine, AppColors.burgundy],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('🍰', style: TextStyle(fontSize: 22)),
                  SizedBox(height: 6),
                  Text(
                    '티라미수 케미 리포트',
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '선택 흐름 · 득표 · 강점 · 드라마틱 해석…',
                    style: TextStyle(fontSize: 12, color: Color(0xD9F5DFA8)),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0x592A1F1A),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xE6FFFFFF),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 24,
                      color: AppColors.wine,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '후기를 남기면 리포트가 열려요',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.camera_alt_outlined,
            size: 18,
            color: AppColors.mutedText,
          ),
          SizedBox(height: 4),
          Text(
            '사진',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
