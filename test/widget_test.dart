import 'package:chemistryoven/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Chemistry Oven prototype renders main tabs', (tester) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    expect(find.text('케미스트리오븐'), findsWidgets);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('회차'), findsOneWidget);
    expect(find.text('내역'), findsOneWidget);
    expect(find.text('마이'), findsOneWidget);
  });

  testWidgets('home renders ref image driven application entry', (
    tester,
  ) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    expect(find.byType(Image), findsWidgets);
    expect(find.text('신청하기'), findsOneWidget);
    expect(find.text('4:4 소셜 베이킹 매칭'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('이번 달 회차'), 500);
    await tester.pumpAndSettle();
    expect(find.text('이번 달 회차'), findsOneWidget);
  });

  testWidgets('month preview changes selected class from calendar date', (
    tester,
  ) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    await tester.scrollUntilVisible(find.text('5월 2024'), 500);
    await tester.pumpAndSettle();
    expect(find.text('4:4 소셜 베이킹 매칭'), findsWidgets);

    await tester.tap(find.byTooltip('다음 달'));
    await tester.pumpAndSettle();
    expect(find.text('6월 2024'), findsOneWidget);
    expect(find.text('5:5 케이크 데코레이션 매칭'), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.text('취향 기반 베이킹 데이트'), findsOneWidget);
  });

  testWidgets('application history shows the current state card only', (
    tester,
  ) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    await tester.ensureVisible(find.text('신청하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('신청하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('내역'));
    await tester.pumpAndSettle();

    expect(find.text('인증 대기'), findsWidgets);
    expect(find.text('신청 상태'), findsOneWidget);
    expect(find.text('내 신청 흐름'), findsNothing);
  });

  testWidgets('participant choices progress by separated stages', (
    tester,
  ) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('행사참가자'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('내역'));
    await tester.pumpAndSettle();

    expect(find.text('닉네임 확인'), findsWidgets);

    await tester.tap(find.text('첫인상 선택으로 이동'));
    await tester.pumpAndSettle();
    expect(find.text('첫인상 선택'), findsWidgets);

    await tester.ensureVisible(find.text('첫인상 선택 제출'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('첫인상 선택 제출'));
    await tester.pumpAndSettle();
    expect(find.text('중간 선택'), findsWidgets);

    await tester.ensureVisible(find.text('중간 선택 제출'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('중간 선택 제출'));
    await tester.pumpAndSettle();
    expect(find.text('최종 선택'), findsWidgets);

    await tester.ensureVisible(find.text('최종 선택 제출'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('최종 선택 제출'));
    await tester.pumpAndSettle();
    expect(find.text('매칭 결과'), findsWidgets);
  });
}
