import 'package:chemistryoven/app/app.dart';
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
}
