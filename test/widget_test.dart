import 'package:chemistryoven/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders v1 bottom tabs and home hero', (tester) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    expect(find.text('Chemistry Oven'), findsWidgets);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('일정'), findsWidgets);
    expect(find.text('케미Lab'), findsOneWidget);
    expect(find.text('오브닝'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);
    expect(find.text('디저트보다 더 달콤한 순간.'), findsOneWidget);
    expect(find.text('8기 신청하기'), findsOneWidget);
  });

  testWidgets('guest application shows onboarding/login gate then status', (
    tester,
  ) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    await tester.ensureVisible(find.text('8기 신청하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8기 신청하기'));
    await tester.pumpAndSettle();
    expect(find.text('신청 전 케미 분석이 필요해요.'), findsOneWidget);

    await tester.tap(find.text('검토용 로그인으로 보기'));
    await tester.pumpAndSettle();
    expect(find.text('신청해주셔서 감사합니다.'), findsOneWidget);

    await tester.tap(find.text('내 신청 현황 보기'));
    await tester.pumpAndSettle();
    expect(find.text('신청 현황'), findsOneWidget);
    expect(find.text('인증 대기'), findsWidgets);
  });

  testWidgets('schedule calendar shows empty and open class states', (
    tester,
  ) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    await tester.tap(find.text('일정').last);
    await tester.pumpAndSettle();
    expect(find.text('2026. 06'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-day-15')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.text('6월 15일에는 아직 확정된 일정이 없어요.'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, 260));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-day-14')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.text('케미스트리오븐 8기'), findsOneWidget);
    expect(find.text('신청 가능'), findsOneWidget);

    await tester.tap(find.text('케미스트리오븐 8기'));
    await tester.pumpAndSettle();
    expect(find.text('신청하기'), findsOneWidget);
  });

  testWidgets('participant ovening choices progress through voting rounds', (
    tester,
  ) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('행사참가자'));
    await tester.pumpAndSettle();

    expect(find.text('OVENING'), findsOneWidget);
    expect(find.text('티라미수'), findsWidgets);

    await tester.ensureVisible(find.text('첫인상 선택 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('첫인상 선택 열기'));
    await tester.pumpAndSettle();
    expect(find.text('첫인상이 가장 인상 깊었던 분은?'), findsOneWidget);

    await tester.ensureVisible(find.text('첫인상 선택 제출하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('첫인상 선택 제출하기'));
    await tester.pumpAndSettle();
    expect(find.text('중간 선택'), findsWidgets);

    await tester.ensureVisible(find.text('중간 선택 제출'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('중간 선택 제출'));
    await tester.pumpAndSettle();
    expect(find.text('마지막으로 마음을 전할 분은?'), findsOneWidget);

    await tester.ensureVisible(find.text('최종 선택 제출'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('최종 선택 제출'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 케미 결과가 도착했어요.'), findsOneWidget);
  });

  testWidgets('admin preview renders responsive console', (tester) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('관리자 · 대시보드'), findsOneWidget);
    expect(find.text('신청자 관리'), findsWidgets);
    expect(find.text('관리자 더미 상태 초기화'), findsOneWidget);
  });
}
