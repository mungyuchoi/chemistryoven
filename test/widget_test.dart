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
    expect(find.text('옆자리 대화를 시작해요.'), findsOneWidget);

    await tester.ensureVisible(find.text('중간 선택 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('중간 선택 열기'));
    await tester.pumpAndSettle();
    expect(find.text('다시 이야기해보고 싶은 분은?'), findsOneWidget);

    await tester.ensureVisible(find.text('중간 선택 제출'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('중간 선택 제출'));
    await tester.pumpAndSettle();
    expect(find.text('다음 자리가 준비되었어요.'), findsOneWidget);

    await tester.ensureVisible(find.text('페어 베이킹 시작'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('페어 베이킹 시작'));
    await tester.pumpAndSettle();
    expect(find.text('함께 만들며 케미를 확인해요.'), findsOneWidget);

    await tester.ensureVisible(find.text('최종 선택 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('최종 선택 열기'));
    await tester.pumpAndSettle();
    expect(find.text('마지막으로 마음을 전할 분은?'), findsOneWidget);

    await tester.ensureVisible(find.text('최종 선택 제출'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('최종 선택 제출'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 케미 결과가 도착했어요.'), findsOneWidget);
  });

  testWidgets('admin preview follows guide screens through part one', (
    tester,
  ) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('오늘의 회차를'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    final loginButton = find.widgetWithText(ElevatedButton, '로그인');
    expect(tester.getSize(loginButton).width, greaterThan(300));
    expect(tester.getSize(loginButton).height, 56);

    await tester.ensureVisible(find.text('로그인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    expect(find.text('오늘은 5/22 (금)'), findsOneWidget);
    expect(find.text('새 회차'), findsOneWidget);

    await tester.tap(find.text('회차'));
    await tester.pumpAndSettle();
    expect(find.text('회차 관리'), findsOneWidget);
    final sessionFilterY = tester.getCenter(find.text('전체 6')).dy;
    expect(tester.getCenter(find.text('모집중 2')).dy, sessionFilterY);
    expect(tester.getCenter(find.text('선정중 1')).dy, sessionFilterY);
    expect(tester.getCenter(find.text('확정 2')).dy, sessionFilterY);
    expect(tester.getCenter(find.text('종료 1')).dy, sessionFilterY);
    expect(tester.getSize(find.text('모집중 2')).width, greaterThan(46));
    expect(tester.getSize(find.text('선정중 1')).width, greaterThan(46));
    expect(find.text('오픈예정'), findsOneWidget);
    expect(find.text('기획중'), findsOneWidget);

    await tester.tap(find.text('8기').first);
    await tester.pumpAndSettle();
    expect(find.text('8기 상세'), findsOneWidget);
    expect(find.text('이어서'), findsOneWidget);
    expect(find.text('이어하기'), findsNothing);
    expect(find.text('열기'), findsNothing);

    await tester.tap(find.text('신청자'));
    await tester.pumpAndSettle();
    expect(find.text('신청자'), findsWidgets);
    expect(find.text('지원자 E'), findsWidgets);
    final applicantFilterY = tester.getCenter(find.text('전체 34')).dy;
    expect(tester.getCenter(find.text('신규 6')).dy, applicantFilterY);
    expect(tester.getCenter(find.text('인증 대기 5')).dy, applicantFilterY);
    expect(tester.getCenter(find.text('인증 완료 29')).dy, applicantFilterY);
    expect(tester.getCenter(find.text('보류 2')).dy, applicantFilterY);
    expect(tester.getCenter(find.text('탈락 1')).dy, applicantFilterY);
    final sortY = tester.getCenter(find.text('최신순')).dy;
    expect(tester.getCenter(find.text('케미 높은순')).dy, sortY);

    await tester.tap(find.text('케미 높은순'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('지원자 E').first).dy,
      lessThan(tester.getTopLeft(find.text('지원자 B').first).dy),
    );

    await tester.tap(find.text('지원자 E').first);
    await tester.pumpAndSettle();
    expect(find.text('케미 분석 (운영 전용)'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('applicant-status-인증 완료')))
          .height,
      22,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('applicant-status-선정 후보')))
          .height,
      22,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('applicant-status-선정 후보')))
          .width,
      lessThan(70),
    );
    expect(
      (tester
                  .getCenter(
                    find.byKey(const ValueKey('applicant-status-인증 완료')),
                  )
                  .dy -
              tester.getCenter(find.text('인증 완료')).dy)
          .abs(),
      lessThanOrEqualTo(1),
    );
    expect(
      (tester
                  .getCenter(
                    find.byKey(const ValueKey('applicant-status-선정 후보')),
                  )
                  .dy -
              tester.getCenter(find.text('선정 후보')).dy)
          .abs(),
      lessThanOrEqualTo(1),
    );

    await tester.tap(find.text('매칭'));
    await tester.pumpAndSettle();
    expect(find.text('인원 선정'), findsOneWidget);
    expect(find.text('크루아상'), findsOneWidget);
    expect(find.text('소금빵'), findsOneWidget);
    expect(find.text('티라미수'), findsOneWidget);
    expect(find.text('에그타르트'), findsOneWidget);
    final selectionModeY = tester.getCenter(find.text('후보 풀')).dy;
    expect(tester.getCenter(find.text('케미 조합')).dy, selectionModeY);
    expect(tester.getCenter(find.text('밸런스')).dy, selectionModeY);

    await tester.tap(find.text('더보기'));
    await tester.pumpAndSettle();
    expect(find.text('알림'), findsOneWidget);

    final filterY = tester.getCenter(find.text('전체')).dy;
    expect(tester.getCenter(find.text('운영').first).dy, filterY);
    expect(tester.getCenter(find.text('결제').first).dy, filterY);
    expect(tester.getCenter(find.text('시스템').first).dy, filterY);
    expect(tester.getCenter(find.text('후기').first).dy, filterY);

    await tester.tap(find.text('후기').first);
    await tester.pumpAndSettle();
    expect(find.text('후기 관리'), findsOneWidget);
  });

  testWidgets('admin session create keeps menu option chips horizontal', (
    tester,
  ) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('로그인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('새 회차'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('알레르기 견과 함유'));
    await tester.pumpAndSettle();

    final chipY = tester.getCenter(find.text('알레르기 견과 함유')).dy;
    expect(tester.getCenter(find.text('글루텐 함유')).dy, chipY);
    expect(tester.getCenter(find.text('계란 함유')).dy, chipY);
    expect(tester.getCenter(find.text('유제품 함유')).dy, chipY);
  });

  testWidgets('admin part two screens continue from selection to reviews', (
    tester,
  ) async {
    await tester.pumpWidget(const ChemistryOvenApp());

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('로그인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('매칭'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('케미 조합보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('케미 조합보기'));
    await tester.pumpAndSettle();
    expect(find.text('케미 조합'), findsOneWidget);
    expect(find.text('지원자 E'), findsOneWidget);
    expect(find.text('선정됨'), findsOneWidget);
    expect(find.text('잘 맞는 남성 Top 4'), findsOneWidget);
    expect(find.textContaining('잘 맞는 여성'), findsNothing);

    await tester.ensureVisible(find.text('최종 선정 저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('최종 선정 저장'));
    await tester.pumpAndSettle();
    expect(find.text('참가자 관리'), findsOneWidget);

    await tester.ensureVisible(find.text('캐릭터 배정으로'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('캐릭터 배정으로'));
    await tester.pumpAndSettle();
    expect(find.text('캐릭터 배정'), findsOneWidget);

    await tester.ensureVisible(find.text('배정 확정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('배정 확정'));
    await tester.pumpAndSettle();
    expect(find.text('투표 관리'), findsOneWidget);

    await tester.ensureVisible(find.text('자리배치 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('자리배치 보기'));
    await tester.pumpAndSettle();
    expect(find.text('자리배치'), findsOneWidget);

    await tester.ensureVisible(find.text('수동 편집'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수동 편집'));
    await tester.pumpAndSettle();
    expect(find.text('자리 수동 편집'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('seat-A1-character'))).data,
      '크루아상',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('seat-A1-name'))).data,
      '지원자 A',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('seat-A3-character'))).data,
      '소금빵',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('seat-A3-name'))).data,
      '지원자 B',
    );

    await tester.tap(find.byKey(const ValueKey('seat-A3')));
    await tester.pumpAndSettle();
    expect(find.text('A1 ↔ A3 변경됨'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('seat-A1-character'))).data,
      '소금빵',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('seat-A1-name'))).data,
      '지원자 B',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('seat-A3-character'))).data,
      '크루아상',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('seat-A3-name'))).data,
      '지원자 A',
    );

    await tester.ensureVisible(find.text('변경 저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('변경 저장'));
    await tester.pumpAndSettle();
    expect(find.text('매칭 결과'), findsOneWidget);

    await tester.ensureVisible(find.text('케미 리포트 발송'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('케미 리포트 발송'));
    await tester.pumpAndSettle();
    expect(find.text('후기 관리'), findsOneWidget);
  });
}
